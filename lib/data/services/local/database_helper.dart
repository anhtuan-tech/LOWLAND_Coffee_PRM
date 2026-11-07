import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/sqlite_file_sync.dart';
import '../../models/cart_item_model.dart';
import '../../models/product_model.dart';
import '../../models/order_model.dart';

/// Lớp DatabaseHelper quản lý cơ sở dữ liệu SQLite cục bộ của ứng dụng LOWLAND Coffee
/// Hỗ trợ cả SQLite trên thiết bị thật/máy ảo Android/iOS và Persistent Local Storage khi chạy trên Web/Windows Desktop
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  static const String _keyLocalCart = 'sqlite_persistent_cart_v1';
  static const String _keyLocalFavorites = 'sqlite_persistent_favorites_v1';
  static const String _keyLocalOrders = 'sqlite_persistent_orders_v1';

  /// Kiểm tra nền tảng Web hoặc Windows Desktop (nơi sqflite mobile không chạy trực tiếp)
  bool get _useMemoryFallback =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;

  // Bộ nhớ cục bộ được đồng bộ bền vững xuống ổ cứng / LocalStorage (không bị mất khi tắt app hay F5)
  final List<CartItemModel> _webCartItems = [];
  final List<ProductModel> _webFavorites = [];
  final List<OrderModel> _webOrders = [];
  int _webIdCounter = 1;
  bool _isWebStorageLoaded = false;

  DatabaseHelper._init();

  /// Nạp dữ liệu đã lưu từ ổ cứng / LocalStorage lên khi khởi động lại App
  Future<void> _ensureLocalPersistenceLoaded() async {
    if (_isWebStorageLoaded) return;
    _isWebStorageLoaded = true;

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Khôi phục Giỏ hàng (cart_items)
      final cartRaw = prefs.getString(_keyLocalCart);
      if (cartRaw != null && cartRaw.isNotEmpty) {
        final decoded = jsonDecode(cartRaw) as List<dynamic>;
        _webCartItems.clear();
        for (final item in decoded) {
          final model = CartItemModel.fromMap(Map<String, dynamic>.from(item as Map));
          _webCartItems.add(model);
          if (model.id != null && model.id! >= _webIdCounter) {
            _webIdCounter = model.id! + 1;
          }
        }
      }

      // 2. Khôi phục Yêu thích (favorites)
      final favRaw = prefs.getString(_keyLocalFavorites);
      if (favRaw != null && favRaw.isNotEmpty) {
        final decoded = jsonDecode(favRaw) as List<dynamic>;
        _webFavorites.clear();
        for (final item in decoded) {
          _webFavorites.add(ProductModel.fromMap(Map<String, dynamic>.from(item as Map)));
        }
      }

      // 3. Khôi phục Lịch sử đơn hàng (order_history)
      final ordersRaw = prefs.getString(_keyLocalOrders);
      if (ordersRaw != null && ordersRaw.isNotEmpty) {
        final decoded = jsonDecode(ordersRaw) as List<dynamic>;
        _webOrders.clear();
        for (final item in decoded) {
          _webOrders.add(OrderModel.fromMap(Map<String, dynamic>.from(item as Map)));
        }
      }

      // Đồng bộ ngay trạng thái hiện tại sang file D:\FA26\prm_project\lowland_coffee.db
      await syncToPhysicalSqliteDb();
    } catch (_) {}
  }

  /// Đồng bộ trực tiếp dữ liệu từ App xuống file vật lý D:\FA26\prm_project\lowland_coffee.db (để xem realtime trên DB Browser for SQLite)
  Future<void> syncToPhysicalSqliteDb() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode({
        'cart_items': _webCartItems.map((e) => e.toMap()).toList(),
        'favorites': _webFavorites.map((e) => {
          'productId': e.id,
          'name': e.name,
          'category': e.category,
          'imageUrl': e.imageUrl,
          'price': e.price,
          'description': e.description,
          'createdAt': DateTime.now().toIso8601String(),
        }).toList(),
        'order_history': _webOrders.map((e) => e.toMap()).toList(),
        'shared_preferences': {
          'is_logged_in': (prefs.getBool(AppConstants.keyUserLoggedIn) ?? false).toString(),
          'user_uid': prefs.getString(AppConstants.keyUserUid) ?? '',
          'user_email': prefs.getString(AppConstants.keyUserEmail) ?? '',
          'user_name': prefs.getString(AppConstants.keyUserName) ?? '',
          'user_phone_number': prefs.getString('user_phone_number') ?? '',
        },
      });
      await syncAppStateToSqliteFile(payload);
    } catch (_) {}
  }

  /// Lưu bền vững Giỏ hàng xuống đĩa / LocalStorage & Đồng bộ file .db
  Future<void> _persistCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(_webCartItems.map((e) => e.toMap()).toList());
      await prefs.setString(_keyLocalCart, data);
      await syncToPhysicalSqliteDb();
    } catch (_) {}
  }

  /// Lưu bền vững Yêu thích xuống đĩa / LocalStorage & Đồng bộ file .db
  Future<void> _persistFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(_webFavorites.map((e) => e.toMap()).toList());
      await prefs.setString(_keyLocalFavorites, data);
      await syncToPhysicalSqliteDb();
    } catch (_) {}
  }

  /// Lưu bền vững Lịch sử đơn hàng xuống đĩa / LocalStorage & Đồng bộ file .db
  Future<void> _persistOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(_webOrders.map((e) => e.toFullMap()).toList());
      await prefs.setString(_keyLocalOrders, data);
      await syncToPhysicalSqliteDb();
    } catch (_) {}
  }

  Future<Database> get database async {
    if (_useMemoryFallback) {
      throw UnsupportedError('sqflite database is only used on Android/iOS.');
    }
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Bảng Giỏ hàng (cart_items)
    await db.execute('''
      CREATE TABLE ${AppConstants.tableCart} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId TEXT NOT NULL,
        name TEXT NOT NULL,
        imageUrl TEXT,
        basePrice REAL NOT NULL,
        selectedSize TEXT NOT NULL,
        selectedSugar INTEGER NOT NULL,
        selectedIce INTEGER NOT NULL,
        selectedToppings TEXT,
        itemPrice REAL NOT NULL,
        quantity INTEGER NOT NULL,
        totalPrice REAL NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // 2. Bảng Yêu thích (favorites)
    await db.execute('''
      CREATE TABLE ${AppConstants.tableFavorites} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        imageUrl TEXT,
        price REAL NOT NULL,
        description TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // 3. Bảng Lịch sử đơn hàng (order_history)
    await db.execute('''
      CREATE TABLE ${AppConstants.tableOrderHistory} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId TEXT UNIQUE NOT NULL,
        userId TEXT NOT NULL,
        itemsJson TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount REAL NOT NULL,
        voucherCode TEXT,
        totalAmount REAL NOT NULL,
        orderDate TEXT NOT NULL,
        status TEXT NOT NULL,
        paymentMethod TEXT
      )
    ''');
  }

  // ==========================================
  // THAO TÁC VỚI BẢNG CART_ITEMS (CRUD Giỏ Hàng)
  // ==========================================

  /// Thêm hoặc gộp sản phẩm vào giỏ hàng
  Future<int> insertOrUpdateCartItem(CartItemModel item) async {
    if (_useMemoryFallback) {
      await _ensureLocalPersistenceLoaded();
      final index = _webCartItems.indexWhere(
        (i) =>
            i.productId == item.productId &&
            i.selectedSize == item.selectedSize &&
            i.selectedSugar == item.selectedSugar &&
            i.selectedIce == item.selectedIce &&
            i.selectedToppings.join(',') == item.selectedToppings.join(','),
      );

      if (index != -1) {
        final current = _webCartItems[index];
        final newQty = current.quantity + item.quantity;
        _webCartItems[index] = current.copyWith(
          quantity: newQty,
          totalPrice: current.itemPrice * newQty,
        );
        await _persistCart();
        return current.id ?? 1;
      } else {
        final newItem = item.copyWith(id: _webIdCounter++);
        _webCartItems.insert(0, newItem);
        await _persistCart();
        return newItem.id!;
      }
    }

    final db = await database;
    final existing = await db.query(
      AppConstants.tableCart,
      where: 'productId = ? AND selectedSize = ? AND selectedSugar = ? AND selectedIce = ? AND selectedToppings = ?',
      whereArgs: [
        item.productId,
        item.selectedSize,
        item.selectedSugar,
        item.selectedIce,
        item.toMap()['selectedToppings'],
      ],
    );

    if (existing.isNotEmpty) {
      final currentItem = CartItemModel.fromMap(existing.first);
      final newQuantity = currentItem.quantity + item.quantity;
      final newTotalPrice = currentItem.itemPrice * newQuantity;

      return await db.update(
        AppConstants.tableCart,
        {
          'quantity': newQuantity,
          'totalPrice': newTotalPrice,
        },
        where: 'id = ?',
        whereArgs: [currentItem.id],
      );
    } else {
      return await db.insert(
        AppConstants.tableCart,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Lấy toàn bộ danh sách món trong giỏ hàng
  Future<List<CartItemModel>> getCartItems() async {
    if (_useMemoryFallback) {
      await _ensureLocalPersistenceLoaded();
      return List.from(_webCartItems);
    }

    final db = await database;
    final result = await db.query(
      AppConstants.tableCart,
      orderBy: 'createdAt DESC',
    );
    return result.map((json) => CartItemModel.fromMap(json)).toList();
  }

  /// Cập nhật số lượng của một món trong giỏ
  Future<int> updateCartItemQuantity(int id, int quantity) async {
    if (_useMemoryFallback) {
      await _ensureLocalPersistenceLoaded();
      if (quantity <= 0) {
        return await deleteCartItem(id);
      }
      final index = _webCartItems.indexWhere((i) => i.id == id);
      if (index != -1) {
        final current = _webCartItems[index];
        _webCartItems[index] = current.copyWith(
          quantity: quantity,
          totalPrice: current.itemPrice * quantity,
        );
        await _persistCart();
        return 1;
      }
      return 0;
    }

    final db = await database;
    if (quantity <= 0) {
      return await deleteCartItem(id);
    }

    final itemMaps = await db.query(
      AppConstants.tableCart,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (itemMaps.isNotEmpty) {
      final item = CartItemModel.fromMap(itemMaps.first);
      final newTotal = item.itemPrice * quantity;
      return await db.update(
        AppConstants.tableCart,
        {
          'quantity': quantity,
          'totalPrice': newTotal,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    return 0;
  }

  /// Xóa một món khỏi giỏ hàng
  Future<int> deleteCartItem(int id) async {
    if (_useMemoryFallback) {
      await _ensureLocalPersistenceLoaded();
      _webCartItems.removeWhere((i) => i.id == id);
      await _persistCart();
      return 1;
    }

    final db = await database;
    return await db.delete(
      AppConstants.tableCart,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Xóa toàn bộ giỏ hàng
  Future<int> clearCart() async {
    if (_useMemoryFallback) {
      await _ensureLocalPersistenceLoaded();
      _webCartItems.clear();
      await _persistCart();
      return 1;
    }

    final db = await database;
    return await db.delete(AppConstants.tableCart);
  }

  /// Lấy số lượng món chưa thanh toán trong giỏ hàng (Startup Cart Check)
  Future<int> getCartItemsCount() async {
    if (_useMemoryFallback) {
      await _ensureLocalPersistenceLoaded();
      return _webCartItems.length;
    }

    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${AppConstants.tableCart}'),
    );
    return count ?? 0;
  }

  // ==========================================
  // THAO TÁC VỚI BẢNG FAVORITES (Yêu thích)
  // ==========================================

  /// Thêm món vào danh sách yêu thích
  Future<int> addFavorite(ProductModel product) async {
    if (_useMemoryFallback) {
      await _ensureLocalPersistenceLoaded();
      if (!_webFavorites.any((p) => p.id == product.id)) {
        _webFavorites.insert(0, product);
        await _persistFavorites();
      }
      return 1;
    }

    final db = await database;
    return await db.insert(
      AppConstants.tableFavorites,
      {
        'productId': product.id,
        'name': product.name,
        'category': product.category,
        'imageUrl': product.imageUrl,
        'price': product.price,
        'description': product.description,
        'createdAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Xóa món khỏi danh sách yêu thích
  Future<int> removeFavorite(String productId) async {
    if (_useMemoryFallback) {
      await _ensureLocalPersistenceLoaded();
      _webFavorites.removeWhere((p) => p.id == productId);
      await _persistFavorites();
      return 1;
    }

    final db = await database;
    return await db.delete(
      AppConstants.tableFavorites,
      where: 'productId = ?',
      whereArgs: [productId],
    );
  }

  /// Kiểm tra món đã được yêu thích chưa
  Future<bool> isFavorite(String productId) async {
    if (_useMemoryFallback) {
      await _ensureLocalPersistenceLoaded();
      return _webFavorites.any((p) => p.id == productId);
    }

    final db = await database;
    final result = await db.query(
      AppConstants.tableFavorites,
      where: 'productId = ?',
      whereArgs: [productId],
    );
    return result.isNotEmpty;
  }

  /// Lấy toàn bộ danh sách món yêu thích
  Future<List<ProductModel>> getFavorites() async {
    if (_useMemoryFallback) {
      await _ensureLocalPersistenceLoaded();
      return List.from(_webFavorites);
    }

    final db = await database;
    final result = await db.query(
      AppConstants.tableFavorites,
      orderBy: 'createdAt DESC',
    );
    return result.map((row) {
      final category = row['category'] as String? ?? 'Cà phê';
      return ProductModel(
        id: row['productId'] as String,
        name: row['name'] as String,
        category: category,
        imageUrl: row['imageUrl'] as String? ?? '',
        price: (row['price'] as num).toDouble(),
        description: row['description'] as String? ?? '',
        availableSizes: category == 'Bánh' ? const ['M'] : const ['S', 'M', 'L'],
        availableToppings: category == 'Bánh'
            ? const []
            : const [
                'Thạch cà phê (+6.000đ)',
                'Trân châu trắng (+6.000đ)',
                'Kem Cheese (+10.000đ)',
                'Shot Espresso (+10.000đ)',
              ],
      );
    }).toList();
  }

  // ==========================================
  // THAO TÁC VỚI BẢNG ORDER_HISTORY (Lịch sử đơn)
  // ==========================================

  /// Thêm hoặc cập nhật đơn hàng vào lịch sử đơn hàng
  Future<int> insertOrder(OrderModel order) async {
    if (_useMemoryFallback) {
      await _ensureLocalPersistenceLoaded();
      final existingIdx = _webOrders.indexWhere((o) => o.orderId == order.orderId);
      if (existingIdx != -1) {
        _webOrders[existingIdx] = order;
      } else {
        _webOrders.insert(0, order);
      }
      await _persistOrders();
      return 1;
    }

    final db = await database;
    return await db.insert(
      AppConstants.tableOrderHistory,
      order.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Lấy danh sách lịch sử đơn hàng của người dùng
  Future<List<OrderModel>> getOrderHistory({String? userId}) async {
    if (_useMemoryFallback) {
      await _ensureLocalPersistenceLoaded();
      if (userId != null && userId.isNotEmpty) {
        return _webOrders.where((o) => o.userId == userId).toList();
      }
      return List.from(_webOrders);
    }

    final db = await database;
    List<Map<String, dynamic>> result;
    if (userId != null && userId.isNotEmpty) {
      result = await db.query(
        AppConstants.tableOrderHistory,
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'orderDate DESC',
      );
    } else {
      result = await db.query(
        AppConstants.tableOrderHistory,
        orderBy: 'orderDate DESC',
      );
    }

    return result.map((json) => OrderModel.fromMap(json)).toList();
  }

  /// Cập nhật trạng thái đơn hàng (ví dụ: Khách hủy đơn khi còn ở trạng thái 'Mới nhận')
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    if (_useMemoryFallback) {
      await _ensureLocalPersistenceLoaded();
      final idx = _webOrders.indexWhere((o) => o.orderId == orderId);
      if (idx != -1) {
        _webOrders[idx] = _webOrders[idx].copyWith(status: newStatus);
        await _persistOrders();
      }
      return;
    }

    final db = await database;
    await db.update(
      AppConstants.tableOrderHistory,
      {'status': newStatus},
      where: 'orderId = ?',
      whereArgs: [orderId],
    );
  }

  /// Đóng kết nối CSDL khi cần
  Future<void> close() async {
    if (_useMemoryFallback) return;
    final db = await database;
    await db.close();
  }
}
