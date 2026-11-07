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
  final String deliveryType; // 'Giao tận nơi' hoặc 'Dùng tại quán / Tự lấy'
  final String receiverPhone;
  final String deliveryAddress;
  final String orderNote;

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
    this.deliveryType = 'Giao tận nơi',
    this.receiverPhone = '',
    this.deliveryAddress = '',
    this.orderNote = '',
  });

  OrderModel copyWith({
    int? id,
    String? status,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderId: orderId,
      userId: userId,
      items: items,
      subtotal: subtotal,
      discount: discount,
      voucherCode: voucherCode,
      totalAmount: totalAmount,
      orderDate: orderDate,
      status: status ?? this.status,
      paymentMethod: paymentMethod,
      deliveryType: deliveryType,
      receiverPhone: receiverPhone,
      deliveryAddress: deliveryAddress,
      orderNote: orderNote,
    );
  }

  /// Map chuẩn cho bảng SQLite (giữ nguyên các cột của bảng order_history)
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

  /// Map đầy đủ cho Cloud Firestore và LocalStorage (bao gồm danh sách items, SĐT, Địa chỉ, Ghi chú)
  Map<String, dynamic> toFullMap() {
    return {
      ...toMap(),
      'items': items.map((i) => i.toMap()).toList(),
      'deliveryType': deliveryType,
      'receiverPhone': receiverPhone,
      'deliveryAddress': deliveryAddress,
      'orderNote': orderNote,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    List<CartItemModel> itemsList = [];
    if (map['itemsJson'] != null) {
      try {
        final decoded = jsonDecode(map['itemsJson']);
        if (decoded is List) {
          itemsList = decoded
              .map((item) => CartItemModel.fromMap(Map<String, dynamic>.from(item as Map)))
              .toList();
        }
      } catch (_) {
        itemsList = [];
      }
    }

    return OrderModel(
      id: map['id'] as int?,
      orderId: map['orderId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      items: itemsList,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      voucherCode: map['voucherCode']?.toString(),
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      orderDate: map['orderDate']?.toString() ?? DateTime.now().toIso8601String(),
      status: map['status']?.toString() ?? 'Mới nhận',
      paymentMethod: map['paymentMethod']?.toString() ?? 'Tiền mặt (COD)',
      deliveryType: map['deliveryType']?.toString() ?? 'Giao tận nơi',
      receiverPhone: map['receiverPhone']?.toString() ?? '',
      deliveryAddress: map['deliveryAddress']?.toString() ?? '',
      orderNote: map['orderNote']?.toString() ?? '',
    );
  }
}
