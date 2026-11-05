import 'package:flutter/material.dart';
import '../data/models/order_model.dart';
import '../data/services/local/database_helper.dart';

/// ViewModel quản lý Lịch sử đơn hàng (Order History)
class OrderHistoryViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<OrderModel> _orders = [];
  bool _isLoading = false;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  OrderHistoryViewModel() {
    loadOrders();
  }

  Future<void> loadOrders({String? userId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _orders = await _dbHelper.getOrderHistory(userId: userId);
    } catch (_) {
      _orders = [];
    }

    _isLoading = false;
    notifyListeners();
  }
}

