// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;

Future<String?> pickImagePlatform() async {
  final completer = Completer<String?>();
  final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
  uploadInput.click();

  uploadInput.onChange.listen((event) {
    final files = uploadInput.files;
    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }

    final file = files.first;
    final reader = html.FileReader();
    reader.readAsDataUrl(file);

    reader.onLoadEnd.listen((_) {
      final result = reader.result as String?;
      if (result == null) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }

      // Nén ảnh bằng HTML5 Canvas xuống tối đa 320px để lưu vào Firestore & LocalStorage siêu nhẹ
      final img = html.ImageElement();
      img.onLoad.listen((_) {
        const int maxDim = 320;
        int width = img.width ?? 320;
        int height = img.height ?? 320;

        if (width > height && width > maxDim) {
          height = ((height * maxDim) / width).round();
          width = maxDim;
        } else if (height > maxDim) {
          width = ((width * maxDim) / height).round();
          height = maxDim;
        }

        final canvas = html.CanvasElement(width: width, height: height);
        final ctx = canvas.context2D;
        ctx.drawImageScaled(img, 0, 0, width, height);
        final compressedDataUrl = canvas.toDataUrl('image/jpeg', 0.82);

        if (!completer.isCompleted) {
          completer.complete(compressedDataUrl);
        }
      });

      img.onError.listen((_) {
        if (!completer.isCompleted) completer.complete(result);
      });

      img.src = result;
    });
  });

  return completer.future;
}

