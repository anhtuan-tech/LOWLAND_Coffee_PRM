import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../models/store_model.dart';
import '../../models/voucher_model.dart';

/// Dịch vụ kết nối và thao tác dữ liệu với Cloud Firestore
class FirestoreService {
  static final FirestoreService instance = FirestoreService._init();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirestoreService._init();

  /// Realtime Stream danh sách sản phẩm từ Cloud Firestore
  Stream<List<ProductModel>> getProductsStream() {
    return _firestore
        .collection(AppConstants.collectionProducts)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Khởi tạo dữ liệu mẫu thực đơn LOWLAND Coffee lên Cloud Firestore nếu database đang rỗng
  Future<void> seedInitialProductsIfEmpty() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.collectionProducts)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return; // Đã có dữ liệu, không cần chèn thêm
      }

      final initialProducts = [
        // --- CÀ PHÊ ---
        ProductModel(
          id: 'cf_phin_sua',
          name: 'Phin Sữa Đá Đậm Đà',
          category: AppConstants.categoryCoffee,
          price: 35000,
          imageUrl: 'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?auto=format&fit=crop&w=600&q=80',
          description: 'Hạt cà phê Robusta hảo hạng hòa quyện cùng sữa đặc béo ngậy, giữ trọn hương vị truyền thống tinh hoa.',
          availableSizes: ['S', 'M', 'L'],
          availableToppings: ['Thạch cà phê (+6.000đ)', 'Trân châu trắng (+6.000đ)', 'Kem Cheese (+10.000đ)', 'Shot Espresso (+10.000đ)'],
        ),
        ProductModel(
          id: 'cf_phin_den',
          name: 'Phin Đen Đá Nguyên Bản',
          category: AppConstants.categoryCoffee,
          price: 32000,
          imageUrl: 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=600&q=80',
          description: 'Cà phê phin truyền thống thơm lừng, vị đắng thanh dịu, hậu vị sâu lắng đánh thức mọi giác quan.',
          availableSizes: ['S', 'M', 'L'],
          availableToppings: ['Thạch cà phê (+6.000đ)', 'Shot Espresso (+10.000đ)'],
        ),
        ProductModel(
          id: 'cf_bac_xiu',
          name: 'Bạc Xỉu Sữa Tươi Kem Béo',
          category: AppConstants.categoryCoffee,
          price: 39000,
          imageUrl: 'https://images.unsplash.com/photo-1541167760496-1628856ab772?auto=format&fit=crop&w=600&q=80',
          description: 'Sự hòa quyện ngọt ngào giữa sữa béo, sữa tươi thanh trùng và chút phảng phất của cà phê phin nguyên chất.',
          availableSizes: ['S', 'M', 'L'],
          availableToppings: ['Thạch cà phê (+6.000đ)', 'Trân châu trắng (+6.000đ)', 'Kem Cheese (+10.000đ)'],
        ),
        ProductModel(
          id: 'cf_muoi',
          name: 'Cà Phê Muối Hoàng Gia',
          category: AppConstants.categoryCoffee,
          price: 45000,
          imageUrl: 'https://images.unsplash.com/photo-1572442388796-11668ba67e53?auto=format&fit=crop&w=600&q=80',
          description: 'Lớp kem muối sánh mịn mặn mặn béo ngậy kết hợp cùng cốt cà phê đậm vị, tạo nên hương vị bùng nổ đầy mê hoặc.',
          availableSizes: ['S', 'M', 'L'],
          availableToppings: ['Thạch cà phê (+6.000đ)', 'Trân châu trắng (+6.000đ)'],
        ),

        // --- TRÀ ---
        ProductModel(
          id: 'tra_sen_vang',
          name: 'Trà Sen Vàng Hạt Sen Thơm',
          category: AppConstants.categoryTea,
          price: 49000,
          imageUrl: 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&w=600&q=80',
          description: 'Trà Ô long thanh mát kết hợp cùng hạt sen bùi béo ngọt lành, lớp củ năng giòn sần sật và kem sữa thơm lừng.',
          availableSizes: ['S', 'M', 'L'],
          availableToppings: ['Hạt sen thêm (+10.000đ)', 'Củ năng (+8.000đ)', 'Kem Cheese (+10.000đ)'],
        ),
        ProductModel(
          id: 'tra_thach_dao',
          name: 'Trà Thạch Đào Mát Lạnh',
          category: AppConstants.categoryTea,
          price: 45000,
          imageUrl: 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?auto=format&fit=crop&w=600&q=80',
          description: 'Hương đào thơm mát hòa cùng vị trà đậm đà, những miếng đào giòn ngọt mọng nước cùng thạch đào mềm dẻo sảng khoái.',
          availableSizes: ['S', 'M', 'L'],
          availableToppings: ['Miếng đào thêm (+10.000đ)', 'Thạch đào (+6.000đ)', 'Trân châu trắng (+6.000đ)'],
        ),
        ProductModel(
          id: 'tra_thanh_dao',
          name: 'Trà Thanh Đào Sả Cam',
          category: AppConstants.categoryTea,
          price: 45000,
          imageUrl: 'https://images.unsplash.com/photo-1597481499750-3e6b22637e12?auto=format&fit=crop&w=600&q=80',
          description: 'Vị chua ngọt thanh khiết của cam vàng tươi, tinh dầu sả thơm ngát và đào mọng nước xua tan cái nóng tức thì.',
          availableSizes: ['S', 'M', 'L'],
          availableToppings: ['Miếng đào thêm (+10.000đ)', 'Trân châu trắng (+6.000đ)'],
        ),

        // --- BÁNH ---
        ProductModel(
          id: 'banh_pho_mai_cf',
          name: 'Bánh Mousse Cà Phê Phô Mai',
          category: AppConstants.categoryPastry,
          price: 39000,
          imageUrl: 'https://images.unsplash.com/photo-1533134242443-d4fd215305ad?auto=format&fit=crop&w=600&q=80',
          description: 'Chiếc bánh mềm mịn béo ngậy vị phô mai mascarpone quyện cùng hương cà phê nồng nàn.',
          availableSizes: ['M'],
          availableToppings: [],
        ),
        ProductModel(
          id: 'banh_chuoi_nuong',
          name: 'Bánh Chuối Nướng Thơm Bơ',
          category: AppConstants.categoryPastry,
          price: 32000,
          imageUrl: 'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?auto=format&fit=crop&w=600&q=80',
          description: 'Vị ngọt tự nhiên của chuối sứ chín muồi nướng vàng ươm, dậy mùi bơ sữa thơm nức lòng.',
          availableSizes: ['M'],
          availableToppings: [],
        ),
        ProductModel(
          id: 'banh_croissant',
          name: 'Bánh Croissant Ngàn Lớp',
          category: AppConstants.categoryPastry,
          price: 35000,
          imageUrl: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&w=600&q=80',
          description: 'Bánh sừng bò truyền thống vỏ giòn tan, ruột xốp mềm béo ngậy bơ Pháp hảo hạng.',
          availableSizes: ['M'],
          availableToppings: [],
        ),
      ];

      final batch = _firestore.batch();
      for (final product in initialProducts) {
        final docRef = _firestore
            .collection(AppConstants.collectionProducts)
            .doc(product.id);
        batch.set(docRef, product.toMap());
      }

      // Khởi tạo thêm danh sách Voucher khuyến mãi vào Firestore
      for (final voucher in getLocalVouchers()) {
        final vRef = _firestore
            .collection(AppConstants.collectionVouchers)
            .doc(voucher.code);
        batch.set(vRef, voucher.toMap());
      }

      // Khởi tạo thông tin chi nhánh Quán Cần Thơ vào Firestore
      final store = getFlagshipStore();
      final storeRef = _firestore
          .collection(AppConstants.collectionStores)
          .doc(store.id);
      batch.set(storeRef, store.toMap());

      await batch.commit();
    } catch (_) {
      // Bỏ qua lỗi nếu offline hoặc đã có dữ liệu
    }
  }

  /// Lấy danh sách Voucher khả dụng
  List<VoucherModel> getLocalVouchers() {
    final now = DateTime.now();
    return [
      VoucherModel(
        code: 'LOWLANDNEW',
        title: 'Chào bạn mới LOWLAND',
        description: 'Giảm 20% cho đơn hàng đầu tiên (Tối đa 40.000đ)',
        type: VoucherType.percentage,
        discountValue: 20,
        maxDiscount: 40000,
        minOrderValue: 40000,
        expiryDate: now.add(const Duration(days: 30)),
        onlyFirstOrder: true,
        oncePerUser: true,
        applicableCategory: 'all',
      ),
      VoucherModel(
        code: 'GIAM20K',
        title: 'Ưu đãi cà phê sáng',
        description: 'Giảm ngay 20.000đ cho đơn hàng từ 70.000đ',
        type: VoucherType.fixed,
        discountValue: 20000,
        minOrderValue: 70000,
        expiryDate: now.add(const Duration(days: 15)),
        onlyFirstOrder: false,
        oncePerUser: false,
        applicableCategory: 'all',
      ),
      VoucherModel(
        code: 'TRAXANH15',
        title: 'Tuần lễ Trà & Bánh',
        description: 'Giảm 15% cho mọi hóa đơn có trà hoặc bánh',
        type: VoucherType.percentage,
        discountValue: 15,
        maxDiscount: 30000,
        minOrderValue: 50000,
        expiryDate: now.add(const Duration(days: 7)),
        onlyFirstOrder: false,
        oncePerUser: false,
        applicableCategory: 'Trà & Bánh',
      ),
    ];
  }

  /// Lấy thông tin Quán Flagship (Đại Học FPT Cần Thơ)
  StoreModel getFlagshipStore() {
    return StoreModel(
      id: 'lowland_flagship',
      name: 'LOWLAND Coffee - Đại Học FPT Cần Thơ',
      address: '600 Nguyễn Văn Cừ nối dài, Phường An Bình, Quận Ninh Kiều, TP. Cần Thơ',
      hotline: '1900 1755',
      openingHours: '07:00 - 22:00 (Thứ 2 - Chủ Nhật)',
      wifiName: 'LOWLAND_Coffee_FPT_CanTho',
      wifiPassword: 'lowlandcoffee2026',
      latitude: 10.0132,
      longitude: 105.7316,
      imageUrl: 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=800&q=80',
    );
  }

  /// Đẩy đơn hàng mới lên Cloud Firestore để Web Admin nhận Realtime
  Future<void> createOrder(OrderModel order, {String? customerName}) async {
    try {
      final orderData = order.toFullMap();
      orderData['userName'] = customerName ?? (order.userId.isEmpty ? 'Khách vãng lai' : order.userId);
      orderData['createdAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('orders')
          .doc(order.orderId)
          .set(orderData);
    } catch (_) {
      // Dữ liệu vẫn được bảo toàn trong SQLite
    }
  }

  /// Cập nhật trạng thái đơn hàng trên Cloud Firestore (ví dụ: Khách hủy đơn)
  Future<void> updateOrderStatusInFirestore(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({'status': status});
    } catch (_) {}
  }

  /// Đồng bộ danh sách Voucher từ Cloud Firestore (kết hợp với bộ Voucher mặc định theo thời gian thực)
  Future<List<VoucherModel>> getVouchersFromFirestore() async {
    final defaultList = getLocalVouchers();
    final defaultCodes = {for (final v in defaultList) v.code.toUpperCase(): v};
    try {
      final snapshot = await _firestore.collection(AppConstants.collectionVouchers).get();
      if (snapshot.docs.isEmpty) return defaultList;

      final Map<String, VoucherModel> merged = {...defaultCodes};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final v = VoucherModel.fromMap(data, doc.id);
        final upperCode = v.code.toUpperCase();
        if (upperCode.isNotEmpty) {
          merged[upperCode] = v;
        }
      }
      return merged.values.toList();
    } catch (_) {
      return defaultList;
    }
  }

  /// Lấy danh sách đơn hàng từ Cloud Firestore để đồng bộ với Lịch sử đơn hàng cục bộ
  Future<List<OrderModel>> getOrdersFromFirestore({String? userId}) async {
    try {
      final snapshot = await _firestore.collection('orders').get();
      final orders = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data()))
          .where((o) => o.orderId.isNotEmpty)
          .toList();

      if (userId != null && userId.isNotEmpty) {
        return orders.where((o) => o.userId == userId).toList();
      }

      orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
      return orders;
    } catch (_) {
      return [];
    }
  }
}
