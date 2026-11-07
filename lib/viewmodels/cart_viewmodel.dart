import 'package:flutter/material.dart';
import '../data/models/cart_item_model.dart';
import '../data/models/order_model.dart';
import '../data/models/voucher_model.dart';
import '../data/services/local/database_helper.dart';
import '../data/services/remote/firestore_service.dart';

/// ViewModel quản lý Giỏ hàng, Mã giảm giá, Hình thức nhận món, Phương thức thanh toán & Đặt hàng
class CartViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FirestoreService _firestoreService = FirestoreService.instance;

  List<CartItemModel> _items = [];
  List<VoucherModel> _vouchers = [];
  List<OrderModel> _userOrders = [];
  VoucherModel? _selectedVoucher;

  String _selectedPaymentMethod = 'Tiền mặt (COD)'; // 'Tiền mặt (COD)' hoặc 'VNPAY Sandbox'
  String _deliveryType = 'Giao tận nơi'; // 'Giao tận nơi' hoặc 'Dùng tại quán / Tự lấy'

  bool _isLoading = false;
  String? _message;

  List<CartItemModel> get items => _items;
  List<VoucherModel> get vouchers => _vouchers;
  VoucherModel? get selectedVoucher => _selectedVoucher;
  String get selectedPaymentMethod => _selectedPaymentMethod;
  String get deliveryType => _deliveryType;
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

  /// Chọn hình thức nhận món (Giao tận nơi / Dùng tại quán)
  void setDeliveryType(String type) {
    _deliveryType = type;
    notifyListeners();
  }

  /// Tải danh sách món trong giỏ hàng từ SQLite / LocalStorage
  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _dbHelper.getCartItems();
      await _refreshUserOrdersSnapshot();
      if (_selectedVoucher != null && !isVoucherApplicable(_selectedVoucher!)) {
        _selectedVoucher = null;
      }
    } catch (_) {
      _items = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Đồng bộ nhanh danh sách đơn hàng đã đặt của người dùng để kiểm tra điều kiện "Đơn đầu tiên" & "Dùng 1 lần"
  Future<void> _refreshUserOrdersSnapshot() async {
    try {
      final localOrders = await _dbHelper.getOrderHistory();
      final Map<String, OrderModel> merged = {
        for (final o in localOrders) o.orderId: o,
      };
      try {
        final remoteOrders = await _firestoreService.getOrdersFromFirestore();
        for (final ro in remoteOrders) {
          merged[ro.orderId] = ro;
        }
      } catch (_) {}
      _userOrders = merged.values.toList();
    } catch (_) {}
  }

  /// Kiểm tra xem khách hàng đã từng có đơn hàng hợp lệ (không bị hủy) trước đó hay chưa
  bool get hasPreviousValidOrders {
    return _userOrders.any((o) => o.status != 'Đã hủy');
  }

  /// Kiểm tra xem khách hàng đã từng dùng mã voucher này ở các đơn hàng trước chưa
  bool hasUsedVoucherBefore(String code) {
    final target = code.trim().toUpperCase();
    return _userOrders.any(
      (o) =>
          o.status != 'Đã hủy' &&
          (o.voucherCode ?? '').trim().toUpperCase() == target,
    );
  }

  /// Kiểm tra giỏ hàng có chứa món thuộc Danh mục yêu cầu của Voucher hay không
  bool matchesCategoryCondition(VoucherModel voucher) {
    final cat = voucher.applicableCategory.trim();
    if (cat.isEmpty || cat.toLowerCase() == 'all' || cat == 'Tất cả') {
      return true;
    }
    if (_items.isEmpty) return false;

    bool hasCoffee = false;
    bool hasTea = false;
    bool hasCake = false;

    for (final item in _items) {
      final pid = item.productId.toLowerCase();
      final name = item.name.toLowerCase();
      if (pid.startsWith('cf_') || name.contains('cà phê') || name.contains('phin') || name.contains('bạc xỉu') || name.contains('espresso')) {
        hasCoffee = true;
      }
      if (pid.startsWith('tra_') || name.contains('trà')) {
        hasTea = true;
      }
      if (pid.startsWith('banh_') || name.contains('bánh') || name.contains('croissant') || name.contains('mousse')) {
        hasCake = true;
      }
    }

    if (cat == 'Cà phê') return hasCoffee;
    if (cat == 'Trà') return hasTea;
    if (cat == 'Bánh') return hasCake;
    if (cat == 'Trà & Bánh') return hasTea || hasCake;
    return true;
  }

  /// Kiểm tra tổng thể xem một Voucher có đủ mọi điều kiện để bấm Áp dụng ngay lúc này không
  bool isVoucherApplicable(VoucherModel voucher) {
    if (voucher.isExpired || voucher.isOutOfStock) return false;
    if (voucher.onlyFirstOrder && hasPreviousValidOrders) return false;
    if (voucher.oncePerUser && hasUsedVoucherBefore(voucher.code)) return false;
    if (!matchesCategoryCondition(voucher)) return false;
    if (subtotal < voucher.minOrderValue) return false;
    return true;
  }

  /// Kiểm tra xem Voucher có bị khóa vĩnh viễn đối với khách hàng hiện tại không (Hết hạn / Hết lượt / Qua đơn đầu / Đã dùng)
  bool isVoucherLockedForUser(VoucherModel voucher) {
    if (voucher.isExpired || voucher.isOutOfStock) return true;
    if (voucher.onlyFirstOrder && hasPreviousValidOrders) return true;
    if (voucher.oncePerUser && hasUsedVoucherBefore(voucher.code)) return true;
    return false;
  }

  /// Tải danh sách Vouchers (Kết hợp Local + Đồng bộ Realtime từ Cloud Firestore)
  Future<void> loadVouchers() async {
    await _refreshUserOrdersSnapshot();
    _vouchers = _firestoreService.getLocalVouchers();
    _sortAndValidateVouchers();
    notifyListeners();

    try {
      final remoteVouchers = await _firestoreService.getVouchersFromFirestore();
      if (remoteVouchers.isNotEmpty) {
        _vouchers = remoteVouchers;
        _sortAndValidateVouchers();
        notifyListeners();
      }
    } catch (_) {}
  }

  void _sortAndValidateVouchers() {
    // Đưa các voucher dùng được lên đầu, voucher bị khóa / hết hạn xuống cuối
    _vouchers.sort((a, b) {
      final lockA = isVoucherLockedForUser(a);
      final lockB = isVoucherLockedForUser(b);
      if (lockA != lockB) {
        return lockA ? 1 : -1;
      }
      return a.expiryDate.compareTo(b.expiryDate);
    });

    // Nếu voucher đang chọn không còn thỏa điều kiện thì tự động gỡ bỏ
    if (_selectedVoucher != null) {
      final matchedIdx = _vouchers.indexWhere(
        (v) => v.code.toUpperCase() == _selectedVoucher!.code.toUpperCase(),
      );
      if (matchedIdx == -1 || !isVoucherApplicable(_vouchers[matchedIdx])) {
        _selectedVoucher = null;
      } else {
        _selectedVoucher = _vouchers[matchedIdx];
      }
    }
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

  /// Đặt lại các món từ một đơn hàng cũ vào giỏ hàng
  Future<void> reorderItems(List<CartItemModel> oldItems) async {
    for (final item in oldItems) {
      await _dbHelper.insertOrUpdateCartItem(
        item.copyWith(createdAt: DateTime.now().toIso8601String()),
      );
    }
    await loadCart();
  }

  /// Áp dụng mã giảm giá từ danh sách
  bool applyVoucher(VoucherModel voucher) {
    if (voucher.isExpired) {
      _message = 'Mã giảm giá ${voucher.code} đã kết thúc thời hạn sử dụng.';
      notifyListeners();
      return false;
    }
    if (voucher.isOutOfStock) {
      _message = 'Mã giảm giá ${voucher.code} đã hết lượt sử dụng.';
      notifyListeners();
      return false;
    }
    if (voucher.onlyFirstOrder && hasPreviousValidOrders) {
      _message = 'Mã ${voucher.code} chỉ áp dụng cho Đơn hàng đầu tiên (bạn đã có đơn hàng trước đó).';
      notifyListeners();
      return false;
    }
    if (voucher.oncePerUser && hasUsedVoucherBefore(voucher.code)) {
      _message = 'Bạn đã sử dụng mã ${voucher.code} ở đơn hàng trước (mỗi khách chỉ dùng 1 lần).';
      notifyListeners();
      return false;
    }
    if (!matchesCategoryCondition(voucher)) {
      _message = 'Giỏ hàng cần có ít nhất 1 món thuộc nhóm "${voucher.applicableCategory}" để dùng mã ${voucher.code}.';
      notifyListeners();
      return false;
    }
    if (subtotal < voucher.minOrderValue) {
      _message = 'Đơn hàng tối thiểu phải từ ${voucher.minOrderValue.toInt()}đ để áp dụng mã ${voucher.code}.';
      notifyListeners();
      return false;
    }
    _selectedVoucher = voucher;
    _message = 'Đã áp dụng voucher: ${voucher.code}';
    notifyListeners();
    return true;
  }

  /// Nhập mã giảm giá thủ công bằng chuỗi Code & Validate
  String? applyVoucherByCode(String rawCode) {
    final cleanCode = rawCode.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      return 'Vui lòng nhập mã ưu đãi!';
    }

    final idx = _vouchers.indexWhere((v) => v.code.toUpperCase() == cleanCode);
    if (idx == -1) {
      return 'Mã ưu đãi "$cleanCode" không tồn tại hoặc không hợp lệ.';
    }

    final voucher = _vouchers[idx];
    if (voucher.isExpired) {
      return 'Mã ưu đãi "$cleanCode" đã kết thúc thời gian sử dụng.';
    }
    if (voucher.isOutOfStock) {
      return 'Mã ưu đãi "$cleanCode" đã hết lượt sử dụng.';
    }
    if (voucher.onlyFirstOrder && hasPreviousValidOrders) {
      return 'Mã "$cleanCode" chỉ dành cho Đơn hàng đầu tiên của khách mới!';
    }
    if (voucher.oncePerUser && hasUsedVoucherBefore(voucher.code)) {
      return 'Bạn đã sử dụng mã "$cleanCode" rồi (giới hạn 1 lần/khách hàng).';
    }
    if (!matchesCategoryCondition(voucher)) {
      return 'Giỏ hàng cần có món thuộc danh mục "${voucher.applicableCategory}" để áp dụng mã "$cleanCode".';
    }

    if (subtotal < voucher.minOrderValue) {
      return 'Đơn hàng hiện tại chưa đạt tối thiểu ${voucher.minOrderValue.toInt()}đ để dùng mã "$cleanCode".';
    }

    _selectedVoucher = voucher;
    notifyListeners();
    return null; // null = Thành công
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
    if (_selectedVoucher == null || _selectedVoucher!.isExpired) return 0.0;
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
  Future<bool> checkout(
    String userId, {
    String? customerName,
    String? paymentMethod,
    String? receiverPhone,
    String? deliveryAddress,
    String? orderNote,
  }) async {
    if (_items.isEmpty) return false;
    if (_selectedVoucher != null && _selectedVoucher!.isExpired) {
      _selectedVoucher = null;
    }

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
        deliveryType: _deliveryType,
        receiverPhone: (receiverPhone ?? '').trim(),
        deliveryAddress: (deliveryAddress ?? '').trim(),
        orderNote: (orderNote ?? '').trim(),
      );

      // 1. Lưu vào bảng order_history trong SQLite / LocalStorage
      await _dbHelper.insertOrder(order);

      // 2. Đẩy lên Cloud Firestore 'orders' để Web Admin nhận Realtime
      await _firestoreService.createOrder(order, customerName: customerName);

      // 3. Làm sạch giỏ hàng & cập nhật lại lịch sử đơn để khóa ngay các mã "Đơn đầu tiên" / "1 lần"
      await _dbHelper.clearCart();
      _items.clear();
      _selectedVoucher = null;
      await _refreshUserOrdersSnapshot();
      _sortAndValidateVouchers();

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
