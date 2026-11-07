import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/product_model.dart';
import '../data/services/remote/firestore_service.dart';

/// ViewModel quản lý Thực đơn, Danh mục và Tìm kiếm theo thời gian thực
class MenuViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService.instance;

  StreamSubscription<List<ProductModel>>? _streamSubscription;
  List<ProductModel> _allProducts = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedCategory = 'Tất cả';
  String _searchQuery = '';

  List<ProductModel> get allProducts => _allProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  MenuViewModel() {
    initMenu();
  }

  /// Khởi tạo thực đơn và kết nối Realtime Stream
  Future<void> initMenu() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Tự động chèn dữ liệu mẫu nếu Firestore còn trống
      await _firestoreService.seedInitialProductsIfEmpty();

      // Lắng nghe Realtime Stream từ Firestore
      _streamSubscription?.cancel();
      _streamSubscription = _firestoreService.getProductsStream().listen(
        (products) {
          _allProducts = products;
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        },
        onError: (error) {
          _errorMessage = 'Không thể tải dữ liệu thời gian thực: $error';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = 'Lỗi kết nối Firestore: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Chọn danh mục sản phẩm (Category Filter)
  void selectCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  /// Cập nhật từ khóa tìm kiếm
  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  /// Danh sách sản phẩm sau khi áp dụng Danh mục & Tìm kiếm
  List<ProductModel> get filteredProducts {
    return _allProducts.where((product) {
      // 1. Lọc theo danh mục
      final matchesCategory = _selectedCategory == 'Tất cả' ||
          product.category.toLowerCase() == _selectedCategory.toLowerCase();

      // 2. Lọc theo từ khóa tìm kiếm
      final matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.description.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}

