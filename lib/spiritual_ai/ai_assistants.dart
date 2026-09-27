import 'dart:math' as math;

import 'package:flutter/material.dart';

class AiAssistant {
  final String id;
  final String name;
  final String hint;
  final Color color;
  final Widget logo;

  const AiAssistant({
    required this.id,
    required this.name,
    required this.hint,
    required this.color,
    required this.logo,
  });
}

class AiAssistantCatalog {
  static const chatgpt = AiAssistant(
    id: 'chatgpt',
    name: 'ChatGPT',
    hint: 'Գրիր ChatGPT-ին',
    color: Color(0xFF10A37F),
    logo: ChatGptLogo(),
  );
  static const gemini = AiAssistant(
    id: 'gemini',
    name: 'Gemini',
    hint: 'Գրիր Gemini-ին',
    color: Color(0xFF4B8BFF),
    logo: GeminiLogo(),
  );
  static const grok = AiAssistant(
    id: 'grok',
    name: 'Grok',
    hint: 'Գրիր Grok-ին',
    color: Color(0xFF111111),
    logo: GrokLogo(),
  );
  static const claude = AiAssistant(
    id: 'claude',
    name: 'Claude',
    hint: 'Գրիր Claude-ին',
    color: Color(0xFFD97757),
    logo: ClaudeLogo(),
  );

  static const all = <AiAssistant>[
    chatgpt,
    gemini,
    grok,
    claude,
  ];

  static AiAssistant? find(String? id) {
    for (final item in all) {
      if (item.id == id) return item;
    }
    return null;
  }
}

class GeminiLogo extends StatelessWidget {
  const GeminiLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size.square(28),
      painter: _GeminiPainter(),
    );
  }
}

class ChatGptLogo extends StatelessWidget {
  const ChatGptLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size.square(28),
      painter: _ChatGptPainter(),
    );
  }
}

class GrokLogo extends StatelessWidget {
  const GrokLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 28,
      height: 28,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xFF111111),
          shape: BoxShape.circle,
        ),
        child: CustomPaint(
          painter: _GrokPainter(),
        ),
      ),
    );
  }
}

class ClaudeLogo extends StatelessWidget {
  const ClaudeLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size.square(28),
      painter: _ClaudePainter(),
    );
  }
}

class _GeminiPainter extends CustomPainter {
  const _GeminiPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.50, h * 0.02)
      ..quadraticBezierTo(w * 0.62, h * 0.38, w * 0.98, h * 0.50)
      ..quadraticBezierTo(w * 0.62, h * 0.62, w * 0.50, h * 0.98)
      ..quadraticBezierTo(w * 0.38, h * 0.62, w * 0.02, h * 0.50)
      ..quadraticBezierTo(w * 0.38, h * 0.38, w * 0.50, h * 0.02)
      ..close();
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF4B8BFF),
          Color(0xFF8B6CFF),
          Color(0xFFE25B78),
          Color(0xFFF0B429),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChatGptPainter extends CustomPainter {
  const _ChatGptPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.075
      ..strokeCap = StrokeCap.round;
    final radius = size.width * 0.30;
    for (var i = 0; i < 6; i++) {
      final angle = -math.pi / 2 + i * math.pi / 3;
      final dir = Offset(math.cos(angle), math.sin(angle));
      final side = Offset(-dir.dy, dir.dx);
      final mid = c + dir * radius * 0.15;
      canvas.drawLine(
        mid - side * radius * 0.72 + dir * radius * 0.55,
        mid + side * radius * 0.72 + dir * radius * 0.55,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GrokPainter extends CustomPainter {
  const _GrokPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(w * 0.28, h * 0.22)
      ..lineTo(w * 0.62, h * 0.22)
      ..quadraticBezierTo(w * 0.80, h * 0.22, w * 0.80, h * 0.40)
      ..quadraticBezierTo(w * 0.80, h * 0.56, w * 0.62, h * 0.62)
      ..lineTo(w * 0.46, h * 0.78)
      ..lineTo(w * 0.40, h * 0.64)
      ..lineTo(w * 0.34, h * 0.64)
      ..quadraticBezierTo(w * 0.22, h * 0.64, w * 0.22, h * 0.48)
      ..quadraticBezierTo(w * 0.22, h * 0.22, w * 0.28, h * 0.22)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(w * 0.48, h * 0.40), w * 0.045, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ClaudePainter extends CustomPainter {
  const _ClaudePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint()..color = const Color(0xFFD97757);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    for (var i = 0; i < 8; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(0, -size.height * 0.02),
            width: size.width * 0.16,
            height: size.height * 0.92,
          ),
          Radius.circular(size.width),
        ),
        paint,
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
