import 'package:flutter/material.dart';
import '../data/models/cart_item_model.dart';
import '../data/models/product_model.dart';
import '../data/services/local/database_helper.dart';

/// ViewModel quản lý Chi tiết món & Logic Tùy chọn (Customization)
class ProductDetailViewModel extends ChangeNotifier {
  final ProductModel product;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  String _selectedSize = 'S';
  int _selectedSugar = 100; // 0, 30, 50, 70, 100
  int _selectedIce = 100; // 0, 30, 50, 70, 100
  final List<String> _selectedToppings = [];
  int _quantity = 1;

  bool _isFavorite = false;
  bool _isAddingToCart = false;

  String get selectedSize => _selectedSize;
  int get selectedSugar => _selectedSugar;
  int get selectedIce => _selectedIce;
  List<String> get selectedToppings => List.unmodifiable(_selectedToppings);
  int get quantity => _quantity;
  bool get isFavorite => _isFavorite;
  bool get isAddingToCart => _isAddingToCart;

  ProductDetailViewModel({required this.product}) {
    // Khởi tạo Size mặc định: Ưu tiên Size S (giá gốc) hoặc phần tử đầu tiên trong availableSizes
    if (product.availableSizes.isNotEmpty) {
      if (product.availableSizes.contains('S')) {
        _selectedSize = 'S';
      } else {
        _selectedSize = product.availableSizes.first;
      }
    } else {
      _selectedSize = 'S';
    }
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    _isFavorite = await _dbHelper.isFavorite(product.id);
    notifyListeners();
  }

  /// Bật/Tắt yêu thích
  Future<void> toggleFavorite() async {
    if (_isFavorite) {
      await _dbHelper.removeFavorite(product.id);
      _isFavorite = false;
    } else {
      await _dbHelper.addFavorite(product);
      _isFavorite = true;
    }
    notifyListeners();
  }

  /// Chọn kích cỡ (Size)
  void setSize(String size) {
    if (_selectedSize != size) {
      _selectedSize = size;
      notifyListeners();
    }
  }

  /// Chọn mức đường
  void setSugar(int sugar) {
    if (_selectedSugar != sugar) {
      _selectedSugar = sugar;
      notifyListeners();
    }
  }

  /// Chọn mức đá
  void setIce(int ice) {
    if (_selectedIce != ice) {
      _selectedIce = ice;
      notifyListeners();
    }
  }

  /// Chọn hoặc hủy Topping
  void toggleTopping(String topping) {
    if (_selectedToppings.contains(topping)) {
      _selectedToppings.remove(topping);
    } else {
      _selectedToppings.add(topping);
    }
    notifyListeners();
  }

  /// Tăng số lượng
  void increaseQuantity() {
    _quantity++;
    notifyListeners();
  }

  /// Giảm số lượng
  void decreaseQuantity() {
    if (_quantity > 1) {
      _quantity--;
      notifyListeners();
    }
  }

  /// Phụ phí theo kích cỡ Size
  double get sizeExtraPrice {
    // Nếu món là Bánh hoặc chỉ có 1 size duy nhất thì không tính phụ phí size
    if (product.category == 'Bánh' || product.availableSizes.length <= 1) {
      return 0.0;
    }
    switch (_selectedSize) {
      case 'M':
        return 6000.0;
      case 'L':
        return 10000.0;
      case 'S':
      default:
        return 0.0;
    }
  }

  /// Phụ phí các Topping đã chọn
  double get toppingsExtraPrice {
    double extra = 0.0;
    for (final topping in _selectedToppings) {
      if (topping.contains('10.000')) {
        extra += 10000.0;
      } else if (topping.contains('8.000')) {
        extra += 8000.0;
      } else if (topping.contains('6.000')) {
        extra += 6000.0;
      } else {
        extra += 6000.0;
      }
    }
    return extra;
  }

  /// Đơn giá 1 ly/món sau khi cộng phụ phí tùy chọn
  double get unitPrice {
    return product.price + sizeExtraPrice + toppingsExtraPrice;
  }

  /// Tổng tiền = Đơn giá * Số lượng
  double get totalPrice {
    return unitPrice * _quantity;
  }

  /// Thêm món vào Giỏ hàng lưu trữ bằng SQLite
  Future<bool> addToCart() async {
    _isAddingToCart = true;
    notifyListeners();

    try {
      final cartItem = CartItemModel(
        productId: product.id,
        name: product.name,
        imageUrl: product.imageUrl,
        basePrice: product.price,
        selectedSize: _selectedSize,
        selectedSugar: _selectedSugar,
        selectedIce: _selectedIce,
        selectedToppings: _selectedToppings,
        itemPrice: unitPrice,
        quantity: _quantity,
        totalPrice: totalPrice,
        createdAt: DateTime.now().toIso8601String(),
      );

      await _dbHelper.insertOrUpdateCartItem(cartItem);
      _isAddingToCart = false;
      notifyListeners();
      return true;
    } catch (_) {
      _isAddingToCart = false;
      notifyListeners();
      return false;
    }
  }
}

