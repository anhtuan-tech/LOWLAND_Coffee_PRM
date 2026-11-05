import 'dart:convert';

/// Mô hình sản phẩm trong Giỏ hàng LOWLAND Coffee
class CartItemModel {
  final int? id;
  final String productId;
  final String name;
  final String imageUrl;
  final double basePrice;
  final String selectedSize; // 'S', 'M', 'L'
  final int selectedSugar; // 0, 30, 50, 70, 100
  final int selectedIce; // 0, 30, 50, 70, 100
  final List<String> selectedToppings;
  final double itemPrice; // Đơn giá sau khi cộng Size và Toppings
  final int quantity;
  final double totalPrice;
  final String createdAt;

  CartItemModel({
    this.id,
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.basePrice,
    required this.selectedSize,
    required this.selectedSugar,
    required this.selectedIce,
    required this.selectedToppings,
    required this.itemPrice,
    required this.quantity,
    required this.totalPrice,
    required this.createdAt,
  });

  CartItemModel copyWith({
    int? id,
    String? productId,
    String? name,
    String? imageUrl,
    double? basePrice,
    String? selectedSize,
    int? selectedSugar,
    int? selectedIce,
    List<String>? selectedToppings,
    double? itemPrice,
    int? quantity,
    double? totalPrice,
    String? createdAt,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      basePrice: basePrice ?? this.basePrice,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedSugar: selectedSugar ?? this.selectedSugar,
      selectedIce: selectedIce ?? this.selectedIce,
      selectedToppings: selectedToppings ?? this.selectedToppings,
      itemPrice: itemPrice ?? this.itemPrice,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'name': name,
      'imageUrl': imageUrl,
      'basePrice': basePrice,
      'selectedSize': selectedSize,
      'selectedSugar': selectedSugar,
      'selectedIce': selectedIce,
      'selectedToppings': jsonEncode(selectedToppings),
      'itemPrice': itemPrice,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'createdAt': createdAt,
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    List<String> toppings = [];
    if (map['selectedToppings'] != null) {
      try {
        final decoded = jsonDecode(map['selectedToppings']);
        if (decoded is List) {
          toppings = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        toppings = [];
      }
    }

    return CartItemModel(
      id: map['id'] as int?,
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      basePrice: (map['basePrice'] as num?)?.toDouble() ?? 0.0,
      selectedSize: map['selectedSize'] ?? 'M',
      selectedSugar: (map['selectedSugar'] as num?)?.toInt() ?? 100,
      selectedIce: (map['selectedIce'] as num?)?.toInt() ?? 100,
      selectedToppings: toppings,
      itemPrice: (map['itemPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}

