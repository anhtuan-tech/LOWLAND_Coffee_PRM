import 'package:flutter/material.dart';
import '../../data/models/product_model.dart';
import '../../views/auth/login_screen.dart';
import '../../views/auth/register_screen.dart';
import '../../views/cart/cart_screen.dart';
import '../../views/cart/voucher_screen.dart';
import '../../views/favorites/favorites_screen.dart';
import '../../views/home/main_navigation_screen.dart';
import '../../views/menu/menu_screen.dart';
import '../../views/orders/order_history_screen.dart';
import '../../views/payment/vnpay_sandbox_screen.dart';
import '../../views/product/product_detail_screen.dart';
import '../../views/profile/profile_screen.dart';
import '../../views/splash/splash_screen.dart';
import '../../views/store/store_info_screen.dart';

/// Quản lý hệ thống Named Routes toàn bộ ứng dụng LOWLAND Coffee
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String main = '/main';
  static const String menu = '/menu';
  static const String productDetail = '/product-detail';
  static const String cart = '/cart';
  static const String vouchers = '/vouchers';
  static const String favorites = '/favorites';
  static const String orderHistory = '/order-history';
  static const String storeInfo = '/store-info';
  static const String profile = '/profile';
  static const String vnpay = '/vnpay';

  /// Trình tạo route điều hướng toàn ứng dụng
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case main:
        return MaterialPageRoute(builder: (_) => const MainNavigationScreen());

      case menu:
        return MaterialPageRoute(builder: (_) => const MenuScreen());

      case productDetail:
        final product = settings.arguments as ProductModel;
        return MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        );

      case cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());

      case vouchers:
        return MaterialPageRoute(builder: (_) => const VoucherScreen());

      case favorites:
        return MaterialPageRoute(builder: (_) => const FavoritesScreen());

      case orderHistory:
        return MaterialPageRoute(builder: (_) => const OrderHistoryScreen());

      case storeInfo:
        return MaterialPageRoute(builder: (_) => const StoreInfoScreen());

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case vnpay:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => VNPaySandboxScreen(
            amount: args['amount'] as double,
            orderInfo: args['orderInfo'] as String? ?? 'Thanh toan don hang LOWLAND',
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Lỗi điều hướng')),
            body: Center(
              child: Text('Không tìm thấy đường dẫn: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
