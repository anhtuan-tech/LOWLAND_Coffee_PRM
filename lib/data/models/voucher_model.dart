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

  VoucherModel({
    required this.code,
    required this.title,
    required this.description,
    required this.type,
    required this.discountValue,
    this.minOrderValue = 0.0,
    this.maxDiscount,
    required this.expiryDate,
  });

  /// Tính số tiền giảm giá thực tế dựa trên giá trị đơn hàng
  double calculateDiscount(double subtotal) {
    if (subtotal < minOrderValue) {
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
    };
  }

  factory VoucherModel.fromMap(Map<String, dynamic> map) {
    return VoucherModel(
      code: map['code'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] == 'fixed' ? VoucherType.fixed : VoucherType.percentage,
      discountValue: (map['discountValue'] as num?)?.toDouble() ?? 0.0,
      minOrderValue: (map['minOrderValue'] as num?)?.toDouble() ?? 0.0,
      maxDiscount: (map['maxDiscount'] as num?)?.toDouble(),
      expiryDate: map['expiryDate'] != null
          ? DateTime.tryParse(map['expiryDate'].toString()) ??
              DateTime.now().add(const Duration(days: 30))
          : DateTime.now().add(const Duration(days: 30)),
    );
  }
}

