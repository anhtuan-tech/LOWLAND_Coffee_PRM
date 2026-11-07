import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

Future<String?> pickImagePlatform() async {
  try {
    if (Platform.isWindows) {
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-STA',
        '-Command',
        r'''
Add-Type -AssemblyName System.Windows.Forms
$dlg = New-Object System.Windows.Forms.OpenFileDialog
$dlg.Title = "Chon anh dai dien tu may tinh"
$dlg.Filter = "Image Files (*.jpg;*.jpeg;*.png;*.webp)|*.jpg;*.jpeg;*.png;*.webp"
if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
  Write-Output $dlg.FileName
}
'''
      ]);

      final filePath = result.stdout.toString().trim();
      if (filePath.isEmpty) return null;

      final file = File(filePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();

      // Nén kích thước ảnh về tối đa 300px để lưu vào Firestore & SharedPreferences
      try {
        final codec = await ui.instantiateImageCodec(
          bytes,
          targetWidth: 300,
        );
        final frame = await codec.getNextFrame();
        final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final resizedBytes = byteData.buffer.asUint8List();
          return 'data:image/png;base64,${base64Encode(resizedBytes)}';
        }
      } catch (_) {}

      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }
  } catch (_) {}
  return null;
}

