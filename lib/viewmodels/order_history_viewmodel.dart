import 'package:flutter/material.dart';
import '../data/models/order_model.dart';
import '../data/services/local/database_helper.dart';
import '../data/services/remote/firestore_service.dart';

/// ViewModel quản lý Lịch sử đơn hàng (Order History: Kết hợp SQLite Cục bộ + Đồng bộ Cloud Firestore)
class OrderHistoryViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FirestoreService _firestoreService = FirestoreService.instance;

  List<OrderModel> _orders = [];
  bool _isLoading = false;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  OrderHistoryViewModel() {
    // Không nạp all orders khi chưa biết userId
  }

  Future<void> loadOrders({String? userId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (userId == null || userId.isEmpty) {
        _orders = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 1. Tải từ bộ nhớ cục bộ (SQLite / LocalStorage) theo đúng userId
      final localOrders = await _dbHelper.getOrderHistory(userId: userId);
      _orders = localOrders;
      notifyListeners();

      // 2. Đồng bộ thêm các đơn hàng từ Cloud Firestore đúng của userId
      final remoteOrders = await _firestoreService.getOrdersFromFirestore(userId: userId);
      if (remoteOrders.isNotEmpty) {
        final Map<String, OrderModel> mergedMap = {
          for (final o in localOrders) o.orderId: o,
        };
        for (final remoteOrder in remoteOrders) {
          mergedMap[remoteOrder.orderId] = remoteOrder;
          // Lưu ngược lại xuống Local để lần sau mở offline vẫn có
          await _dbHelper.insertOrder(remoteOrder);
        }
        final mergedList = mergedMap.values.where((o) => o.userId == userId).toList();
        mergedList.sort((a, b) => b.orderDate.compareTo(a.orderDate));
        _orders = mergedList;
      }
    } catch (_) {
      // Giữ nguyên danh sách local nếu mất mạng
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Hủy đơn hàng khi đơn đang ở trạng thái 'Mới nhận' (chưa pha chế)
  Future<bool> cancelOrder(String orderId, {String? userId}) async {
    try {
      await _dbHelper.updateOrderStatus(orderId, 'Đã hủy');
      await _firestoreService.updateOrderStatusInFirestore(orderId, 'Đã hủy');
      await loadOrders(userId: userId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
