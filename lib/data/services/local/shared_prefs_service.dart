import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import 'database_helper.dart';

/// Dịch vụ quản lý phiên đăng nhập và bộ nhớ đệm SharedPreferences
class SharedPrefsService {
  static final SharedPrefsService instance = SharedPrefsService._init();

  static const String _keyUserPhone = 'user_phone_number';
  static const String _keyUserPhoto = 'user_photo_url_data';

  SharedPrefsService._init();

  /// Lưu phiên đăng nhập người dùng (bao gồm cả SĐT và Ảnh đại diện Base64/URL)
  Future<void> saveUserSession({
    required String uid,
    required String email,
    required String displayName,
    String? phoneNumber,
    String? photoUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyUserLoggedIn, true);
    await prefs.setString(AppConstants.keyUserUid, uid);
    await prefs.setString(AppConstants.keyUserEmail, email);
    await prefs.setString(AppConstants.keyUserName, displayName);
    if (phoneNumber != null) {
      await prefs.setString(_keyUserPhone, phoneNumber);
    }
    if (photoUrl != null && photoUrl.isNotEmpty) {
      await prefs.setString(_keyUserPhoto, photoUrl);
    }
    await DatabaseHelper.instance.syncToPhysicalSqliteDb();
  }

  /// Kiểm tra trạng thái đã đăng nhập
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyUserLoggedIn) ?? false;
  }

  /// Lấy thông tin phiên hiện tại
  Future<Map<String, String?>> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'uid': prefs.getString(AppConstants.keyUserUid),
      'email': prefs.getString(AppConstants.keyUserEmail),
      'name': prefs.getString(AppConstants.keyUserName),
      'phone': prefs.getString(_keyUserPhone),
      'photoUrl': prefs.getString(_keyUserPhoto),
    };
  }

  /// Xóa phiên làm việc khi Đăng xuất (Logout)
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyUserLoggedIn);
    await prefs.remove(AppConstants.keyUserUid);
    await prefs.remove(AppConstants.keyUserEmail);
    await prefs.remove(AppConstants.keyUserName);
    await prefs.remove(_keyUserPhone);
    await prefs.remove(_keyUserPhoto);
    await DatabaseHelper.instance.syncToPhysicalSqliteDb();
  }
}
