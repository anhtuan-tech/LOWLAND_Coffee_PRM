import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/auth_guard.dart';
import '../../core/utils/local_image_picker.dart';
import '../../data/models/user_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/custom_button.dart';

/// Màn hình Tài khoản & Hồ sơ người dùng (Hỗ trợ đổi Ảnh đại diện chọn từ máy tính/điện thoại)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  /// Mở hộp thoại chọn file ảnh từ máy tính / thiết bị để xem trước (Preview)
  /// Ảnh sẽ chỉ được tải lên Cloudinary khi người dùng bấm nút "Lưu thay đổi".
  Future<String?> _pickImageForPreview(BuildContext context) async {
    try {
      return await LocalImagePicker.pickLocalImagePreview();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể đọc file ảnh: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return null;
    }
  }

  /// Xây dựng Widget hiển thị Avatar từ ảnh chọn trong máy (Base64), ảnh URL hoặc chữ cái đầu
  Widget _buildAvatarWidget(
    UserModel? user, {
    double radius = 38,
    String? previewPhotoUrl,
  }) {
    final photo = (previewPhotoUrl ?? user?.photoUrl ?? '').trim();

    if (photo.isNotEmpty) {
      if (photo.startsWith('data:image')) {
        try {
          final commaIndex = photo.indexOf(',');
          final rawBase64 = commaIndex != -1 ? photo.substring(commaIndex + 1) : photo;
          final bytes = base64Decode(rawBase64);
          return CircleAvatar(
            radius: radius,
            backgroundColor: Colors.white,
            backgroundImage: MemoryImage(bytes),
          );
        } catch (_) {}
      } else if (photo.startsWith('http')) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: Colors.white,
          backgroundImage: NetworkImage(photo),
        );
      }
    }

    if (user != null && user.displayName.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.surfaceCream,
        child: Text(
          user.displayName[0].toUpperCase(),
          style: TextStyle(
            fontSize: radius * 0.75,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo.png',
          width: radius * 1.8,
          height: radius * 1.8,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi LOWLAND Coffee?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthViewModel>().logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (route) => false,
                );
              }
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, UserModel user) {
    final nameController = TextEditingController(text: user.displayName);
    final phoneController = TextEditingController(text: user.phoneNumber ?? '');
    String? selectedPhotoDataUrl = user.photoUrl;

    showDialog(
      context: context,
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_pin_rounded, color: AppColors.accent),
                  ),
                  const SizedBox(width: 10),
                  const Text('Cập nhật hồ sơ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Khu vực chọn Ảnh đại diện từ máy tính / điện thoại (xem trước, chỉ upload Cloudinary khi bấm Lưu)
                    GestureDetector(
                      onTap: isSaving
                          ? null
                          : () async {
                              final pickedDataUrl = await _pickImageForPreview(context);
                              if (pickedDataUrl != null) {
                                setDialogState(() {
                                  selectedPhotoDataUrl = pickedDataUrl;
                                });
                              }
                            },
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.accent, width: 2),
                                ),
                                child: _buildAvatarWidget(
                                  user,
                                  radius: 44,
                                  previewPhotoUrl: selectedPhotoDataUrl,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final pickedDataUrl = await _pickImageForPreview(context);
                                    if (pickedDataUrl != null) {
                                      setDialogState(() {
                                        selectedPhotoDataUrl = pickedDataUrl;
                                      });
                                    }
                                  },
                            icon: const Icon(Icons.upload_file_rounded, size: 18),
                            label: const Text(
                              'Chọn ảnh từ thiết bị',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Họ và tên',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Số điện thoại',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newName = nameController.text.trim();
                          final newPhone = phoneController.text.trim();
                          if (newName.length < 2) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Họ và tên phải có ít nhất 2 ký tự!'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }
                          if (newPhone.isNotEmpty &&
                              !RegExp(r'^(0[3|5|7|8|9])+([0-9]{8})$').hasMatch(newPhone)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Số điện thoại không hợp lệ (Gồm 10 số, bắt đầu bằng 03, 05, 07, 08, 09)!'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }
                          setDialogState(() => isSaving = true);
                          final success = await context.read<AuthViewModel>().updateProfile(
                                displayName: newName,
                                phoneNumber: newPhone,
                                photoUrl: selectedPhotoDataUrl,
                              );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Cập nhật hồ sơ & ảnh đại diện thành công! 🎉'
                                      : 'Lỗi cập nhật hồ sơ.',
                                ),
                                backgroundColor: success ? AppColors.success : AppColors.error,
                              ),
                            );
                          }
                        },
                  child: isSaving
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Đang lưu...',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      : const Text(
                          'Lưu thay đổi',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tài khoản của tôi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Thẻ thông tin cá nhân
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar bấm vào sẽ mở hộp thoại Cập nhật hồ sơ để chọn ảnh & bấm Lưu lên Cloudinary
                  GestureDetector(
                    onTap: user != null ? () => _showEditProfileDialog(context, user) : null,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 2),
                          ),
                          child: _buildAvatarWidget(user, radius: 36),
                        ),
                        if (user != null)
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                user?.displayName ?? 'Khách trải nghiệm',
                                style: AppTextStyles.heading3,
                              ),
                            ),
                            if (user != null)
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.accent),
                                tooltip: 'Chỉnh sửa hồ sơ & ảnh',
                                onPressed: () => _showEditProfileDialog(context, user),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'Chưa đăng nhập tài khoản',
                          style: AppTextStyles.bodySmall,
                        ),
                        if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'SĐT: ${user.phoneNumber}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Các mục cài đặt & tiện ích
            if (user != null)
              _buildMenuItem(
                icon: Icons.manage_accounts_rounded,
                title: 'Cập nhật hồ sơ & Ảnh đại diện',
                subtitle: 'Chọn ảnh từ thiết bị, đổi tên hiển thị và SĐT',
                onTap: () => _showEditProfileDialog(context, user),
              ),
            _buildMenuItem(
              icon: Icons.history_rounded,
              title: 'Lịch sử đơn hàng',
              subtitle: 'Xem lại các đơn cà phê đã đặt',
              onTap: () {
                if (AuthGuard.checkAuth(context, actionMessage: 'xem lịch sử đơn hàng')) {
                  Navigator.pushNamed(context, AppRoutes.orderHistory);
                }
              },
            ),
            _buildMenuItem(
              icon: Icons.favorite_border_rounded,
              title: 'Món yêu thích',
              subtitle: 'Danh sách các món bạn đã thả tim',
              onTap: () {
                if (AuthGuard.checkAuth(context, actionMessage: 'xem danh sách món yêu thích')) {
                  Navigator.pushNamed(context, AppRoutes.favorites);
                }
              },
            ),
            _buildMenuItem(
              icon: Icons.confirmation_number_outlined,
              title: 'Ví Voucher ưu đãi',
              subtitle: 'Mã giảm giá và khuyến mãi của bạn',
              onTap: () {
                if (AuthGuard.checkAuth(context, actionMessage: 'xem kho mã giảm giá')) {
                  Navigator.pushNamed(context, AppRoutes.vouchers);
                }
              },
            ),
            _buildMenuItem(
              icon: Icons.storefront_rounded,
              title: 'Thông tin Quán café',
              subtitle: 'Địa chỉ, Hotline, Wifi & Chỉ đường Maps',
              onTap: () => Navigator.pushNamed(context, AppRoutes.storeInfo),
            ),
            const SizedBox(height: 32),

            // Nút Đăng xuất hoặc Đăng nhập
            if (user != null)
              CustomButton(
                text: 'Đăng xuất',
                icon: Icons.logout_rounded,
                isOutlined: true,
                onPressed: () => _showLogoutDialog(context),
              )
            else
              CustomButton(
                text: 'Đăng nhập / Đăng ký',
                icon: Icons.login_rounded,
                onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceCream,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        title: Text(title, style: AppTextStyles.subtitle),
        subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
        onTap: onTap,
      ),
    );
  }
}
