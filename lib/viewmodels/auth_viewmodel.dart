import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/services/local/shared_prefs_service.dart';
import '../data/services/remote/cloudinary_service.dart';
import '../data/services/remote/firebase_auth_service.dart';

/// ViewModel quản lý Xác thực & Tài khoản người dùng
class AuthViewModel extends ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService.instance;
  final SharedPrefsService _prefsService = SharedPrefsService.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isConfirmPasswordVisible => _isConfirmPasswordVisible;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoggedIn => _currentUser != null;

  AuthViewModel() {
    checkLoginSession();
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Validation Email định dạng chuẩn
  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập địa chỉ email.';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không hợp lệ (Ví dụ: ten@gmail.com).';
    }
    return null;
  }

  /// Validation Mật khẩu tối thiểu 6 ký tự
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu.';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự.';
    }
    return null;
  }

  /// Validation Tên hiển thị
  String? validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập họ và tên của bạn.';
    }
    return null;
  }

  /// Kiểm tra phiên đăng nhập đã lưu trong SharedPreferences
  Future<bool> checkLoginSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isLoggedIn = await _prefsService.isLoggedIn();
      if (isLoggedIn) {
        final session = await _prefsService.getUserSession();
        final uid = session['uid'];
        final email = session['email'];
        final name = session['name'];
        final phone = session['phone'];
        final photoUrl = session['photoUrl'];

        if (uid != null && email != null) {
          _currentUser = UserModel(
            uid: uid,
            email: email,
            displayName: name ?? email.split('@').first,
            phoneNumber: phone,
            photoUrl: photoUrl,
          );
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
    } catch (_) {
      // Bỏ qua lỗi đọc cache
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Thực hiện Đăng nhập
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.login(
        email: email,
        password: password,
      );

      _currentUser = user;
      await _prefsService.saveUserSession(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        phoneNumber: user.phoneNumber,
        photoUrl: user.photoUrl,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Thực hiện Đăng ký tài khoản mới
  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.register(
        email: email,
        password: password,
        displayName: displayName,
      );

      _currentUser = user;
      await _prefsService.saveUserSession(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        phoneNumber: user.phoneNumber,
        photoUrl: user.photoUrl,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cập nhật thông tin hồ sơ người dùng (Họ tên, SĐT, Ảnh đại diện từ máy)
  Future<bool> updateProfile({
    required String displayName,
    String? phoneNumber,
    String? photoUrl,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    String? effectivePhotoUrl = photoUrl ?? _currentUser!.photoUrl;

    try {
      // Nếu là ảnh mới chọn từ thiết bị (chưa phải link http), tải lên Cloudinary khi bấm Lưu
      if (effectivePhotoUrl != null &&
          effectivePhotoUrl.trim().isNotEmpty &&
          !effectivePhotoUrl.trim().startsWith('http')) {
        effectivePhotoUrl = await CloudinaryService.uploadImage(
          effectivePhotoUrl.trim(),
          folder: 'lowland_coffee/avatars',
        );
      }

      final updatedUser = await _authService.updateProfile(
        uid: _currentUser!.uid,
        displayName: displayName,
        phoneNumber: phoneNumber,
        photoUrl: effectivePhotoUrl,
      );

      _currentUser = UserModel(
        uid: updatedUser.uid,
        email: updatedUser.email.isNotEmpty ? updatedUser.email : _currentUser!.email,
        displayName: updatedUser.displayName,
        phoneNumber: updatedUser.phoneNumber ?? phoneNumber,
        photoUrl: updatedUser.photoUrl ?? effectivePhotoUrl,
        role: updatedUser.role,
        isBlocked: updatedUser.isBlocked,
        createdAt: updatedUser.createdAt ?? _currentUser!.createdAt,
      );

      await _prefsService.saveUserSession(
        uid: _currentUser!.uid,
        email: _currentUser!.email,
        displayName: _currentUser!.displayName,
        phoneNumber: _currentUser!.phoneNumber,
        photoUrl: _currentUser!.photoUrl,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Kể cả khi Firestore lỗi mạng tạm thời, vẫn lưu hồ sơ (kèm URL Cloudinary vừa tải) vào Local
      _currentUser = UserModel(
        uid: _currentUser!.uid,
        email: _currentUser!.email,
        displayName: displayName.trim(),
        phoneNumber: phoneNumber?.trim(),
        photoUrl: effectivePhotoUrl,
        role: _currentUser!.role,
        isBlocked: _currentUser!.isBlocked,
      );
      await _prefsService.saveUserSession(
        uid: _currentUser!.uid,
        email: _currentUser!.email,
        displayName: _currentUser!.displayName,
        phoneNumber: _currentUser!.phoneNumber,
        photoUrl: _currentUser!.photoUrl,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  /// Đăng xuất khỏi tài khoản
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      await _prefsService.clearSession();
      _currentUser = null;
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }
}

