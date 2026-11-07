import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../models/user_model.dart';

/// Dịch vụ Xác thực Firebase Authentication
class FirebaseAuthService {
  static final FirebaseAuthService instance = FirebaseAuthService._init();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseAuthService._init();

  /// Stream theo dõi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// User hiện tại
  User? get currentUser => _auth.currentUser;

  /// Đăng ký tài khoản mới bằng Email và Mật khẩu
  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Không thể tạo tài khoản người dùng.');
      }

      // Cập nhật tên hiển thị
      await user.updateDisplayName(displayName.trim());

      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? email,
        displayName: displayName.trim(),
        role: 'customer',
        isBlocked: false,
        createdAt: DateTime.now(),
      );

      // Lưu hồ sơ người dùng vào Firestore
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(user.uid)
          .set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Đã xảy ra lỗi khi đăng ký: ${e.toString()}');
    }
  }

  /// Đăng nhập bằng Email và Mật khẩu
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Tài khoản hoặc mật khẩu không chính xác.');
      }

      // Lấy thêm thông tin từ Firestore nếu có
      final doc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final userModel = UserModel.fromMap(doc.data()!, user.uid);
        if (userModel.isBlocked) {
          await _auth.signOut();
          throw Exception('Tài khoản của bạn đã bị Quản trị viên vô hiệu hóa/khóa quyền truy cập.');
        }
        return userModel;
      } else {
        return UserModel(
          uid: user.uid,
          email: user.email ?? email,
          displayName: user.displayName ?? email.split('@').first,
          role: 'customer',
          isBlocked: false,
          createdAt: DateTime.now(),
        );
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Đã xảy ra lỗi khi đăng nhập: ${e.toString()}');
    }
  }

  /// Đăng xuất khỏi Firebase
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Cập nhật thông tin hồ sơ người dùng (Họ tên, Số điện thoại, Ảnh đại diện chọn từ máy)
  Future<UserModel> updateProfile({
    required String uid,
    required String displayName,
    String? phoneNumber,
    String? photoUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName.trim());
        if (photoUrl != null && photoUrl.trim().startsWith('http')) {
          try {
            await user.updatePhotoURL(photoUrl.trim());
          } catch (_) {}
        }
      }

      final Map<String, dynamic> updateData = {
        'uid': uid,
        'displayName': displayName.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (user?.email != null) {
        updateData['email'] = user!.email;
      }
      if (phoneNumber != null) {
        updateData['phoneNumber'] = phoneNumber.trim();
      }
      if (photoUrl != null && photoUrl.trim().isNotEmpty) {
        updateData['photoUrl'] = photoUrl.trim();
      }

      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .set(updateData, SetOptions(merge: true));

      final doc = await _firestore.collection(AppConstants.collectionUsers).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, uid);
      } else {
        return UserModel(
          uid: uid,
          email: user?.email ?? '',
          displayName: displayName.trim(),
          phoneNumber: phoneNumber,
          photoUrl: photoUrl,
        );
      }
    } catch (e) {
      throw Exception('Không thể cập nhật hồ sơ: ${e.toString()}');
    }
  }

  /// Chuyển đổi mã lỗi Firebase thành thông báo tiếng Việt thân thiện
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Tài khoản không tồn tại trong hệ thống.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không chính xác.';
      case 'email-already-in-use':
        return 'Email này đã được đăng ký tài khoản khác.';
      case 'invalid-email':
        return 'Định dạng email không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu quá yếu (yêu cầu tối thiểu 6 ký tự).';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng, vui lòng kiểm tra Internet của bạn.';
      case 'too-many-requests':
        return 'Đã thử quá nhiều lần. Vui lòng thử lại sau ít phút.';
      default:
        return e.message ?? 'Lỗi xác thực: ${e.code}';
    }
  }
}

