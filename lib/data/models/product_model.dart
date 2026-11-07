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
    this.availableToppings = const [],
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
    final category = map['category']?.toString() ?? 'Cà phê';
    final rawSizes = (map['availableSizes'] as List<dynamic>?)
        ?.map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final rawToppings = (map['availableToppings'] as List<dynamic>?)
        ?.map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return ProductModel(
      id: docId ?? map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      category: category,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'] ?? '',
      availableSizes: (rawSizes != null && rawSizes.isNotEmpty)
          ? rawSizes
          : (category == 'Bánh' ? const ['M'] : const ['S', 'M', 'L']),
      availableToppings: rawToppings ?? const [],
      isAvailable: map['isAvailable'] ?? true,
    );
  }
}

