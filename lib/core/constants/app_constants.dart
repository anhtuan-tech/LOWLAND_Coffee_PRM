/// Các hằng số cấu hình hệ thống ứng dụng LOWLAND Coffee
class AppConstants {
  AppConstants._();

  static const String appName = 'LOWLAND Coffee';
  static const String appTagline = 'Đậm vị truyền thống - Chuẩn vị đam mê';

  // SQLite Database
  static const String databaseName = 'lowland_coffee.db';
  static const int databaseVersion = 1;

  // Database Table Names
  static const String tableCart = 'cart_items';
  static const String tableFavorites = 'favorites';
  static const String tableOrderHistory = 'order_history';

  // Firestore Collections
  static const String collectionProducts = 'products';
  static const String collectionVouchers = 'vouchers';
  static const String collectionStores = 'stores';
  static const String collectionUsers = 'users';

  // Menu Categories
  static const String categoryCoffee = 'Cà phê';
  static const String categoryTea = 'Trà';
  static const String categoryPastry = 'Bánh';

  static const List<String> categories = [
    'Tất cả',
    categoryCoffee,
    categoryTea,
    categoryPastry,
  ];

  // SharedPreferences Keys
  static const String keyUserLoggedIn = 'is_logged_in';
  static const String keyUserEmail = 'user_email';
  static const String keyUserUid = 'user_uid';
  static const String keyUserName = 'user_name';
}

