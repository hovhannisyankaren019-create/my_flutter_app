import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _VerseOfDayCache {
  static const _textKey = 'cached_verse_of_day_text';
  static const _refKey = 'cached_verse_of_day_ref';
  static const _editionKey = 'cached_verse_of_day_edition';

  static Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots() {
    if (Firebase.apps.isEmpty) {
      return const Stream.empty();
    }
    try {
      return FirebaseFirestore.instance
          .collection('verseOfDay')
          .doc('today')
          .snapshots();
    } catch (_) {
      return const Stream.empty();
    }
  }

  static Future<void> save({
    required String text,
    required String reference,
    required String edition,
  }) async {
    if (text.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_textKey, text);
    await prefs.setString(_refKey, reference);
    await prefs.setString(_editionKey, edition);
  }

  static Future<Map<String, String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'text': prefs.getString(_textKey) ?? '',
      'reference': prefs.getString(_refKey) ?? '',
      'edition': prefs.getString(_editionKey) ?? '',
    };
  }
}

class VerseOfDayHomeCard extends StatefulWidget {
  final bool isDark;
  final void Function(String text, String reference, String edition)? onOpen;

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
  State<VerseOfDayHomeCard> createState() => _VerseOfDayHomeCardState();
}

class _VerseOfDayHomeCardState extends State<VerseOfDayHomeCard> {
  String _cachedText = '';
  String _cachedReference = '';
  String _cachedEdition = '';

  @override
  void initState() {
    super.initState();
    _loadCache();
  }

  Future<void> _loadCache() async {
    final cached = await _VerseOfDayCache.load();
    if (!mounted) return;
    setState(() {
      _cachedText = cached['text'] ?? '';
      _cachedReference = cached['reference'] ?? '';
      _cachedEdition = cached['edition'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _VerseOfDayCache.snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        var text = data['text'] as String? ?? '';
        var reference = data['reference'] as String? ?? '';
        var edition =
            '${data['edition'] ?? data['translation'] ?? data['source'] ?? ''}';
        if (text.trim().isEmpty) {
          text = _cachedText;
          reference = _cachedReference;
          edition = _cachedEdition;
        } else {
          _VerseOfDayCache.save(
            text: text,
            reference: reference,
            edition: edition,
          );
        }
        final hasVerse = text.trim().isNotEmpty;

        final quoted = hasVerse
            ? (text.trim().startsWith('«') ? text.trim() : '«${text.trim()}»')
            : 'Դեռևս Օրվա Խոսք ավելացված չէ։';
        final lineColor =
            isDark ? const Color(0xFFD8D3C4) : const Color(0xFF8A8768);
        final cardColor =
            isDark ? const Color(0xFF5A6158) : const Color(0xFFF7F5EF);
        final titleColor =
            isDark ? const Color(0xFFB8B6A6) : const Color(0xFF8A8768);
        final bodyColor = hasVerse
            ? (isDark ? const Color(0xFFE6E3DB) : const Color(0xFF3D463F))
            : (isDark ? const Color(0xFF8E948C) : const Color(0xFFB8B6AE));

        return Material(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: hasVerse
                ? () => widget.onOpen?.call(text, reference, edition)
                : null,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 8, 16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 3,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: lineColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'ՕՐՎԱ ԽՈՍՔ',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: titleColor,
                                ),
                              ),
                              const Spacer(),
                              if (hasVerse)
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  onPressed: () async {
                                    final shareText = reference.isEmpty
                                        ? quoted
                                        : '$quoted\n$reference';
                                    await Clipboard.setData(
                                      ClipboardData(text: shareText),
                                    );
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context)
                                        .hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Պատճենված է'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  icon: Icon(
                                    Icons.content_copy,
                                    size: 18,
                                    color: titleColor,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            quoted,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.45,
                              color: bodyColor,
                            ),
                          ),
                          if (reference.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              reference,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? const Color(0xFFC4C0A8)
                                    : const Color(0xFF3F4C41),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class VerseOfDayScreen extends StatefulWidget {
  const VerseOfDayScreen({super.key});

  @override
  State<VerseOfDayScreen> createState() => _VerseOfDayScreenState();
}

class _VerseOfDayScreenState extends State<VerseOfDayScreen> {
  String _cachedText = '';
  String _cachedReference = '';

  @override
  void initState() {
    super.initState();
    _loadCache();
  }

  Future<void> _loadCache() async {
    final cached = await _VerseOfDayCache.load();
    if (!mounted) return;
    setState(() {
      _cachedText = cached['text'] ?? '';
      _cachedReference = cached['reference'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Օրվա Խոսքը'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _VerseOfDayCache.snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? {};
          var text = data['text'] as String? ?? '';
          var reference = data['reference'] as String? ?? '';
          if (text.trim().isEmpty) {
            text = _cachedText;
            reference = _cachedReference;
          } else {
            _VerseOfDayCache.save(
              text: text,
              reference: reference,
              edition: '',
            );
          }

          if (text.trim().isEmpty) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
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
