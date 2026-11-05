import 'package:flutter/material.dart';

/// Bảng màu chủ đạo của ứng dụng LOWLAND Coffee
/// Phong cách: Nâu Cà phê (Espresso/Mocha) kết hợp Kem (Cream/Latte) sang trọng
class AppColors {
  AppColors._();

  // Primary Colors (Tông Nâu Đậm Đà)
  static const Color primary = Color(0xFF4A2810); // Nâu Espresso chủ đạo
  static const Color primaryDark = Color(0xFF2E1708); // Nâu rang đậm
  static const Color primaryLight = Color(0xFF7A4B29); // Nâu caramel ấm

  // Secondary & Accent Colors (Tông Vàng Đồng & Caramel)
  static const Color accent = Color(0xFFC68B45); // Vàng hổ phách / mật ong
  static const Color accentLight = Color(0xFFDEAF74); // Vàng kem nhạt
  static const Color accentDark = Color(0xFFA16B28);

  // Background & Surface (Tông Kem & Sữa)
  static const Color background = Color(0xFFFAF6F0); // Kem sáng làm nền toàn app
  static const Color surface = Color(0xFFFFFFFF); // Màu thẻ / card trắng ngà
  static const Color surfaceCream = Color(0xFFF3ECE1); // Kem sữa đậm cho card phụ
  static const Color surfaceVariant = Color(0xFFECE4D8);

  // Text Colors
  static const Color textPrimary = Color(0xFF26180E); // Chữ chính nâu đậm, sắc nét
  static const Color textSecondary = Color(0xFF6E5D53); // Chữ phụ xám nâu
  static const Color textMuted = Color(0xFF9E8E85); // Chữ ghi chú mờ
  static const Color textLight = Color(0xFFFFFFFF); // Chữ trắng trên nền nâu

  // Border & Divider
  static const Color border = Color(0xFFE5DACD); // Đường viền kem
  static const Color divider = Color(0xFFEFE8DF);

  // Status & Utility Colors
  static const Color success = Color(0xFF2E7D32); // Xanh lá cây thông báo
  static const Color error = Color(0xFFC62828); // Đỏ cảnh báo / xóa
  static const Color warning = Color(0xFFF57C00); // Cam cảnh báo
  static const Color star = Color(0xFFFFB300); // Vàng đánh giá sao
}

