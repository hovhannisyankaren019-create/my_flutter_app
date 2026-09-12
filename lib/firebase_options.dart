import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase web config is not set.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Firebase is configured for Android and iOS.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAL59tEdRTRANUApl-BSDFu7l8FTIbq8UE',
    appId: '1:679587606372:android:15e99d78e73bce23d7d471',
    messagingSenderId: '679587606372',
    projectId: 'spiritual-ai-414c4',
    storageBucket: 'spiritual-ai-414c4.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAL59tEdRTRANUApl-BSDFu7l8FTIbq8UE',
    appId: '1:679587606372:ios:15e99d78e73bce23d7d471',
    messagingSenderId: '679587606372',
    projectId: 'spiritual-ai-414c4',
    storageBucket: 'spiritual-ai-414c4.firebasestorage.app',
    iosBundleId: 'com.armenianbible.bible',
    iosClientId:
        '679587606372-dparr4ipppihjculmvl2pi013584mm09.apps.googleusercontent.com',
  );
}
