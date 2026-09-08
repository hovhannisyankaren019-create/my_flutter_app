import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../spiritual_image/spiritual_image_service.dart';
import 'bible_context.dart';
import 'spiritual_ai_config.dart';
import 'spiritual_ai_service.dart';

class SpiritualAiScreen extends StatefulWidget {
  const SpiritualAiScreen({super.key});

  @override
  State<SpiritualAiScreen> createState() => _SpiritualAiScreenState();
}

class _ChatItem {
  final String role;
  final String text;
  final List<BiblePassage> passages;

  const _ChatItem({
    required this.role,
    required this.text,
    this.passages = const [],
  });
}

class _SpiritualAiScreenState extends State<SpiritualAiScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _service = SpiritualAiService();
  final _historyLookup = SpiritualImageService();
  final _messages = <_ChatItem>[];
  bool _sending = false;
  bool _indexReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BibleContextRetriever.instance.ensureReady();
      if (mounted) setState(() => _indexReady = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    if (_sending) return;
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty) return;

    setState(() {
      _sending = true;
      _messages.add(_ChatItem(role: 'user', text: text));
      _controller.clear();
    });
    _scrollToEnd();

    try {
      final retriever = BibleContextRetriever.instance;
      retriever.ensureReady();
      final previous = _messages.sublist(0, _messages.length - 1);
      var lastUserText = '';
      for (final item in previous.reversed) {
        if (item.role == 'user') {
          lastUserText = item.text;
          break;
        }
      }
      final followUp = retriever.looksLikeFollowUp(
        text,
        hasPriorTurn: previous.any((item) => item.role == 'assistant'),
        previousUser: lastUserText,
      );
      final wantsHistory = retriever.wantsHistoricalFacts(text);
      if (retriever.looksLikeImageAsk(text) && !wantsHistory) {
        setState(() {
          _messages.add(
            const _ChatItem(
              role: 'assistant',
              text: BibleContextRetriever.imagesOffReply,
            ),
          );
        });
        return;
      }
      final searchQuery =
          (followUp || wantsHistory) ? _searchContext(text, previous) : text;
      final history = _apiHistory(
        previous,
        followUp: followUp || wantsHistory,
      );

      var askText = text;
      var sourceLines = '';
      if (wantsHistory) {
        final topic = _historicalTopic(text, previous);
        try {
          final lookup = await _historyLookup.findHistorical(prompt: topic);
          if (lookup.factsText.trim().isNotEmpty) {
            askText =
                '$text\n\nԱղբյուրներ (պատմություն, ժամանակ, վայր, ում համար է գրվել գիրքը և ինչու — պատասխանիր սրանցով, թվեր մի հորինիր, միայն հայերենով).\n${lookup.factsText}';
          }
          if (lookup.sources.isNotEmpty) {
            final buf = StringBuffer('Աղբյուրներ');
            for (final source in lookup.sources.take(4)) {
              final name =
                  source.source.isNotEmpty ? source.source : source.title;
              buf.writeln();
              buf.write('• $name: ${source.url}');
            }
            sourceLines = buf.toString();
          }
        } catch (_) {}
      }

      final reply = await _service.ask(
        message: askText,
        history: history,
        followUp: followUp || wantsHistory,
        searchQuery: searchQuery,
      );
      if (!mounted) return;
      final body = [
        reply.text.trim(),
        if (sourceLines.isNotEmpty) sourceLines,
      ].where((part) => part.isNotEmpty).join('\n\n');
      setState(() {
        _messages.add(
          _ChatItem(
            role: 'assistant',
            text: body,
            passages: reply.passages,
          ),
        );
      });
    } on SpiritualAiException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatItem(role: 'assistant', text: e.message));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          const _ChatItem(
            role: 'assistant',
            text: 'Կապի սխալ։ Խնդրում ենք ստուգել ինտերնետը և նորից փորձել։',
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToEnd();
      }
    }
  }

  List<Map<String, String>> _apiHistory(
    List<_ChatItem> previous, {
    required bool followUp,
  }) {
    final usable = <_ChatItem>[];
    for (var i = 0; i < previous.length; i++) {
      final item = previous[i];
      if (!followUp &&
          item.role == 'user' &&
          BibleContextRetriever.instance
              .quoteExplicitReferences(item.text)
              .matched) {
        if (i + 1 < previous.length && previous[i + 1].role == 'assistant') {
          i++;
        }
        continue;
      }
      usable.add(item);
    }
    final turns = <Map<String, String>>[
      for (final item in usable)
        if (item.text.trim().isNotEmpty)
          {
            'role': item.role,
            'content': item.text.trim().length > 1200
                ? item.text.trim().substring(0, 1200)
                : item.text.trim(),
          },
    ];
    final start = turns.length > 6 ? turns.length - 6 : 0;
    return turns.sublist(start);
  }

  String _searchContext(String text, List<_ChatItem> previous) {
    String lastOf(String role) {
      for (final item in previous.reversed) {
        if (item.role == role && item.text.trim().isNotEmpty) {
          final t = item.text.trim();
          return t.length > 400 ? t.substring(0, 400) : t;
        }
      }
      return '';
    }

    return [lastOf('user'), lastOf('assistant'), text]
        .where((part) => part.isNotEmpty)
        .join('\n');
  }

  String _historicalTopic(String request, List<_ChatItem> previous) {
    var extra = request.toLowerCase();
    const strips = [
      'պատմական տվյալներ տուր',
      'պատմական տվյալներ տուր',
      'պատմական տվյալներ',
      'պատմական տուեալներ',
      'պատմական տվյալ',
      'պատմություն տուր',
      'պատմութիւն տուր',
      'տուր պատմական',
      'պատմական',
      'տվյալներ տուր',
      'տուեալներ տուր',
      'տվյալներ',
      'ժամանակաշրջան',
      'թվականներ',
      'թվական',
    ];
    for (final s in strips) {
      extra = extra.replaceAll(s, ' ');
    }
    extra = extra.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (extra.length >= 3) {
      return extra.length > 280 ? extra.substring(0, 280) : extra;
    }
    for (final item in previous.reversed) {
      if (item.role != 'user') continue;
      if (BibleContextRetriever.instance.wantsHistoricalFacts(item.text) &&
          _stripHistoricalAsk(item.text).length < 3) {
        continue;
      }
      final snippet = _stripHistoricalAsk(item.text);
      if (snippet.length < 3) continue;
      return snippet.length > 280 ? snippet.substring(0, 280) : snippet;
    }
    return request;
  }

  String _stripHistoricalAsk(String text) {
    var extra = text.toLowerCase();
    for (final s in [
      'պատմական տվյալներ տուր',
      'պատմական տվյալներ',
      'պատմական',
    ]) {
      extra = extra.replaceAll(s, ' ');
    }
    return extra.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleMine = isDark ? Colors.grey[800]! : Colors.grey[800]!;
    final bubbleAi = isDark ? const Color(0xFF1F1F1F) : Colors.grey[100]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Հոգևոր ԱԲ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          if (!SpiritualAiConfig.isConfigured)
            Material(
              color: Colors.orange.withValues(alpha: 0.18),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Backend-ը դեռ միացված չէ։ Գործարկեք server/ պանակի սերվերը և հավելվածը բացեք SPIRITUAL_AI_URL-ով։',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              children: [
                for (final item in _messages)
                  _MessageBubble(
                    item: item,
                    mineColor: bubbleMine,
                    aiColor: bubbleAi,
                    isDark: isDark,
                  ),
                if (_sending)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: bubbleAi,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      enabled: _indexReady && !_sending,
                      onSubmitted: (_) => _send(),
                      cursorColor: Colors.black,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: !_indexReady
                            ? 'Բեռնվում է Աստվածաշնչի տեքստը...'
                            : 'Գրեք հայերեն հարցը...',
                        hintStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  IconButton.filled(
                    onPressed: _indexReady && !_sending ? () => _send() : null,
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatItem item;
  final Color mineColor;
  final Color aiColor;
  final bool isDark;

  const _MessageBubble({
    required this.item,
    required this.mineColor,
    required this.aiColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = item.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.86,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUser ? mineColor : aiColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.text.isNotEmpty)
                SelectableText(
                  item.text,
                  style: TextStyle(
                    fontSize: 16,
                    color: isUser
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black),
                  ),
                ),
              if (!isUser && item.passages.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.passages.take(6).map((p) {
                    return ActionChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(p.displayRef, style: const TextStyle(fontSize: 12)),
                      onPressed: () => _openPassage(context, p),
                    );
                  }).toList(),
                ),
              ],
              if (!isUser && item.text.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'Պատճենել',
                    iconSize: 18,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: item.text));
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Պատճենվեց')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPassage(BuildContext context, BiblePassage passage) {
    final text = bibleText[passage.book]?[passage.chapter];
    if (text == null || text.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChapterTextScreen(
          bookName: passage.book,
          chapterNumber: passage.chapter,
          text: text,
          targetVerse: passage.verse,
        ),
      ),
    );
  }
}
