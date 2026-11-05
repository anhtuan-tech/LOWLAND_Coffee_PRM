import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../../viewmodels/auth_viewmodel.dart';

/// Tiện ích kiểm tra phân quyền & nhắc nhở đăng nhập (Auth Guard)
class AuthGuard {
  AuthGuard._();

  /// Kiểm tra user đã đăng nhập chưa; nếu chưa thì hiện Dialog nhắc nhở và trả về false
  static bool checkAuth(BuildContext context, {required String actionMessage}) {
    final authVM = context.read<AuthViewModel>();
    if (!authVM.isLoggedIn) {
      showLoginRequiredDialog(context, actionMessage: actionMessage);
      return false;
    }
    return true;
  }

  /// Hiển thị hộp thoại nhắc nhở Đăng nhập thân thiện
  static void showLoginRequiredDialog(
    BuildContext context, {
    required String actionMessage,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded, color: AppColors.accent, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Yêu cầu đăng nhập',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn đang duyệt ở chế độ Khách (chỉ xem thực đơn).',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng đăng nhập tài khoản để $actionMessage, áp mã giảm giá và tích điểm thành viên nhé!',
              style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Để sau', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, AppRoutes.login);
            },
            child: const Text(
              'Đăng nhập ngay',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

