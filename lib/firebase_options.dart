// Generated from `google-services.json` + `GoogleService-Info.plist` (project `bhoomise`).
// Android applicationId / iOS bundle id: `com.bhoomise`. Re-run `flutterfire configure` after Firebase app id changes.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with `package:firebase_core`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web — run flutterfire configure.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos — run flutterfire configure.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAVDv3FHRCQwihwwG5PaOQEzHvYEOjqnGQ',
    appId: '1:203873375607:android:d44c2a878928eb47c27d72',
    messagingSenderId: '203873375607',
    projectId: 'bhoomise',
    storageBucket: 'bhoomise.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBCTGc7IfjLTXKMehpbnTJiBgf3-vEME9U',
    appId: '1:203873375607:ios:3e6f64e062138cdac27d72',
    messagingSenderId: '203873375607',
    projectId: 'bhoomise',
    storageBucket: 'bhoomise.firebasestorage.app',
    iosBundleId: 'com.bhoomise',
  );
}
