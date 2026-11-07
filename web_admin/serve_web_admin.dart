// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef _Sqlite3OpenNative = ffi.Int32 Function(
  ffi.Pointer<Utf8> filename,
  ffi.Pointer<ffi.Pointer<ffi.Void>> ppDb,
);
typedef _Sqlite3OpenDart = int Function(
  ffi.Pointer<Utf8> filename,
  ffi.Pointer<ffi.Pointer<ffi.Void>> ppDb,
);

typedef _Sqlite3ExecNative = ffi.Int32 Function(
  ffi.Pointer<ffi.Void> db,
  ffi.Pointer<Utf8> sql,
  ffi.Pointer<ffi.Void> callback,
  ffi.Pointer<ffi.Void> arg,
  ffi.Pointer<ffi.Pointer<Utf8>> errmsg,
);
typedef _Sqlite3ExecDart = int Function(
  ffi.Pointer<ffi.Void> db,
  ffi.Pointer<Utf8> sql,
  ffi.Pointer<ffi.Void> callback,
  ffi.Pointer<ffi.Void> arg,
  ffi.Pointer<ffi.Pointer<Utf8>> errmsg,
);

typedef _Sqlite3CloseNative = ffi.Int32 Function(ffi.Pointer<ffi.Void> db);
typedef _Sqlite3CloseDart = int Function(ffi.Pointer<ffi.Void> db);

Future<void> main() async {
  final Directory rootDir = File(Platform.script.toFilePath()).parent;
  final Directory projectRoot = rootDir.parent;

  final List<HttpServer> servers = [];

  for (final int port in [5555, 5556, 8090, 3000]) {
    try {
      final server = await HttpServer.bind(
        InternetAddress.anyIPv6,
        port,
        v6Only: false,
        shared: true,
      );
      servers.add(server);
      _handleRequests(server, rootDir, projectRoot);
      stdout.writeln('✅ LOWLAND Web Admin & SQLite Sync Server: http://localhost:$port');
    } catch (e) {
      try {
        final server = await HttpServer.bind(
          InternetAddress.anyIPv4,
          port,
          shared: true,
        );
        servers.add(server);
        _handleRequests(server, rootDir, projectRoot);
        stdout.writeln('✅ LOWLAND Web Admin (IPv4): http://127.0.0.1:$port');
      } catch (_) {}
    }
  }

  if (servers.isEmpty) {
    stderr.writeln('Không thể khởi tạo server trên cổng 5555, 8090 hoặc 3000.');
    exit(1);
  }
}

void _handleRequests(HttpServer server, Directory rootDir, Directory projectRoot) {
  server.listen((HttpRequest request) async {
    try {
      request.response.headers.set('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0');
      request.response.headers.set('Pragma', 'no-cache');
      request.response.headers.set('Expires', '0');
      request.response.headers.set('Access-Control-Allow-Origin', '*');
      request.response.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      request.response.headers.set('Access-Control-Allow-Headers', 'Content-Type, Accept');

      if (request.method == 'OPTIONS') {
        request.response.statusCode = HttpStatus.ok;
        await request.response.close();
        return;
      }

      // Endpoint đồng bộ Realtime từ App xuống file vật lý D:\FA26\prm_project\lowland_coffee.db
      if (request.method == 'POST' && request.uri.path == '/api/sync-sqlite') {
        final String body = await utf8.decoder.bind(request).join();
        final Map<String, dynamic> data = jsonDecode(body) as Map<String, dynamic>;
        _writeSqliteDatabaseFile(projectRoot, data);
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"ok":true}');
        await request.response.close();
        return;
      }

      String reqPath = request.uri.path;
      if (reqPath == '/' || reqPath.isEmpty) {
        reqPath = '/index.html';
      }

      final String cleanRelPath = reqPath
          .replaceAll('\\', '/')
          .split('/')
          .where((segment) => segment.isNotEmpty && segment != '..' && segment != '.')
          .join(Platform.pathSeparator);

      final File file = File('${rootDir.path}${Platform.pathSeparator}$cleanRelPath');

      if (await file.exists()) {
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = _getContentType(file.path);
        await request.response.addStream(file.openRead());
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.headers.contentType = ContentType.html;
        request.response.write('<h3>404 - Không tìm thấy tệp: $reqPath</h3>');
      }
    } catch (_) {
      try {
        request.response.statusCode = HttpStatus.internalServerError;
      } catch (_) {}
    } finally {
      try {
        await request.response.close();
      } catch (_) {}
    }
  });
}

String _esc(dynamic v) {
  if (v == null) return 'NULL';
  final s = v.toString().replaceAll("'", "''");
  return "'$s'";
}

void _writeSqliteDatabaseFile(Directory projectRoot, Map<String, dynamic> data) {
  try {
    final List<dynamic> cartItems = (data['cart_items'] as List<dynamic>?) ?? [];
    final List<dynamic> favorites = (data['favorites'] as List<dynamic>?) ?? [];
    final List<dynamic> orders = (data['order_history'] as List<dynamic>?) ?? [];
    final Map<String, dynamic> prefs =
        (data['shared_preferences'] as Map<String, dynamic>?) ?? {};

    final StringBuffer sb = StringBuffer();
    sb.writeln('BEGIN TRANSACTION;');

    sb.writeln('''
CREATE TABLE IF NOT EXISTS cart_items (
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
);
CREATE TABLE IF NOT EXISTS favorites (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  productId TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  imageUrl TEXT,
  price REAL NOT NULL,
  description TEXT,
  createdAt TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS order_history (
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
);
CREATE TABLE IF NOT EXISTS shared_preferences (
  prefKey TEXT PRIMARY KEY NOT NULL,
  prefValue TEXT
);
DELETE FROM cart_items;
DELETE FROM favorites;
DELETE FROM order_history;
DELETE FROM shared_preferences;
''');

    for (final raw in cartItems) {
      final m = Map<String, dynamic>.from(raw as Map);
      sb.writeln(
        'INSERT INTO cart_items (productId, name, imageUrl, basePrice, selectedSize, selectedSugar, selectedIce, selectedToppings, itemPrice, quantity, totalPrice, createdAt) VALUES (${_esc(m['productId'])}, ${_esc(m['name'])}, ${_esc(m['imageUrl'])}, ${m['basePrice'] ?? 0}, ${_esc(m['selectedSize'] ?? 'S')}, ${m['selectedSugar'] ?? 100}, ${m['selectedIce'] ?? 100}, ${_esc(m['selectedToppings'] ?? '[]')}, ${m['itemPrice'] ?? 0}, ${m['quantity'] ?? 1}, ${m['totalPrice'] ?? 0}, ${_esc(m['createdAt'] ?? DateTime.now().toIso8601String())});',
      );
    }

    for (final raw in favorites) {
      final m = Map<String, dynamic>.from(raw as Map);
      sb.writeln(
        'INSERT OR REPLACE INTO favorites (productId, name, category, imageUrl, price, description, createdAt) VALUES (${_esc(m['productId'] ?? m['id'])}, ${_esc(m['name'])}, ${_esc(m['category'] ?? 'Cà phê')}, ${_esc(m['imageUrl'])}, ${m['price'] ?? 0}, ${_esc(m['description'])}, ${_esc(m['createdAt'] ?? DateTime.now().toIso8601String())});',
      );
    }

    for (final raw in orders) {
      final m = Map<String, dynamic>.from(raw as Map);
      sb.writeln(
        'INSERT OR REPLACE INTO order_history (orderId, userId, itemsJson, subtotal, discount, voucherCode, totalAmount, orderDate, status, paymentMethod) VALUES (${_esc(m['orderId'])}, ${_esc(m['userId'] ?? 'guest')}, ${_esc(m['itemsJson'] ?? '[]')}, ${m['subtotal'] ?? 0}, ${m['discount'] ?? 0}, ${_esc(m['voucherCode'])}, ${m['totalAmount'] ?? 0}, ${_esc(m['orderDate'] ?? DateTime.now().toIso8601String())}, ${_esc(m['status'] ?? 'Mới nhận')}, ${_esc(m['paymentMethod'] ?? 'Tiền mặt (COD)')});',
      );
    }

    prefs.forEach((key, value) {
      sb.writeln(
        'INSERT OR REPLACE INTO shared_preferences (prefKey, prefValue) VALUES (${_esc(key)}, ${_esc(value)});',
      );
    });

    sb.writeln('COMMIT;');
    final String sqlText = sb.toString();

    // Lưu bản .sql
    final File sqlFile = File('${projectRoot.path}${Platform.pathSeparator}lowland_coffee_sqlite.sql');
    sqlFile.writeAsStringSync(sqlText);

    // Thực thi trực tiếp vào file nhị phân lowland_coffee.db bằng winsqlite3.dll của Windows
    final String dbFilePath = '${projectRoot.path}${Platform.pathSeparator}lowland_coffee.db';
    final dylib = ffi.DynamicLibrary.open('winsqlite3.dll');
    final sqlite3Open = dylib.lookupFunction<_Sqlite3OpenNative, _Sqlite3OpenDart>('sqlite3_open');
    final sqlite3Exec = dylib.lookupFunction<_Sqlite3ExecNative, _Sqlite3ExecDart>('sqlite3_exec');
    final sqlite3Close = dylib.lookupFunction<_Sqlite3CloseNative, _Sqlite3CloseDart>('sqlite3_close');

    final dbPathPtr = dbFilePath.toNativeUtf8();
    final sqlPtr = sqlText.toNativeUtf8();
    final ppDb = calloc<ffi.Pointer<ffi.Void>>();
    final errMsg = calloc<ffi.Pointer<Utf8>>();

    try {
      final rc = sqlite3Open(dbPathPtr, ppDb);
      if (rc == 0 && ppDb.value != ffi.nullptr) {
        sqlite3Exec(ppDb.value, sqlPtr, ffi.nullptr, ffi.nullptr, errMsg);
        sqlite3Close(ppDb.value);
      }
    } finally {
      calloc.free(dbPathPtr);
      calloc.free(sqlPtr);
      calloc.free(ppDb);
      calloc.free(errMsg);
    }
  } catch (e) {
    stdout.writeln('Lỗi đồng bộ SQLite: $e');
  }
}

ContentType _getContentType(String path) {
  final String lower = path.toLowerCase();
  if (lower.endsWith('.html') || lower.endsWith('.htm')) {
    return ContentType('text', 'html', charset: 'utf-8');
  } else if (lower.endsWith('.js') || lower.endsWith('.mjs')) {
    return ContentType('application', 'javascript', charset: 'utf-8');
  } else if (lower.endsWith('.css')) {
    return ContentType('text', 'css', charset: 'utf-8');
  } else if (lower.endsWith('.json')) {
    return ContentType('application', 'json', charset: 'utf-8');
  } else if (lower.endsWith('.png')) {
    return ContentType('image', 'png');
  } else if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    return ContentType('image', 'jpeg');
  } else if (lower.endsWith('.svg')) {
    return ContentType('image', 'svg+xml');
  } else if (lower.endsWith('.ico')) {
    return ContentType('image', 'x-icon');
  }
  return ContentType.binary;
}
