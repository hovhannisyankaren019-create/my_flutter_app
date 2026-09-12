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
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    try {
      await _messaging.subscribeToTopic('all_users');
    } catch (_) {}

    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleTap(initialMessage);
      });
    }
  }

  static void _handleTap(RemoteMessage message) {
    final isVerseOfDay = message.data['type'] == 'verse_of_day' ||
        message.notification?.title == 'Օրվա Խոսքը';

    if (isVerseOfDay) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const VerseOfDayScreen()),
      );
    }
  }
}
