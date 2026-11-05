import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../../core/constants/app_constants.dart';
import '../../models/cart_item_model.dart';
import '../../models/product_model.dart';
import '../../models/order_model.dart';

/// Lớp DatabaseHelper quản lý cơ sở dữ liệu SQLite cục bộ của ứng dụng LOWLAND Coffee
/// Hỗ trợ cả SQLite trên thiết bị thật/máy ảo và In-Memory Web Storage khi test trên Chrome F12
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // In-Memory Storage tương thích khi chạy trên Flutter Web (Chrome F12)
  final List<CartItemModel> _webCartItems = [];
  final List<ProductModel> _webFavorites = [];
  final List<OrderModel> _webOrders = [];
  int _webIdCounter = 1;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('sqflite database is not used on Web platform.');
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
    if (kIsWeb) {
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
        return current.id ?? 1;
      } else {
        final newItem = item.copyWith(id: _webIdCounter++);
        _webCartItems.insert(0, newItem);
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
    if (kIsWeb) {
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
    if (kIsWeb) {
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
    if (kIsWeb) {
      _webCartItems.removeWhere((i) => i.id == id);
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
    if (kIsWeb) {
      _webCartItems.clear();
      return 1;
    }

    final db = await database;
    return await db.delete(AppConstants.tableCart);
  }

  /// Lấy số lượng món chưa thanh toán trong giỏ hàng (Startup Cart Check)
  Future<int> getCartItemsCount() async {
    if (kIsWeb) {
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
    if (kIsWeb) {
      if (!_webFavorites.any((p) => p.id == product.id)) {
        _webFavorites.insert(0, product);
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
    if (kIsWeb) {
      _webFavorites.removeWhere((p) => p.id == productId);
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
    if (kIsWeb) {
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
    if (kIsWeb) {
      return List.from(_webFavorites);
    }

    final db = await database;
    final result = await db.query(
      AppConstants.tableFavorites,
      orderBy: 'createdAt DESC',
    );
    return result.map((row) {
      return ProductModel(
        id: row['productId'] as String,
        name: row['name'] as String,
        category: row['category'] as String,
        imageUrl: row['imageUrl'] as String? ?? '',
        price: (row['price'] as num).toDouble(),
        description: row['description'] as String? ?? '',
      );
    }).toList();
  }

  // ==========================================
  // THAO TÁC VỚI BẢNG ORDER_HISTORY (Lịch sử đơn)
  // ==========================================

  /// Thêm đơn hàng mới vào lịch sử đơn hàng
  Future<int> insertOrder(OrderModel order) async {
    if (kIsWeb) {
      _webOrders.insert(0, order);
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
    if (kIsWeb) {
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

  /// Đóng kết nối CSDL khi cần
  Future<void> close() async {
    if (kIsWeb) return;
    final db = await database;
    await db.close();
  }
}
