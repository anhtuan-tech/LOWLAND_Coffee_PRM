import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

/// Dịch vụ lưu trữ hình ảnh đám mây miễn phí qua Cloudinary REST API (Unsigned Upload)
/// Dùng để lưu trữ ảnh sản phẩm (Menu) & ảnh đại diện khách hàng (Avatar) hoàn toàn miễn phí.
class CloudinaryService {
  // ===========================================================================
  // CẤU HÌNH CLOUDINARY (Bạn có thể điền trực tiếp ở đây HOẶC nhập trên Web Admin)
  // ===========================================================================
  static const String defaultCloudName = 'bflxgvhn'; // VD: 'dxyz12345'
  static const String defaultUploadPreset = 'lowland_unsigned'; // VD: 'lowland_unsigned'

  static String? _cachedCloudName;
  static String? _cachedUploadPreset;

  /// Bộ nhớ đệm giúp không upload lại cùng một bức ảnh nhiều lần lên Cloudinary
  static final Map<int, String> _uploadedUrlCache = {};

  /// Đọc cấu hình Cloudinary (ưu tiên hằng số trong code, nếu để trống sẽ tự động lấy từ Firestore `settings/cloudinary`)
  static Future<Map<String, String>> getCredentials() async {
    if (defaultCloudName.trim().isNotEmpty &&
        defaultUploadPreset.trim().isNotEmpty) {
      return {
        'cloudName': defaultCloudName.trim(),
        'uploadPreset': defaultUploadPreset.trim(),
      };
    }

    if (_cachedCloudName != null && _cachedCloudName!.isNotEmpty) {
      return {
        'cloudName': _cachedCloudName!,
        'uploadPreset': _cachedUploadPreset ?? 'lowland_unsigned',
      };
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('cloudinary')
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final cn = (data['cloudName'] as String? ?? '').trim();
        final up = (data['uploadPreset'] as String? ?? '').trim();
        if (cn.isNotEmpty && up.isNotEmpty) {
          _cachedCloudName = cn;
          _cachedUploadPreset = up;
          return {'cloudName': cn, 'uploadPreset': up};
        }
      }
    } catch (_) {}

    return {'cloudName': '', 'uploadPreset': ''};
  }

  /// Tải ảnh (dạng chuỗi Base64 Data URL `data:image/jpeg;base64,...` hoặc URL) lên Cloudinary
  /// Trả về đường dẫn HTTPS (`secure_url`) trên Cloudinary.
  /// Nếu chưa cấu hình Cloudinary hoặc mất mạng, trả về chính `dataUrlOrBase64` để App không bao giờ lỗi.
  static Future<String> uploadImage(
    String dataUrlOrBase64, {
    String folder = 'lowland_coffee/avatars',
  }) async {
    final trimmed = dataUrlOrBase64.trim();
    if (trimmed.isEmpty || trimmed.startsWith('http')) {
      return trimmed;
    }

    // Kiểm tra cache để tránh upload trùng lặp cùng 1 bức ảnh
    final cacheKey = trimmed.hashCode;
    if (_uploadedUrlCache.containsKey(cacheKey)) {
      return _uploadedUrlCache[cacheKey]!;
    }

    try {
      final creds = await getCredentials();
      final cloudName = creds['cloudName'] ?? '';
      final uploadPreset = creds['uploadPreset'] ?? '';

      // Nếu người dùng chưa điền Cloud Name thì giữ nguyên ảnh nén Base64 dự phòng
      if (cloudName.isEmpty || uploadPreset.isEmpty) {
        return trimmed;
      }

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      // Cách 1: Gửi dạng Multipart FormData (chuẩn giống Web Admin, nhanh và ổn định nhất)
      try {
        final commaIdx = trimmed.indexOf(',');
        final rawBase64 =
            commaIdx != -1 ? trimmed.substring(commaIdx + 1) : trimmed;
        final bytes = base64Decode(rawBase64);

        final request = http.MultipartRequest('POST', uri)
          ..fields['upload_preset'] = uploadPreset
          ..fields['folder'] = folder
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              bytes,
              filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
            ),
          );

        final streamedResponse =
            await request.send().timeout(const Duration(seconds: 20));
        final responseBody = await streamedResponse.stream.bytesToString();

        if (streamedResponse.statusCode == 200) {
          final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
          final secureUrl = decoded['secure_url'] as String?;
          if (secureUrl != null && secureUrl.isNotEmpty) {
            _uploadedUrlCache[cacheKey] = secureUrl;
            return secureUrl;
          }
        }
      } catch (_) {
        // Nếu Multipart gặp lỗi thì chuyển sang Cách 2 bên dưới
      }

      // Cách 2: Gửi trực tiếp chuỗi Data URL qua HTTP POST
      final dataUrlPayload = trimmed.startsWith('data:image')
          ? trimmed
          : 'data:image/jpeg;base64,$trimmed';

      final response = await http
          .post(
            uri,
            body: {
              'file': dataUrlPayload,
              'upload_preset': uploadPreset,
              'folder': folder,
            },
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final secureUrl = decoded['secure_url'] as String?;
        if (secureUrl != null && secureUrl.isNotEmpty) {
          _uploadedUrlCache[cacheKey] = secureUrl;
          return secureUrl;
        }
      }
    } catch (_) {
      // Dự phòng an toàn khi offline
    }

    return trimmed;
  }
}

