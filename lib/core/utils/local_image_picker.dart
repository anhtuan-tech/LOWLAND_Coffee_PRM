import '../../data/services/remote/cloudinary_service.dart';
import 'local_image_picker_stub.dart'
    if (dart.library.html) 'local_image_picker_web.dart'
    if (dart.library.io) 'local_image_picker_io.dart';

/// Tiện ích chọn ảnh trực tiếp từ máy tính / thiết bị (hỗ trợ cả Web và Desktop/Mobile)
/// và tải lên Cloudinary khi người dùng bấm Lưu.
class LocalImagePicker {
  /// Chỉ chọn ảnh từ thiết bị và trả về chuỗi Data URL (`data:image/...;base64,...`) để xem trước (Preview)
  /// Chưa tải lên Cloudinary cho tới khi người dùng bấm nút "Lưu thay đổi".
  static Future<String?> pickLocalImagePreview() async {
    final rawDataUrl = await pickImagePlatform();
    if (rawDataUrl == null || rawDataUrl.isEmpty) return null;
    return rawDataUrl;
  }

  /// Tải ảnh đang xem trước lên Cloudinary (nếu là ảnh mới dạng Base64 Data URL)
  static Future<String> uploadToCloudinary(
    String imageUrlOrDataUrl, {
    String folder = 'lowland_coffee/avatars',
  }) async {
    if (imageUrlOrDataUrl.isEmpty || imageUrlOrDataUrl.startsWith('http')) {
      return imageUrlOrDataUrl;
    }
    return await CloudinaryService.uploadImage(
      imageUrlOrDataUrl,
      folder: folder,
    );
  }

  /// Chọn ảnh và đẩy ngay lên Cloudinary
  static Future<String?> pickImageAsDataUrl({
    String folder = 'lowland_coffee/avatars',
  }) async {
    final rawDataUrl = await pickImagePlatform();
    if (rawDataUrl == null || rawDataUrl.isEmpty) return null;

    return await CloudinaryService.uploadImage(
      rawDataUrl,
      folder: folder,
    );
  }
}

