import 'package:flutter/material.dart';
import '../data/models/cart_item_model.dart';
import '../data/models/order_model.dart';
import '../data/models/voucher_model.dart';
import '../data/services/local/database_helper.dart';
import '../data/services/remote/firestore_service.dart';

/// ViewModel quản lý Giỏ hàng, Mã giảm giá, Phương thức thanh toán & Đặt hàng
class CartViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FirestoreService _firestoreService = FirestoreService.instance;

  List<CartItemModel> _items = [];
  List<VoucherModel> _vouchers = [];
  VoucherModel? _selectedVoucher;

  String _selectedPaymentMethod = 'Tiền mặt (COD)'; // 'Tiền mặt (COD)' hoặc 'VNPAY Sandbox'

  bool _isLoading = false;
  String? _message;

  List<CartItemModel> get items => _items;
  List<VoucherModel> get vouchers => _vouchers;
  VoucherModel? get selectedVoucher => _selectedVoucher;
  String get selectedPaymentMethod => _selectedPaymentMethod;
  bool get isLoading => _isLoading;
  String? get message => _message;

  CartViewModel() {
    loadCart();
    loadVouchers();
  }

  /// Chọn phương thức thanh toán
  void setPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  /// Tải danh sách món trong giỏ hàng từ SQLite
  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _dbHelper.getCartItems();
    } catch (_) {
      _items = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Tải danh sách Vouchers
  void loadVouchers() {
    _vouchers = _firestoreService.getLocalVouchers();
    notifyListeners();
  }

  /// Cập nhật số lượng của một món trong giỏ
  Future<void> updateQuantity(CartItemModel item, int newQuantity) async {
    if (item.id == null) return;

    if (newQuantity <= 0) {
      await removeItem(item.id!);
    } else {
      await _dbHelper.updateCartItemQuantity(item.id!, newQuantity);
      await loadCart();
    }
  }

  /// Xóa một món khỏi giỏ hàng
  Future<void> removeItem(int id) async {
    await _dbHelper.deleteCartItem(id);
    await loadCart();
  }

  /// Xóa toàn bộ giỏ hàng
  Future<void> clearCart() async {
    await _dbHelper.clearCart();
    _selectedVoucher = null;
    await loadCart();
  }

  /// Áp dụng mã giảm giá
  bool applyVoucher(VoucherModel voucher) {
    if (subtotal < voucher.minOrderValue) {
      _message = 'Đơn hàng tối thiểu phải từ ${voucher.minOrderValue.toInt()}đ để áp dụng voucher này.';
      notifyListeners();
      return false;
    }
    _selectedVoucher = voucher;
    _message = 'Đã áp dụng voucher: ${voucher.code}';
    notifyListeners();
    return true;
  }

  /// Hủy áp dụng voucher
  void removeVoucher() {
    _selectedVoucher = null;
    _message = 'Đã hủy mã giảm giá';
    notifyListeners();
  }

  /// Tổng tiền tạm tính trước giảm giá
  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  /// Số tiền được giảm giá
  double get discountAmount {
    if (_selectedVoucher == null) return 0.0;
    return _selectedVoucher!.calculateDiscount(subtotal);
  }

  /// Tổng số tiền cần thanh toán
  double get totalAmount {
    final finalAmount = subtotal - discountAmount;
    return finalAmount > 0 ? finalAmount : 0;
  }

  /// Tổng số lượng món trong giỏ
  int get totalItemCount {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  /// Kiểm tra số lượng món còn lại khi khởi động app (Startup Cart Check)
  Future<int> checkCartOnStartup() async {
    return await _dbHelper.getCartItemsCount();
  }

  /// Xác nhận Đặt hàng (Lưu SQLite cục bộ + Đẩy lên Firestore Realtime)
  Future<bool> checkout(String userId, {String? customerName, String? paymentMethod}) async {
    if (_items.isEmpty) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      final actualPaymentMethod = paymentMethod ?? _selectedPaymentMethod;

      final order = OrderModel(
        orderId: orderId,
        userId: userId.isEmpty ? 'guest' : userId,
        items: List.from(_items),
        subtotal: subtotal,
        discount: discountAmount,
        voucherCode: _selectedVoucher?.code,
        totalAmount: totalAmount,
        orderDate: DateTime.now().toIso8601String(),
        status: 'Mới nhận',
        paymentMethod: actualPaymentMethod,
      );

      // 1. Lưu vào bảng order_history trong SQLite
      await _dbHelper.insertOrder(order);

      // 2. Đẩy lên Cloud Firestore 'orders' để Web Admin nhận Realtime
      await _firestoreService.createOrder(order, customerName: customerName);

      // 3. Làm sạch giỏ hàng
      await _dbHelper.clearCart();
      _items.clear();
      _selectedVoucher = null;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
