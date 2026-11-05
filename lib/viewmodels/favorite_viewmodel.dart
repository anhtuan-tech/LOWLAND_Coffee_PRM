import 'package:flutter/material.dart';
import '../data/models/product_model.dart';
import '../data/services/local/database_helper.dart';

/// ViewModel quản lý Danh sách món yêu thích (Favorites)
class FavoriteViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<ProductModel> _favorites = [];
  bool _isLoading = false;

  List<ProductModel> get favorites => _favorites;
  bool get isLoading => _isLoading;

  FavoriteViewModel() {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      _favorites = await _dbHelper.getFavorites();
    } catch (_) {
      _favorites = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> removeFavorite(String productId) async {
    await _dbHelper.removeFavorite(productId);
    await loadFavorites();
  }

  Future<void> addFavorite(ProductModel product) async {
    await _dbHelper.addFavorite(product);
    await loadFavorites();
  }

  Future<bool> isFavorite(String productId) async {
    return await _dbHelper.isFavorite(productId);
  }
}

