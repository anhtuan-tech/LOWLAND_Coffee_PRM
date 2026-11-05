/// Mô hình dữ liệu cho Sản phẩm (Đồ uống / Bánh) trong menu LOWLAND Coffee
class ProductModel {
  final String id;
  final String name;
  final String category; // Cà phê, Trà, Bánh
  final double price;
  final String imageUrl;
  final String description;
  final List<String> availableSizes; // S, M, L
  final List<String> availableToppings; // Thạch cà phê, Trân châu trắng, Kem cheese, v.v.
  final bool isAvailable;

  ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.description,
    this.availableSizes = const ['S', 'M', 'L'],
    this.availableToppings = const [
      'Thạch cà phê (+6.000đ)',
      'Trân châu trắng (+6.000đ)',
      'Kem Cheese (+10.000đ)',
      'Shot Espresso (+10.000đ)',
    ],
    this.isAvailable = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'imageUrl': imageUrl,
      'description': description,
      'availableSizes': availableSizes,
      'availableToppings': availableToppings,
      'isAvailable': isAvailable,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return ProductModel(
      id: docId ?? map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? 'Cà phê',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'] ?? '',
      availableSizes: (map['availableSizes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['S', 'M', 'L'],
      availableToppings: (map['availableToppings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [
            'Thạch cà phê (+6.000đ)',
            'Trân châu trắng (+6.000đ)',
            'Kem Cheese (+10.000đ)',
          ],
      isAvailable: map['isAvailable'] ?? true,
    );
  }
}

