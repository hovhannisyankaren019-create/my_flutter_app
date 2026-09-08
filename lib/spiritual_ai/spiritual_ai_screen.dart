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
  final Uint8List? imageBytes;
  final List<String> imageUrls;

  const _ChatItem({
    required this.role,
    required this.text,
    this.passages = const [],
    this.imageBytes,
    this.imageUrls = const [],
  });
}

class _SpiritualAiScreenState extends State<SpiritualAiScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _service = SpiritualAiService();
  final _imageService = SpiritualImageService();
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
      final searchQuery = followUp ? _searchContext(text, previous) : text;
      final history = _apiHistory(previous, followUp: followUp);
      final treatAsVerseQuote = !retriever.wantsCommentary(text) &&
          !_isImageRequest(text) &&
          (retriever.quoteExplicitReferences(text).matched ||
              (!followUp && retriever.wantsVerseOnly(text)) ||
              (followUp && retriever.wantsMoreVerses(text)));
      final wantsLookupImage = !treatAsVerseQuote &&
          (_isImageRequest(text) || _isHistoricalImageRequest(text));
      if (wantsLookupImage) {
        final prompt = _imageSearchPrompt(text, previous);
        final askMessage =
            '$text\n\n(Համակարգ. նկարն ու քարտեզը հավելվածը կցուցադրի. դու միայն կարճ բացատրիր վայրը հայերենով և երբեք մի ասա, որ չես կարող նկար կամ քարտեզ տալ։)';
        List<SpiritualFoundImage> found = const [];
        var factsText = '';
        var sources = const <SpiritualFoundImage>[];
        Object? findError;
        SpiritualAiReply? reply;
        try {
          final lookup = await _imageService.findHistorical(
            prompt: prompt,
            exclude: _seenImageUrls(previous),
          );
          found = lookup.images.where((item) {
            final key = _imageKey(item.url);
            return !_seenImageUrls(previous)
                .map(_imageKey)
                .contains(key);
          }).toList();
          factsText = lookup.factsText;
          sources = lookup.sources;
        } catch (e) {
          findError = e;
        }
        final groundedAsk = factsText.isEmpty
            ? askMessage
            : '$askMessage\n\nԱղբյուրներ (պատմություն, քարտեզ, ժամանակաշրջան — պատասխանիր սրանցով, թվեր մի հորինիր).\n$factsText';
        try {
          reply = await _service.ask(
            message: groundedAsk,
            history: history,
            followUp: followUp,
            searchQuery: searchQuery,
          );
        } catch (_) {}
        if (!mounted) return;
        final replyText = _withoutRefusal(reply?.text ?? '');
        final caption = StringBuffer();
        if (replyText.isNotEmpty) {
          caption.writeln(replyText);
        }
        if (sources.isNotEmpty) {
          if (caption.isNotEmpty) caption.writeln();
          caption.writeln('Աղբյուրներ');
          for (final source in sources.take(4)) {
            final name = source.source.isNotEmpty ? source.source : source.title;
            caption.writeln('• $name: ${source.url}');
          }
        } else if (found.isNotEmpty) {
          if (caption.isNotEmpty) caption.writeln();
          caption.write(
            'Նկարներն ու քարտեզները վերցված են Google-ից և հանրային հավաստի աղբյուրներից, ոչ գեներացված են։',
          );
        }
        if (found.isEmpty && caption.isEmpty) {
          throw findError ??
              SpiritualImageException(
                'Համապատասխան նկար չգտնվեց հավաստի աղբյուրներում։ Գրեք ավելի կոնկրետ՝ վայր, տեսարան կամ քարտեզ։',
              );
        }
        setState(() {
          _messages.add(
            _ChatItem(
              role: 'assistant',
              text: caption.toString().trim(),
              passages: reply?.passages ?? const [],
              imageUrls: [for (final item in found.take(3)) item.url],
            ),
          );
        });
      } else {
        final reply = await _service.ask(
          message: text,
          history: history,
          followUp: followUp,
          searchQuery: searchQuery,
        );
        if (!mounted) return;
        final refusedImage = _looksLikeRefusal(reply.text) &&
            (reply.text.toLowerCase().contains('նկար') ||
                reply.text.toLowerCase().contains('գեներաց') ||
                reply.text.toLowerCase().contains('image') ||
                _isImageRequest(text));
        if (refusedImage) {
          final prompt = _imageSearchPrompt(text, previous);
          if (prompt.trim().isNotEmpty) {
            final lookup = await _imageService.findHistorical(
              prompt: prompt,
              exclude: _seenImageUrls(previous),
            );
            if (!mounted) return;
            final seenKeys = _seenImageUrls(previous).map(_imageKey).toSet();
            final urls = [
              for (final item in lookup.images)
                if (!seenKeys.contains(_imageKey(item.url))) item.url,
            ].take(3).toList();
            final caption = StringBuffer();
            if (lookup.sources.isNotEmpty) {
              caption.writeln('Աղբյուրներ');
              for (final source in lookup.sources.take(4)) {
                final name =
                    source.source.isNotEmpty ? source.source : source.title;
                caption.writeln('• $name: ${source.url}');
              }
            } else if (lookup.images.isNotEmpty) {
              caption.write(
                'Նկարները վերցված են Google-ից և հանրային հավաստի աղբյուրներից, ոչ գեներացված են։',
              );
            }
            setState(() {
              _messages.add(
                _ChatItem(
                  role: 'assistant',
                  text: caption.toString().trim(),
                  imageUrls: urls,
                ),
              );
            });
            return;
          }
        }
        setState(() {
          _messages.add(
            _ChatItem(
              role: 'assistant',
              text: reply.text,
              passages: reply.passages,
            ),
          );
        });
      }
    } on SpiritualImageException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatItem(role: 'assistant', text: e.message));
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

  bool _isHistoricalImageRequest(String text) {
    final t = text.toLowerCase().trim();
    const phrases = [
      'քարտեզ',
      'քարտէզ',
      'map',
      'հնագիտական',
      'հնավայր',
      'լուսանկար',
      'իրական նկար',
      'պատմական նկար',
      'պատմական քարտեզ',
      'գտիր նկար',
      'գտիր քարտեզ',
      'տրամադրել քարտեզ',
      'տուր քարտեզ',
      'կարող ես քարտեզ',
      'archaeolog',
      'historical map',
      'where was',
      'պատմական',
      'պատմություն',
      'ժամանակաշրջան',
      'թվական',
      'մ.թ.ա',
      'մ.թ.',
      'երբ էր',
      'երբ է եղել',
      'որ դարում',
      'chronolog',
    ];
    for (final phrase in phrases) {
      if (t.contains(phrase)) return true;
    }
    return _hasBiblicalPlace(t) &&
        (t.contains('որտեղ') ||
            t.contains('տեղը') ||
            t.contains('վայր') ||
            t.contains('երբ') ||
            t.contains('պատմ'));
  }

  bool _hasBiblicalPlace(String t) {
    const places = [
      'երիքով',
      'երուսաղեմ',
      'բեթղեհեմ',
      'գալիլեա',
      'նազարեթ',
      'կափառնաում',
      'հորդանան',
      'սինա',
      'եդեմ',
      'գողգոթա',
      'հեբրոն',
      'բաբելոն',
      'սուրբ երկիր',
      'jericho',
      'jerusalem',
      'bethlehem',
      'galilee',
      'nazareth',
    ];
    return places.any(t.contains);
  }

  bool _looksLikeRefusal(String text) {
    final t = text.toLowerCase();
    const phrases = [
      'չեմ կարող',
      'չկարողանամ',
      'չեմ տրամադր',
      'չեմ կարողանում',
      'չեմ գեներաց',
      'չեմ ուղարկ',
      'cannot provide',
      "can't provide",
      'unable to provide',
      'cannot generate',
      "can't generate",
      'cannot send',
      'նկարներ կամ քարտեզներ',
    ];
    return phrases.any(t.contains);
  }

  String _withoutRefusal(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _looksLikeRefusal(trimmed)) return '';
    return trimmed;
  }

  bool _isImageRequest(String text) {
    final t = text.toLowerCase().trim();
    if (t.contains('պատկերաց')) return false;
    if (t.contains('նկարագր') &&
        !t.contains('նկարով') &&
        !t.contains('նկարիր') &&
        !t.contains('նկարը') &&
        !t.contains('նկարներ')) {
      return false;
    }
    const phrases = [
      'նկարով պատկեր',
      'նկարով ցույց',
      'նկարով տուր',
      'պատկերիր',
      'պատկերի',
      'պատկերով',
      'նկարիր',
      'նկարել',
      'նկարը տուր',
      'նկար տուր',
      'նկարներ',
      'նկար ուղարկ',
      'ուղարկիր նկար',
      'ուղարկել նկար',
      'կարող ես նկար',
      'նկար ստեղծ',
      'նկար գեներաց',
      'գեներացրու',
      'գեներացնել',
      'մի նկար',
      'որպես նկար',
      'նկարի տեսք',
      'show as image',
      'show a picture',
      'draw this',
      'generate image',
      'make an image',
      'send an image',
      'send a picture',
    ];
    for (final phrase in phrases) {
      if (t.contains(phrase)) return true;
    }
    if (t.contains('նկար')) return true;
    return RegExp(r'(^|[^ա-ֆԱ-Ֆ])նկար([^ա-ֆԱ-Ֆ]|$)').hasMatch(t);
  }

  List<String> _seenImageUrls(List<_ChatItem> messages) {
    return [
      for (final item in messages)
        for (final url in item.imageUrls)
          if (url.isNotEmpty) url,
    ];
  }

  String _imageKey(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) {
      return url.split('?').first.toLowerCase();
    }
    return '${uri.host}${uri.path}'.toLowerCase();
  }

  String _stripImageVerbs(String request) {
    var extra = request;
    const strips = [
      'նկարով պատկերիր',
      'նկարով պատկերի',
      'նկարով ցույց տուր',
      'նկարով տուր',
      'պատկերիր',
      'պատկերի',
      'նկարիր',
      'նկար գեներացրու',
      'գեներացրու նկար',
      'նկար ստեղծիր',
      'նկարը տուր',
      'նկար տուր',
      'էլի նկարներ',
      'էլի նկար',
      'ուրիշ նկարներ',
      'ուրիշ նկար',
      'այլ նկարներ',
      'այլ նկար',
      'նոր նկարներ',
      'նոր նկար',
      'կրկին նկար',
      'show as image',
      'show a picture',
      'generate image',
      'draw this',
      'make an image',
      'another picture',
      'more pictures',
      'more images',
    ];
    for (final phrase in strips) {
      extra = extra.replaceAll(
        RegExp(RegExp.escape(phrase), caseSensitive: false),
        ' ',
      );
    }
    extra = extra.replaceAll(
      RegExp(r'(^|[^\p{L}])նկար(ներ)?([^\p{L}]|$)', unicode: true),
      r'$1$3',
    );
    extra = extra.replaceAll(RegExp(r'\s+'), ' ').trim();
    return extra;
  }

  bool _isThinImageTopic(String text) {
    final t = text.toLowerCase().trim();
    if (t.length < 3) return true;
    const thin = {
      'էլի',
      'ուրիշ',
      'այլ',
      'նորից',
      'կրկին',
      'please',
      'more',
      'again',
      'another',
    };
    return thin.contains(t);
  }

  String _imageSearchPrompt(String request, List<_ChatItem> previous) {
    final current = _stripImageVerbs(request);
    if (current.isNotEmpty && !_isThinImageTopic(current)) {
      return current.length > 280 ? current.substring(0, 280) : current;
    }
    for (final item in previous.reversed) {
      if (item.role != 'user') continue;
      final snippet = _stripImageVerbs(item.text);
      if (snippet.isEmpty || _isThinImageTopic(snippet)) continue;
      return snippet.length > 280 ? snippet.substring(0, 280) : snippet;
    }
    if (current.isNotEmpty) return current;
    return request;
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
              if (item.imageBytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    item.imageBytes!,
                    fit: BoxFit.cover,
                  ),
                ),
                if (item.text.isNotEmpty || item.imageUrls.isNotEmpty)
                  const SizedBox(height: 8),
              ],
              for (var i = 0; i < item.imageUrls.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: i == 0 ? 4 / 3 : 16 / 10,
                    child: Image.network(
                      item.imageUrls[i],
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.high,
                      headers: const {
                        'User-Agent':
                            'AraratBible/1.0 (biblical education; image display)',
                        'Accept': 'image/jpeg,image/png,image/webp,*/*',
                      },
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return ColoredBox(
                          color: Colors.black12,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Color(0x11000000),
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('Նկարը չբացվեց։'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (item.imageUrls.isNotEmpty) const SizedBox(height: 8),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
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
                    ],
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
