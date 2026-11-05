import 'dart:convert';
import 'cart_item_model.dart';

/// Mô hình Đơn hàng đã đặt / Lịch sử đơn hàng
class OrderModel {
  final int? id; // SQLite ID
  final String orderId;
  final String userId;
  final List<CartItemModel> items;
  final double subtotal;
  final double discount;
  final String? voucherCode;
  final double totalAmount;
  final String orderDate;
  final String status; // 'Mới nhận', 'Đang chế biến', 'Đang giao', 'Hoàn thành', 'Đã hủy'
  final String paymentMethod; // 'Tiền mặt (COD)', 'VNPAY Sandbox'

  OrderModel({
    this.id,
    required this.orderId,
    required this.userId,
    required this.items,
    required this.subtotal,
    this.discount = 0.0,
    this.voucherCode,
    required this.totalAmount,
    required this.orderDate,
    this.status = 'Mới nhận',
    this.paymentMethod = 'Tiền mặt (COD)',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'userId': userId,
      'itemsJson': jsonEncode(items.map((i) => i.toMap()).toList()),
      'subtotal': subtotal,
      'discount': discount,
      'voucherCode': voucherCode,
      'totalAmount': totalAmount,
      'orderDate': orderDate,
      'status': status,
      'paymentMethod': paymentMethod,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    List<CartItemModel> itemsList = [];
    if (map['itemsJson'] != null) {
      try {
        final decoded = jsonDecode(map['itemsJson']);
        if (decoded is List) {
          itemsList = decoded
              .map((item) => CartItemModel.fromMap(item as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {
        itemsList = [];
      }
    }

    return OrderModel(
      id: map['id'] as int?,
      orderId: map['orderId'] ?? '',
      userId: map['userId'] ?? '',
      items: itemsList,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      voucherCode: map['voucherCode'],
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      orderDate: map['orderDate'] ?? DateTime.now().toIso8601String(),
      status: map['status'] ?? 'Mới nhận',
      paymentMethod: map['paymentMethod'] ?? 'Tiền mặt (COD)',
    );
  }
}
