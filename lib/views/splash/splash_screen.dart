import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/services/local/database_helper.dart';

/// Màn hình Splash / Chào đón thương hiệu LOWLAND Coffee
/// Tích hợp Startup Cart Check: Kiểm tra giỏ hàng còn món chưa thanh toán để nhắc nhở
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAppStartup();
  }

  Future<void> _checkAppStartup() async {
    // Thời gian hiển thị splash thương hiệu
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    // Kiểm tra số lượng món còn lưu trong SQLite giỏ hàng
    final cartCount = await DatabaseHelper.instance.getCartItemsCount();

    if (!mounted) return;

    if (cartCount > 0) {
      // Hiển thị Alert Dialog nhắc nhở tiếp tục mua hàng
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.shopping_bag_rounded, color: AppColors.accent),
              const SizedBox(width: 8),
              const Text('Giỏ hàng chờ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Bạn còn $cartCount món chưa thanh toán trong giỏ hàng. Bạn có muốn tiếp tục xem lại giỏ hàng không?',
            style: AppTextStyles.body,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacementNamed(context, AppRoutes.main);
              },
              child: const Text('Vào trang chủ', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacementNamed(context, AppRoutes.main);
                Navigator.pushNamed(context, AppRoutes.cart);
              },
              child: const Text('Xem giỏ ngay'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.main);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo chính thức LOWLAND Coffee
              Container(
                width: 120,
                height: 120,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tên thương hiệu
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 8),

              // Slogan
              const Text(
                AppConstants.appTagline,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.accentLight,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 50),

              // Loading spinner
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
