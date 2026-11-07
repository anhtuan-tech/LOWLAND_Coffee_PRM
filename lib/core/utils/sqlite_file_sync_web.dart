// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

Future<void> postSqliteSyncPayload(String jsonPayload) async {
  for (final port in [5556, 5555]) {
    try {
      await html.HttpRequest.request(
        'http://localhost:$port/api/sync-sqlite',
        method: 'POST',
        sendData: jsonPayload,
        requestHeaders: {'Content-Type': 'application/json; charset=utf-8'},
      );
      break;
    } catch (_) {}
  }
}
