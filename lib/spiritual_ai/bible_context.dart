import '../main.dart';

class BiblePassage {
  final String book;
  final int chapter;
  final int verse;
  final String text;

  const BiblePassage({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
  });

  String get ref => '$book $chapter:$verse';

  Map<String, String> toJson() => {
        'ref': ref,
        'book': book,
        'chapter': '$chapter',
        'verse': '$verse',
        'text': text,
      };
}

class _IndexedVerse {
  final String book;
  final int chapter;
  final int verse;
  final String original;
  final String normalized;

  const _IndexedVerse({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.original,
    required this.normalized,
  });
}

/// Looks up verses from the in-app Ararat text so the model can ground answers.
class BibleContextRetriever {
  BibleContextRetriever._();
  static final BibleContextRetriever instance = BibleContextRetriever._();

  List<_IndexedVerse>? _index;
  late final List<MapEntry<String, String>> _bookNames;

  static const _stopwords = {
    'ինչ',
    'ինչպես',
    'ինչու',
    'որտեղ',
    'երբ',
    'ով',
    'որ',
    'թե',
    'և',
    'ու',
    'կամ',
    'այս',
    'այն',
    'մասին',
    'համար',
    'կարող',
    'ասում',
    'ասել',
    'խնդրում',
    'բացատրիր',
    'ասա',
    'խնդրեմ',
    'հարց',
    'աստվածաշունչ',
    'աստվածաշնչում',
    'աստվածաշնչի',
    'գիրք',
    'գրքում',
    'համարում',
    'համարը',
    'համարներ',
    'համարները',
    'համարների',
    'տուր',
    'տվեք',
    'ցույց',
    'գտիր',
    'կարդա',
    'թեմա',
    'թեմայի',
    'խոսքեր',
  };

  static const _synonyms = [
    ['աստված', 'աստծո', 'աստուծոյ', 'աստծու', 'աստծոյ', 'տէր', 'տերոջ'],
    ['սեր', 'սէր', 'սիրո', 'սիրել', 'սիրեց', 'սիրում', 'սիրելով', 'սիրով'],
    ['հաւատ', 'հավատ', 'հաւատք', 'հավատք', 'հաւատում'],
    ['աղօթ', 'աղոթ', 'աղօթք', 'աղոթք', 'աղաչել'],
    ['փրկութ', 'փրկություն', 'փրկիչ', 'փրկել'],
    ['յիսուս', 'հիսուս', 'քրիստոս'],
  ];

  static const _aliases = {
    'Հովհաննես': 'Յովհաննէս',
    'Հովհաննէս': 'Յովհաննէս',
    'Յովհաննես': 'Յովհաննէս',
    'Հովհաննու': 'Յովհաննէս',
    'Մատթեոս': 'Մատթէոս',
    'Մարկոսի': 'Մարկոս',
    'Ղուկասի': 'Ղուկաս',
    'Սաղմոսներ': 'Սաղմոս',
    'Սաղմոսաց': 'Սաղմոս',
    'Ծննդոց գիրք': 'Ծննդոց',
    'Ծնունդ': 'Ծննդոց',
    'Ելք': 'Ելից',
    'Ղևտական': 'Ղևտացոց',
    'Թվեր': 'Թուոց',
    'Երկրորդ Օրենք': 'Երկրորդ Օրինաց',
    'Հեսու': 'Յեսու',
    'Դատավորներ': 'Դատաւորաց',
    'Հռութի': 'Հռութ',
    'Ա Թագավորաց': 'Ա Թագաւորաց',
    'Բ Թագավորաց': 'Բ Թագաւորաց',
    'Գ Թագավորաց': 'Գ Թագաւորաց',
    'Դ Թագավորաց': 'Դ Թագաւորաց',
    'Հոբ': 'Յոբ',
    'Առակներ': 'Առակաց',
    'Եսայի': 'Եսայիա',
    'Երեմիայի ողբ': 'Ողբ Երեմիայի',
    'Եզեկիել': 'Եզեկիէլ',
    'Դանիել': 'Դանիէլ',
    'Հովսե': 'Ովսէ',
    'Հովել': 'Հովէլ',
    'Ամոս': 'Ամովս',
    'Հովնան': 'Յովնան',
    'Միքիա': 'Միքիա',
    'Նաում': 'Նաում',
    'Հաբակում': 'Ամբակում',
    'Սոֆոնիա': 'Սոփոնիա',
    'Անգե': 'Անգէ',
    'Զաքարիա': 'Զաքարիա',
    'Մաղաքիա': 'Մաղաքիա',
    'Գործք': 'Գործք Առաքելոց',
    'Գործք առաքելոց': 'Գործք Առաքելոց',
    'Հռոմեացիս': 'Հռովմայեցիս',
    'Հռոմայեցիս': 'Հռովմայեցիս',
    'Ա Կորնթացիներ': 'Ա Կորնթացիս',
    'Բ Կորնթացիներ': 'Բ Կորնթացիս',
    'Գաղատացիներ': 'Գաղատացիս',
    'Եփեսացիներ': 'Եփեսացիս',
    'Փիլիպպեցիներ': 'Փիլիպպեցիս',
    'Կողոսացիներ': 'Կողոսացիս',
    'Եբրայեցիներ': 'Եբրայեցիս',
    'Հակոբոս': 'Յակոբոս',
    'Ա Հովհաննես': 'Ա Յովհաննէս',
    'Բ Հովհաննես': 'Բ Յովհաննէս',
    'Գ Հովհաննես': 'Գ Յովհաննէս',
    'Հուդա': 'Յուդա',
    'Հայտնություն': 'Յայտնութիւն',
    'Հայտնութիւն': 'Յայտնութիւն',
    'Յայտնություն': 'Յայտնութիւն',
  };

  void ensureReady() {
    if (_index != null) return;
    _bookNames = _buildBookNames();
    final index = <_IndexedVerse>[];
    bibleText.forEach((book, chapters) {
      chapters.forEach((chapterNum, text) {
        final verses = VerseHelper.parseVerses(text);
        verses.forEach((verseNum, verseText) {
          final trimmed = verseText.trim();
          if (trimmed.isEmpty) return;
          index.add(
            _IndexedVerse(
              book: book,
              chapter: chapterNum,
              verse: verseNum,
              original: trimmed,
              normalized: TransliterationHelper.normalizeForSearch(trimmed),
            ),
          );
        });
      });
    });
    _index = index;
  }

  List<MapEntry<String, String>> _buildBookNames() {
    final map = <String, String>{};
    for (final name in chapterCounts.keys) {
      map[name] = name;
    }
    _aliases.forEach((alias, canonical) {
      if (chapterCounts.containsKey(canonical)) {
        map[alias] = canonical;
      }
    });
    final entries = map.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    return entries;
  }

  List<BiblePassage> passagesForQuestion(String question, {int limit = 6}) {
    ensureReady();
    final found = <String, BiblePassage>{};

    for (final passage in _passagesFromReferences(question)) {
      found[passage.ref] = passage;
    }

    if (found.length >= limit) {
      return found.values.take(limit).toList();
    }

    for (final passage in _passagesFromKeywords(question, limit: limit)) {
      found.putIfAbsent(passage.ref, () => passage);
      if (found.length >= limit) break;
    }

    return found.values.take(limit).toList();
  }

  List<BiblePassage> _passagesFromReferences(String question) {
    final results = <BiblePassage>[];
    final q = question;
    for (final entry in _bookNames) {
      final name = entry.key;
      final book = entry.value;
      final escaped = RegExp.escape(name);
      final pattern = RegExp(
        '$escaped\\s*(\\d+)\\s*(?:[:։.]\\s*(\\d+))?(?:\\s*[-–]\\s*(\\d+))?',
        caseSensitive: false,
      );
      for (final match in pattern.allMatches(q)) {
        final chapter = int.tryParse(match.group(1) ?? '');
        if (chapter == null) continue;
        final startVerse = int.tryParse(match.group(2) ?? '');
        final endVerse = int.tryParse(match.group(3) ?? '');
        results.addAll(
          _lookupRange(
            book: book,
            chapter: chapter,
            startVerse: startVerse,
            endVerse: endVerse ?? startVerse,
          ),
        );
      }
    }
    return results;
  }

  List<BiblePassage> _lookupRange({
    required String book,
    required int chapter,
    int? startVerse,
    int? endVerse,
  }) {
    final chapterText = bibleText[book]?[chapter];
    if (chapterText == null || chapterText.isEmpty) return const [];
    final verses = VerseHelper.parseVerses(chapterText);
    if (verses.isEmpty) return const [];

    if (startVerse == null) {
      final keys = verses.keys.toList()..sort();
      return keys.take(12).map((n) {
        return BiblePassage(
          book: book,
          chapter: chapter,
          verse: n,
          text: verses[n]!,
        );
      }).toList();
    }

    final from = startVerse;
    final to = (endVerse == null || endVerse < from) ? from : endVerse;
    final out = <BiblePassage>[];
    for (var n = from; n <= to && out.length < 12; n++) {
      final text = verses[n];
      if (text == null || text.trim().isEmpty) continue;
      out.add(
        BiblePassage(
          book: book,
          chapter: chapter,
          verse: n,
          text: text,
        ),
      );
    }
    return out;
  }

  List<Set<String>> _queryConcepts(String question) {
    final tokens = TransliterationHelper.normalizeForSearch(question)
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= 3 && !_stopwords.contains(t))
        .toList();
    return tokens.map(_needlesFor).toList();
  }

  Set<String> _needlesFor(String token) {
    final needles = <String>{token};
    if (token.length >= 4) {
      needles.add(token.substring(0, 4));
    }
    for (final group in _synonyms) {
      final hit = group.any(
        (g) => token.contains(g) || g.contains(token),
      );
      if (hit) needles.addAll(group);
    }
    return needles.where((n) => n.length >= 3).toSet();
  }

  bool _matchesConcept(String haystack, Set<String> needles) {
    for (final needle in needles) {
      if (haystack.contains(needle)) return true;
    }
    return false;
  }

  List<BiblePassage> _passagesFromKeywords(String question, {required int limit}) {
    final index = _index ?? const <_IndexedVerse>[];
    final concepts = _queryConcepts(question);
    if (concepts.isEmpty) return const [];

    final requiredHits = concepts.length >= 2 ? concepts.length : 1;
    final scored = <_ScoredVerse>[];

    for (final verse in index) {
      var hits = 0;
      var score = 0.0;
      for (final needles in concepts) {
        if (_matchesConcept(verse.normalized, needles)) {
          hits += 1;
          score += 8;
        }
      }
      if (hits < requiredHits) continue;
      scored.add(_ScoredVerse(verse, score + hits));
    }

    if (scored.isEmpty) return const [];
    scored.sort((a, b) => b.score.compareTo(a.score));
    final best = scored.first.score;
    return scored
        .where((s) => s.score >= best * 0.65)
        .take(limit)
        .map((s) {
          return BiblePassage(
            book: s.verse.book,
            chapter: s.verse.chapter,
            verse: s.verse.verse,
            text: s.verse.original,
          );
        })
        .toList();
  }
}

class _ScoredVerse {
  final _IndexedVerse verse;
  final double score;
  _ScoredVerse(this.verse, this.score);
}
