import 'dart:convert';
import 'dart:io';

Future<void> postSqliteSyncPayload(String jsonPayload) async {
  for (final port in [5556, 5555]) {
    final client = HttpClient();
    client.connectionTimeout = const Duration(milliseconds: 800);
    try {
      final req = await client.postUrl(Uri.parse('http://localhost:$port/api/sync-sqlite'));
      req.headers.contentType = ContentType.json;
      req.add(utf8.encode(jsonPayload));
      final res = await req.close();
      await res.drain<void>();
      break;
    } catch (_) {
    } finally {
      client.close();
    }
  }
}
