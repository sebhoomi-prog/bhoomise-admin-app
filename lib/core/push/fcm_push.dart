import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

Future<void> _persistFcmTokenToUserDoc(String token) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null || token.isEmpty) return;
  try {
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        'fcmTokens': FieldValue.arrayUnion([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  } on Object catch (e) {
    if (kDebugMode) {
      debugPrint('FCM token persist failed: $e');
    }
  }
}

/// Must be a top-level function; register before other Firebase Messaging usage.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    debugPrint(
      'FCM background message: ${message.messageId} '
      '${message.notification?.title}',
    );
  }
}

/// Firebase Cloud Messaging — permission, tokens, foreground handling.
///
/// **iOS:** Requires Push capability (Runner entitlements), `UIBackgroundModes` =
/// `remote-notification`, and an **APNs Authentication Key** uploaded in Firebase Console
/// → Project settings → Cloud Messaging.
Future<void> setupFirebaseMessaging() async {
  try {
    final messaging = FirebaseMessaging.instance;

    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('FCM setForegroundNotificationPresentationOptions: $e');
      }
    }

    try {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('FCM requestPermission: $e');
      }
    }

    // Do not await getToken() during startup — Installations often returns
    // SERVICE_NOT_AVAILABLE offline and older plugin builds still threw.
    // Best-effort: log (debug) + persist token on `users/{uid}` for future Cloud Functions push.
    scheduleMicrotask(() async {
      try {
        final t = await FirebaseMessaging.instance
            .getToken()
            .timeout(const Duration(seconds: 20));
        if (kDebugMode) {
          debugPrint('FCM registration token: $t');
        }
        if (t != null && t.isNotEmpty) {
          await _persistFcmTokenToUserDoc(t);
        }
      } on Object catch (e) {
        if (kDebugMode) {
          debugPrint(
            'FCM getToken unavailable (network / Installations): $e',
          );
        }
      }
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((t) {
      scheduleMicrotask(() async {
        await _persistFcmTokenToUserDoc(t);
      });
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint(
          'FCM foreground: ${message.notification?.title} '
          '${message.notification?.body}',
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('FCM notification opened app: ${message.messageId}');
      }
    });
  } on Object catch (e) {
    if (kDebugMode) {
      debugPrint('FCM setup aborted: $e');
    }
  }
}
