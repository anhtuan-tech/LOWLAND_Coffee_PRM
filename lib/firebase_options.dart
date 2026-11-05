import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Cấu hình Firebase tự động cho cả Android và Web
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDh87j1s8dvGNHpP7Jsqw-6chaokejNoz8',
    appId: '1:914107662357:web:09d4ea1da4306ee4ed0e1c',
    messagingSenderId: '914107662357',
    projectId: 'lowland-coffee',
    authDomain: 'lowland-coffee.firebaseapp.com',
    storageBucket: 'lowland-coffee.firebasestorage.app',
    measurementId: 'G-2MQV2NXC5Q',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB9CrMrMvGK5rsiiJhsx86Mr-Zsxt6Srtw',
    appId: '1:914107662357:android:82b4b85876760c06ed0e1c',
    messagingSenderId: '914107662357',
    projectId: 'lowland-coffee',
    storageBucket: 'lowland-coffee.firebasestorage.app',
  );
}

