import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';
import 'verse_of_day_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class FirebaseMessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (_) {}

    try {
      await _messaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
          )
          .timeout(const Duration(seconds: 3));
    } catch (_) {}

    try {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {}

    unawaited(_registerDevice());
    try {
      _messaging.onTokenRefresh.listen((token) {
        _registerDevice();
      });
    } catch (_) {}

    try {
      FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
    } catch (_) {}

    try {
      final initialMessage = await _messaging
          .getInitialMessage()
          .timeout(const Duration(seconds: 2));
      if (initialMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleTap(initialMessage);
        });
      }
    } catch (_) {}

    if (Platform.isIOS) {
      Future<void>.delayed(const Duration(seconds: 3), _registerDevice);
      Future<void>.delayed(const Duration(seconds: 10), _registerDevice);
    }
  }

  static Future<void> _registerDevice() async {
    String fcmToken = '';
    String apnsToken = '';
    try {
      if (Platform.isIOS) {
        apnsToken = (await _messaging
                    .getAPNSToken()
                    .timeout(const Duration(seconds: 2)))
                ?.replaceAll(' ', '') ??
            '';
      }
    } catch (_) {}
    try {
      fcmToken =
          (await _messaging.getToken().timeout(const Duration(seconds: 4))) ??
              '';
    } catch (_) {}

    final id = fcmToken.isNotEmpty
        ? 'fcm_${fcmToken.replaceAll('/', '_')}'
        : (apnsToken.isNotEmpty ? 'apns_$apnsToken' : '');
    if (id.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('verseOfDay')
            .doc(id)
            .set({
          'token': fcmToken,
          'apnsToken': apnsToken,
          'platform': Platform.operatingSystem,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
            .timeout(const Duration(seconds: 4));
      } catch (_) {}
    }

    try {
      await _messaging
          .subscribeToTopic('all_users')
          .timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  static void _handleTap(RemoteMessage message) {
    final isVerseOfDay = message.data['type'] == 'verse_of_day' ||
        message.notification?.title == 'Օրվա խոսք' ||
        message.notification?.title == 'Օրվա Խոսքը';

    if (isVerseOfDay) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const VerseOfDayScreen()),
      );
    }
  }
}
