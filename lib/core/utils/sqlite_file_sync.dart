import 'sqlite_file_sync_stub.dart'
    if (dart.library.js_interop) 'sqlite_file_sync_web.dart'
    if (dart.library.io) 'sqlite_file_sync_io.dart';

/// Đồng bộ dữ liệu cục bộ từ App sang file SQLite vật lý (D:\FA26\prm_project\lowland_coffee.db)
Future<void> syncAppStateToSqliteFile(String jsonPayload) =>
    postSqliteSyncPayload(jsonPayload);

