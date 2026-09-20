import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VerseOfDayHomeCard extends StatelessWidget {
  final bool isDark;
  final void Function(String text, String reference)? onOpen;

  const VerseOfDayHomeCard({
    super.key,
    required this.isDark,
    this.onOpen,
  });

  static String armenianDate([DateTime? date]) {
    const months = <String>[
      'հունվարի',
      'փետրվարի',
      'մարտի',
      'ապրիլի',
      'մայիսի',
      'հունիսի',
      'հուլիսի',
      'օգոստոսի',
      'սեպտեմբերի',
      'հոկտեմբերի',
      'նոյեմբերի',
      'դեկտեմբերի',
    ];
    final d = date ?? DateTime.now();
    final month = months[d.month - 1];
    return '${month[0].toUpperCase()}${month.substring(1)} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('verseOfDay')
          .doc('today')
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final text = data['text'] as String? ?? '';
        final reference = data['reference'] as String? ?? '';
        final hasVerse = text.trim().isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Text(
                    'Օրվա խոսք',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFE6E3DB)
                          : const Color(0xFF3D463F),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    armenianDate(),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? const Color(0xFF8E948C)
                          : const Color(0xFFB8B6AE),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Material(
              color: isDark
                  ? const Color(0xFF3A4A3C)
                  : const Color(0xFFD4DDD2),
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                onTap: hasVerse ? () => onOpen?.call(text, reference) : null,
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              hasVerse
                                  ? (text.trim().startsWith('«')
                                      ? text.trim()
                                      : '«${text.trim()}»')
                                  : 'Դեռևս Օրվա Խոսք ավելացված չէ։',
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.45,
                                color: hasVerse
                                    ? (isDark
                                        ? const Color(0xFFE6E3DB)
                                        : const Color(0xFF3D463F))
                                    : (isDark
                                        ? const Color(0xFF8E948C)
                                        : const Color(0xFFB8B6AE)),
                              ),
                            ),
                          ),
                          if (hasVerse)
                            Padding(
                              padding: const EdgeInsets.only(left: 8, top: 2),
                              child: Icon(
                                Icons.chevron_right,
                                color: isDark
                                    ? const Color(0xFF8E948C)
                                    : const Color(0xFFB8B6AE),
                              ),
                            ),
                        ],
                      ),
                      if (reference.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          reference,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFF8A8768)
                                : const Color(0xFF3F4C41),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class VerseOfDayScreen extends StatelessWidget {
  const VerseOfDayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Օրվա Խոսքը'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('verseOfDay')
            .doc('today')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Սխալ: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() ?? {};
          final text = data['text'] as String? ?? '';
          final reference = data['reference'] as String? ?? '';

          if (!snapshot.hasData ||
              snapshot.data?.exists != true ||
              text.isEmpty) {
            return const Center(
              child: Text('Դեռևս Օրվա Խոսք ավելացված չէ։'),
            );
          }

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (reference.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      reference,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
