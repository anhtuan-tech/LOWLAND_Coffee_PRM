/// Loại giảm giá của Voucher
enum VoucherType { percentage, fixed }

/// Mô hình dữ liệu cho Mã giảm giá (Vouchers) LOWLAND Coffee
class VoucherModel {
  final String code;
  final String title;
  final String description;
  final VoucherType type;
  final double discountValue; // Giá trị giảm (Ví dụ: 15% hoặc 20.000đ)
  final double minOrderValue; // Giá trị đơn tối thiểu để áp dụng
  final double? maxDiscount; // Giảm tối đa (đối với loại %)
  final DateTime expiryDate;

  // Các điều kiện nâng cao của Voucher
  final bool onlyFirstOrder; // Chỉ áp dụng cho Đơn hàng đầu tiên của khách mới
  final bool oncePerUser; // Mỗi tài khoản khách hàng chỉ được dùng tối đa 1 lần
  final String applicableCategory; // 'all', 'Cà phê', 'Trà', 'Bánh', 'Trà & Bánh'
  final int? usageLimit; // Giới hạn tổng số lượt dùng toàn hệ thống (null = không giới hạn)
  final int usedCount; // Số lượt đã sử dụng

  VoucherModel({
    required this.code,
    required this.title,
    required this.description,
    required this.type,
    required this.discountValue,
    this.minOrderValue = 0.0,
    this.maxDiscount,
    required this.expiryDate,
    this.onlyFirstOrder = false,
    this.oncePerUser = false,
    this.applicableCategory = 'all',
    this.usageLimit,
    this.usedCount = 0,
  });

  /// Kiểm tra xem Voucher đã hết hạn theo thời gian thực hay chưa
  bool get isExpired {
    return DateTime.now().isAfter(expiryDate);
  }

  /// Kiểm tra xem Voucher đã hết lượt sử dụng toàn hệ thống chưa
  bool get isOutOfStock {
    if (usageLimit == null || usageLimit! <= 0) return false;
    return usedCount >= usageLimit!;
  }

  /// Số ngày còn lại trước khi hết hạn (0 nếu đã hết hạn)
  int get remainingDays {
    final diff = expiryDate.difference(DateTime.now());
    if (diff.isNegative) return 0;
    return diff.inDays + 1;
  }

  /// Tính số tiền giảm giá thực tế dựa trên giá trị đơn hàng
  double calculateDiscount(double subtotal) {
    if (isExpired || isOutOfStock || subtotal < minOrderValue) {
      return 0.0;
    }

    if (type == VoucherType.fixed) {
      return discountValue > subtotal ? subtotal : discountValue;
    } else {
      double calculated = subtotal * (discountValue / 100);
      if (maxDiscount != null && calculated > maxDiscount!) {
        return maxDiscount!;
      }
      return calculated;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'title': title,
      'description': description,
      'type': type.name,
      'discountValue': discountValue,
      'minOrderValue': minOrderValue,
      'maxDiscount': maxDiscount,
      'expiryDate': expiryDate.toIso8601String(),
      'onlyFirstOrder': onlyFirstOrder,
      'oncePerUser': oncePerUser,
      'applicableCategory': applicableCategory,
      'usageLimit': usageLimit,
      'usedCount': usedCount,
    };
  }

  factory VoucherModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parsedExpiry = DateTime.now().add(const Duration(days: 30));
    if (map['expiryDate'] != null) {
      final raw = map['expiryDate'].toString().trim();
      final dt = DateTime.tryParse(raw);
      if (dt != null) {
        final localDt = dt.toLocal();
        if (localDt.hour == 0 && localDt.minute == 0 && localDt.second == 0) {
          parsedExpiry = DateTime(localDt.year, localDt.month, localDt.day, 23, 59, 59);
        } else {
          parsedExpiry = localDt;
        }
      }
    }

    final codeStr = (map['code'] ?? docId ?? '').toString().trim();
    final descStr = map['description']?.toString() ?? '';
    final upperCode = codeStr.toUpperCase();

    final bool inferredFirstOrder = upperCode == 'LOWLANDNEW' ||
        descStr.toLowerCase().contains('đơn hàng đầu tiên') ||
        descStr.toLowerCase().contains('đơn đầu tiên');

    final String inferredCategory = upperCode == 'TRAXANH15'
        ? 'Trà & Bánh'
        : (map['applicableCategory']?.toString() ?? 'all');

    final bool onlyFirst = map['onlyFirstOrder'] is bool
        ? map['onlyFirstOrder'] as bool
        : inferredFirstOrder;

    return VoucherModel(
      code: codeStr,
      title: map['title']?.toString() ?? 'Mã ưu đãi LOWLAND',
      description: descStr,
      type: map['type'] == 'fixed' ? VoucherType.fixed : VoucherType.percentage,
      discountValue: (map['discountValue'] as num?)?.toDouble() ?? 0.0,
      minOrderValue: (map['minOrderValue'] as num?)?.toDouble() ?? 0.0,
      maxDiscount: (map['maxDiscount'] as num?)?.toDouble(),
      expiryDate: parsedExpiry,
      onlyFirstOrder: onlyFirst,
      oncePerUser: map['oncePerUser'] is bool ? (map['oncePerUser'] as bool) : onlyFirst,
      applicableCategory: inferredCategory.isEmpty ? 'all' : inferredCategory,
      usageLimit: (map['usageLimit'] as num?)?.toInt(),
      usedCount: (map['usedCount'] as num?)?.toInt() ?? 0,
    );
  }
}
