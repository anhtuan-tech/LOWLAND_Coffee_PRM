import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/auth_guard.dart';
import '../../data/models/user_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/custom_button.dart';

/// Màn hình Tài khoản & Hồ sơ người dùng
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                      color: AppColors.accent.withOpacity(0.15),
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
                          if (newName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vui lòng nhập họ và tên!')),
                            );
                            return;
                          }
                          setDialogState(() => isSaving = true);
                          final success = await context.read<AuthViewModel>().updateProfile(
                                displayName: newName,
                                phoneNumber: phoneController.text.trim(),
                              );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success ? 'Cập nhật hồ sơ thành công! 🎉' : 'Lỗi cập nhật hồ sơ.'),
                                backgroundColor: success ? AppColors.success : AppColors.error,
                              ),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Lưu thay đổi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    color: AppColors.primaryDark.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    child: (user != null && user.displayName.isNotEmpty)
                        ? Text(
                            user.displayName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 65,
                              height: 65,
                              fit: BoxFit.contain,
                            ),
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
                                tooltip: 'Chỉnh sửa hồ sơ',
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
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: (user != null)
                                ? AppColors.accent.withOpacity(0.15)
                                : Colors.grey.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            (user != null) ? 'Thành viên Vàng ☕' : 'Khách vãng lai 👤',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: (user != null) ? AppColors.accentDark : Colors.grey.shade700,
                            ),
                          ),
                        ),
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
                title: 'Cập nhật hồ sơ cá nhân',
                subtitle: 'Đổi tên hiển thị, số điện thoại liên hệ',
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
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
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

