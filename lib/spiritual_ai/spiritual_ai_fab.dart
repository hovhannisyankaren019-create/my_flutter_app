import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../firebase/auth_screen.dart';
import '../main.dart';
import 'spiritual_ai_screen.dart';

class SpiritualAiFab extends StatelessWidget {
  const SpiritualAiFab({super.key});

  void _openSpiritualAi(BuildContext context) {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {
      user = null;
    }

    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AuthScreen(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SpiritualAiScreen(
            isGuest: false,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 6),
      child: Tooltip(
        message: 'ԱԲ',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _openSpiritualAi(context),
            child: Ink(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.forest,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.forest.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: AppColors.cream,
                    size: 26,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'ԱԲ',
                    style: TextStyle(
                      color: AppColors.cream,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
