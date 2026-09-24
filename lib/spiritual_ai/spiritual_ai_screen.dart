import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../firebase/chat_firestore_service.dart';
import '../firebase/chat_history_screen.dart';
import '../firebase/firebase_auth_service.dart';
import '../main.dart';
import 'bible_context.dart';
import 'spiritual_ai_config.dart';
import 'spiritual_ai_service.dart';

class SpiritualAiScreen extends StatefulWidget {
  final String? chatId;
  final bool isGuest;
  final bool embedded;
  final String? initialQuestion;
  final VoidCallback? onRequestAccount;

  const SpiritualAiScreen({
    super.key,
    this.chatId,
    this.isGuest = false,
    this.embedded = false,
    this.initialQuestion,
    this.onRequestAccount,
  });

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

final FirebaseAuthService _authService = FirebaseAuthService();

class _SpiritualAiScreenState extends State<SpiritualAiScreen> {
  bool get _isGuest => widget.isGuest;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _service = SpiritualAiService();
  final _messages = <_ChatItem>[];
  bool _sending = false;
  bool _indexReady = false;
  ChatFirestoreService? _chatFirestoreService;
  String? _chatId;

  ChatFirestoreService get _chats {
    return _chatFirestoreService ??= ChatFirestoreService();
  }

  @override
  void initState() {
    super.initState();
    _chatId = widget.chatId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_chatId != null) {
        await _loadChatMessages();
      }
      if (mounted) setState(() => _indexReady = true);
      final question = widget.initialQuestion?.trim();
      if (question != null && question.isNotEmpty && mounted) {
        await _send(question);
      }
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

    if (!_isGuest && _chatId == null) {
      try {
        final chatId = await _chats.createChat(
          title: text.length > 40 ? '${text.substring(0, 40)}...' : text,
        );
        _chatId = chatId;
      } catch (_) {
        // Firebase-ի սխալը չպետք է կանգնեցնի ԱԲ-ի աշխատանքը
      }
    }

    setState(() {
      _sending = true;
      _messages.add(_ChatItem(role: 'user', text: text));
      _controller.clear();
    });
    if (!_isGuest && _chatId != null) {
      try {
        await _chats.saveMessage(
          chatId: _chatId!,
          text: text,
          role: 'user',
        );
      } catch (_) {}
    }
    _scrollToEnd();

    try {
      final retriever = BibleContextRetriever.instance;
      await retriever.ensureReady();
      final previous = _messages.sublist(0, _messages.length - 1);
      var lastUserText = '';
      for (final item in previous.reversed) {
        if (item.role == 'user') {
          lastUserText = item.text;
          break;
        }
      }
      final verseFollow = retriever.looksLikeVerseFollowUp(text);
      final followUp = verseFollow ||
          retriever.looksLikeFollowUp(
            text,
            hasPriorTurn: previous.any((item) => item.role == 'assistant'),
            previousUser: lastUserText,
          );
      final wantsHistory = retriever.wantsRestrictedSources(text);
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
      final searchQuery = verseFollow ? _searchContext(text, previous) : text;
      final history = _apiHistory(
        previous,
        followUp: followUp,
      );

      var askText = text;
      if (wantsHistory) {
        askText =
            '$text\n\n(Համակարգ. տուր լիարժեք հոգևոր պատասխան տարբեր աղբյուրներով՝ Աստվածաշունչ, մեկնություններ, Սուրբ Հայրեր և այլ հոգևոր գրքեր։ Կարճ մի գրիր։)';
      }

      final reply = await _service.ask(
        message: askText,
        history: history,
        followUp: followUp,
        searchQuery: searchQuery,
      );
      if (!mounted) return;
      final body = reply.text.trim();
      setState(() {
        _messages.add(
          _ChatItem(
            role: 'assistant',
            text: body,
            passages: reply.passages,
          ),
        );
      });
      if (!_isGuest && _chatId != null) {
        try {
          await _chats.saveMessage(
            chatId: _chatId!,
            text: body,
            role: 'assistant',
          );
        } catch (_) {}
      }
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

  Future<void> _loadChatMessages() async {
    if (_chatId == null) return;

    try {
      final snapshot =
          await _chats.streamMessages(_chatId!).first;

      final loadedMessages = <_ChatItem>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final role = data['role'] as String? ?? 'assistant';
        final text = data['text'] as String? ?? '';
        if (text.isEmpty) continue;
        loadedMessages.add(
          _ChatItem(
            role: role,
            text: text,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(loadedMessages);
      });
      _scrollToEnd();
    } catch (e) {
      debugPrint('Error loading chat messages: $e');
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

  void _startNewChat() {
    if (_sending) return;
    FocusScope.of(context).unfocus();
    _controller.clear();
    setState(() {
      _chatId = null;
      _messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleMine = isDark ? const Color(0xFF9AA090) : AppColors.forest;
    final bubbleAi = isDark ? AppColors.darkForest : AppColors.lightChip;

    return Scaffold(
      backgroundColor: AppColors.bg(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.bg(isDark),
        title: Text(
          'ԱԲ',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppColors.text(isDark),
          ),
        ),
        centerTitle: false,
        automaticallyImplyLeading: !widget.embedded,
        leading: widget.embedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
        actions: [
          if (_isGuest && widget.onRequestAccount != null)
            IconButton(
              tooltip: 'Մուտք / Գրանցում',
              icon: Icon(
                Icons.person_outline,
                color: AppColors.text(isDark),
              ),
              onPressed: widget.onRequestAccount,
            ),
          IconButton(
            tooltip: 'Նոր նամակագրություն',
            icon: Icon(
              Icons.edit_outlined,
              color: AppColors.text(isDark),
            ),
            onPressed: _sending ? null : _startNewChat,
          ),
          if (!_isGuest)
            IconButton(
              tooltip: 'Նախորդ զրույցներ',
              icon: const Icon(Icons.history),
              onPressed: () async {
                final startNew = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChatHistoryScreen(),
                  ),
                );
                if (startNew == true && mounted) {
                  _startNewChat();
                }
              },
            ),
          if (!_isGuest)
            IconButton(
              tooltip: 'Դուրս գալ',
              icon: const Icon(Icons.logout),
              onPressed: () async {
                try {
                  await _authService.logout();
                } catch (_) {}
                if (!context.mounted) return;
                if (!widget.embedded) {
                  Navigator.popUntil(context, (route) => route.isFirst);
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (!SpiritualAiConfig.isConfigured)
            Material(
              color: AppColors.olive.withValues(alpha: 0.22),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Backend-ը դեռ միացված չէ։ Գործարկեք server/ պանակի սերվերը և հավելվածը բացեք SPIRITUAL_AI_URL-ով։',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          Expanded(
            child: _messages.isEmpty && !_sending
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 42,
                            color: isDark ? AppColors.darkOlive : AppColors.olive,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Հարցրեք Աստվածաշնչի մասին',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: bubbleAi,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: isDark
                                      ? AppColors.cream
                                      : AppColors.forest,
                                ),
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
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
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
                      cursorColor: AppColors.forest,
                      style: TextStyle(
                        color: AppColors.text(isDark),
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: !_indexReady
                            ? 'Բեռնվում է Աստվածաշնչի տեքստը...'
                            : 'Հարց...',
                        hintStyle: TextStyle(
                          color: AppColors.muted(isDark),
                          fontSize: 16,
                        ),
                        filled: true,
                        fillColor:
                            isDark ? AppColors.darkForest : AppColors.lightChip,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
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
                    icon: const Icon(Icons.send_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          isDark ? AppColors.darkForest : AppColors.forest,
                      foregroundColor: AppColors.cream,
                      disabledBackgroundColor: AppColors.olive,
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
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 6),
              bottomRight: Radius.circular(isUser ? 6 : 18),
            ),
            border: isUser
                ? null
                : Border.all(
                    color: isDark
                        ? AppColors.olive.withValues(alpha: 0.35)
                        : AppColors.olive.withValues(alpha: 0.28),
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.text.isNotEmpty)
                SelectableText(
                  item.text,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    color: isUser
                        ? (isDark ? AppColors.darkForest : AppColors.cream)
                        : AppColors.text(isDark),
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
                      backgroundColor:
                          isDark ? AppColors.olive : AppColors.lightChip,
                      label: Text(
                        p.displayRef,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.text(isDark),
                        ),
                      ),
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
                    icon: Icon(
                      Icons.copy,
                      color: AppColors.muted(isDark),
                    ),
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
          autoClearFramesAfter: const Duration(seconds: 2),
        ),
      ),
    );
  }
}
