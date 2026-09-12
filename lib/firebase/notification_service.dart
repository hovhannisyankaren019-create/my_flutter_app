import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_messaging_service.dart';
import 'verse_of_day_screen.dart';

class NotificationService {
  static Future<void> init() async {
    await FirebaseMessagingService.initialize();
  }

  static void handleTap(RemoteMessage message) {
    final isVerseOfDay = message.data['type'] == 'verse_of_day' ||
        message.notification?.title == 'Օրվա Խոսքը';

    if (isVerseOfDay) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const VerseOfDayScreen()),
      );
    }
  }
}
