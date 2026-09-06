import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
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
  final _messages = <_ChatItem>[];
  bool _sending = false;
  bool _indexReady = false;

  static const _suggestions = [
    'Ի՞նչ է ասում Աստվածաշունչը սիրո մասին',
    'Ինչպե՞ս աղոթել դժվարության մեջ',
    'Ո՞վ է Հիսուս Քրիստոսը ըստ Ավետարանի',
  ];

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

    final previous = _messages.sublist(0, _messages.length - 1);
    final start = previous.length > 8 ? previous.length - 8 : 0;
    final history = [
      for (final item in previous.sublist(start))
        {'role': item.role, 'content': item.text},
    ];

    try {
      final reply = await _service.ask(message: text, history: history);
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatItem(
            role: 'assistant',
            text: reply.text,
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
                Text(
                  'Հարցրեք հայերենով Աստվածաշնչի մասին։ Պատասխանները հիմնվում են հավելվածի տեքստի վրա և չեն հորինում համարներ։',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                if (_messages.isEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestions.map((s) {
                      return ActionChip(
                        label: Text(s, style: const TextStyle(fontSize: 13)),
                        onPressed: _indexReady && !_sending ? () => _send(s) : null,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
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
                      decoration: InputDecoration(
                        hintText: _indexReady
                            ? 'Գրեք ձեր հարցը...'
                            : 'Բեռնվում է Աստվածաշնչի տեքստը...',
                        filled: true,
                        fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
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
                  const SizedBox(width: 8),
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
                      label: Text(p.ref, style: const TextStyle(fontSize: 12)),
                      onPressed: () => _openPassage(context, p),
                    );
                  }).toList(),
                ),
              ],
              if (!isUser)
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
