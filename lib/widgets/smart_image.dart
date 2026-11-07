import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Widget hiển thị ảnh thông minh hỗ trợ cả URL mạng (https://...) và ảnh chọn từ máy tính (data:image/...;base64,...)
class SmartImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? fallback;

  const SmartImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final defaultFallback = fallback ??
        Container(
          width: width,
          height: height,
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          alignment: Alignment.center,
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
          ),
        );

    final trimmed = imageUrl.trim();
    if (trimmed.isEmpty ||
        trimmed == 'img/logo.png' ||
        trimmed == 'assets/images/logo.png' ||
        trimmed.contains('1517256064527-09c73fc73e38') ||
        trimmed.endsWith('localhost:5555/') ||
        trimmed.endsWith('localhost:5500/')) {
      return defaultFallback;
    }

    // 1. Nếu là ảnh chọn từ máy tính được mã hóa Data URL Base64 (data:image/jpeg;base64,...)
    if (trimmed.startsWith('data:image')) {
      try {
        final commaIdx = trimmed.indexOf(',');
        final base64Str = commaIdx != -1 ? trimmed.substring(commaIdx + 1) : trimmed;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => defaultFallback,
        );
      } catch (_) {
        return defaultFallback;
      }
    }

    // 2. Nếu là đường dẫn ảnh URL thông thường
    return Image.network(
      trimmed,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => defaultFallback,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          width: width,
          height: height,
          color: AppColors.surfaceCream,
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              ),
            ),
          ),
        );
      },
    );
  }
}

