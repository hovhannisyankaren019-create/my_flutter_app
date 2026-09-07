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

  static String displayBook(String book) {
    const names = {
      'Յեսու': 'Հեսու',
      'Դատաւորաց': 'Դատավորաց',
      'Ա Թագաւորաց': 'Ա Թագավորաց',
      'Բ Թագաւորաց': 'Բ Թագավորաց',
      'Գ Թագաւորաց': 'Գ Թագավորաց',
      'Դ Թագաւորաց': 'Դ Թագավորաց',
      'Նէեմիա': 'Նեեմիա',
      'Յոբ': 'Հոբ',
      'Եզեկիէլ': 'Եզեկիել',
      'Դանիէլ': 'Դանիել',
      'Ովսէ': 'Հովսե',
      'Հովէլ': 'Հովել',
      'Յովնան': 'Հովնան',
      'Անգէ': 'Անգե',
      'Մատթէոս': 'Մատթեոս',
      'Յովհաննէս': 'Հովհաննես',
      'Ա Յովհաննէս': 'Ա Հովհաննես',
      'Բ Յովհաննէս': 'Բ Հովհաննես',
      'Գ Յովհաննէս': 'Գ Հովհաննես',
      'Հռովմայեցիս': 'Հռոմեացիս',
      'Ա Տիմոթէոս': 'Ա Տիմոթեոս',
      'Բ Տիմոթէոս': 'Բ Տիմոթեոս',
      'Յակոբոս': 'Հակոբոս',
      'Յուդա': 'Հուդա',
      'Յայտնութիւն': 'Հայտնություն',
    };
    return names[book] ?? book;
  }

  String get displayRef => '${displayBook(book)} $chapter։$verse';

  Map<String, String> toJson() => {
        'ref': displayRef,
        'book': book,
        'chapter': '$chapter',
        'verse': '$verse',
        'text': text,
      };
}

class _RefSpec {
  final String book;
  final int chapter;
  final int? startVerse;
  final int? endVerse;

  const _RefSpec({
    required this.book,
    required this.chapter,
    this.startVerse,
    this.endVerse,
  });
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
    ['իրեններ', 'իրաններ', 'իրանց', 'իւրեանց'],
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
    'Հովհաննեսի': 'Յովհաննէս',
    'Մատթեոս': 'Մատթէոս',
    'Մատթէոսի': 'Մատթէոս',
    'Մատթեոսի': 'Մատթէոս',
    'Մարկոսի': 'Մարկոս',
    'Ղուկասի': 'Ղուկաս',
    'Սաղմոսներ': 'Սաղմոս',
    'Սաղմոսաց': 'Սաղմոս',
    'Սաղմոսի': 'Սաղմոս',
    'Ծննդոց գիրք': 'Ծննդոց',
    'Ծնունդ': 'Ծննդոց',
    'Ծննդոցի': 'Ծննդոց',
    'Ելք': 'Ելից',
    'Ելիցի': 'Ելից',
    'Ղևտական': 'Ղևտացոց',
    'Ղեւտական': 'Ղևտացոց',
    'Ղևիտական': 'Ղևտացոց',
    'Ղեւտացոց': 'Ղևտացոց',
    'Թվեր': 'Թուոց',
    'Թւեր': 'Թուոց',
    'Երկրորդ Օրենք': 'Երկրորդ Օրինաց',
    'Երկրորդ օրենք': 'Երկրորդ Օրինաց',
    'Բ Օրենք': 'Երկրորդ Օրինաց',
    'Հեսու': 'Յեսու',
    'Հեսուի': 'Յեսու',
    'Դատավորներ': 'Դատաւորաց',
    'Դատավորաց': 'Դատաւորաց',
    'Դատաւորներ': 'Դատաւորաց',
    'Հռութի': 'Հռութ',
    'Ռութ': 'Հռութ',
    'Ա Թագավորաց': 'Ա Թագաւորաց',
    'Բ Թագավորաց': 'Բ Թագաւորաց',
    'Գ Թագավորաց': 'Գ Թագաւորաց',
    'Դ Թագավորաց': 'Դ Թագաւորաց',
    'Ա Թագավորներ': 'Ա Թագաւորաց',
    'Բ Թագավորներ': 'Բ Թագաւորաց',
    'Գ Թագավորներ': 'Գ Թագաւորաց',
    'Դ Թագավորներ': 'Դ Թագաւորաց',
    'Ա Թագաւորներ': 'Ա Թագաւորաց',
    'Բ Թագաւորներ': 'Բ Թագաւորաց',
    'Գ Թագաւորներ': 'Գ Թագաւորաց',
    'Դ Թագաւորներ': 'Դ Թագաւորաց',
    'Ա Մնացորդներ': 'Ա Մնացորդաց',
    'Բ Մնացորդներ': 'Բ Մնացորդաց',
    'Եզրա': 'Եզրաս',
    'Նեեմիա': 'Նէեմիա',
    'Նէեմիայի': 'Նէեմիա',
    'Հոբ': 'Յոբ',
    'Հոբի': 'Յոբ',
    'Առակներ': 'Առակաց',
    'Առակաց գիրք': 'Առակաց',
    'Ժողովողի': 'Ժողովող',
    'Երգոց': 'Երգ Երգոց',
    'Երգեր': 'Երգ Երգոց',
    'Երգ երգոց': 'Երգ Երգոց',
    'Եսայի': 'Եսայիա',
    'Եսայա': 'Եսայիա',
    'Երեմիայի ողբ': 'Ողբ Երեմիայի',
    'Ողբ': 'Ողբ Երեմիայի',
    'Եզեկիել': 'Եզեկիէլ',
    'Եզեկիլ': 'Եզեկիէլ',
    'Դանիել': 'Դանիէլ',
    'Հովսե': 'Ովսէ',
    'Հովսէ': 'Ովսէ',
    'Ովսե': 'Ովսէ',
    'Հովել': 'Հովէլ',
    'Ամոս': 'Ամովս',
    'Հովնան': 'Յովնան',
    'Հովնանի': 'Յովնան',
    'Հաբակում': 'Ամբակում',
    'Սոֆոնիա': 'Սոփոնիա',
    'Անգե': 'Անգէ',
    'Գործք': 'Գործք Առաքելոց',
    'Գործք առաքելոց': 'Գործք Առաքելոց',
    'Առաքելոց': 'Գործք Առաքելոց',
    'Հռոմեացիս': 'Հռովմայեցիս',
    'Հռոմայեցիս': 'Հռովմայեցիս',
    'Հռոմեացիներ': 'Հռովմայեցիս',
    'Հռովմայեցիներ': 'Հռովմայեցիս',
    'Ա Կորնթացիներ': 'Ա Կորնթացիս',
    'Բ Կորնթացիներ': 'Բ Կորնթացիս',
    'Գաղատացիներ': 'Գաղատացիս',
    'Եփեսացիներ': 'Եփեսացիս',
    'Փիլիպպեցիներ': 'Փիլիպպեցիս',
    'Կողոսացիներ': 'Կողոսացիս',
    'Ա Թեսաղոնիկեցիներ': 'Ա Թեսաղոնիկեցիս',
    'Բ Թեսաղոնիկեցիներ': 'Բ Թեսաղոնիկեցիս',
    'Ա Տիմոթեոս': 'Ա Տիմոթէոս',
    'Բ Տիմոթեոս': 'Բ Տիմոթէոս',
    'Եբրայեցիներ': 'Եբրայեցիս',
    'Հակոբոս': 'Յակոբոս',
    'Հակոբոսի': 'Յակոբոս',
    'Ա Հովհաննես': 'Ա Յովհաննէս',
    'Բ Հովհաննես': 'Բ Յովհաննէս',
    'Գ Հովհաննես': 'Գ Յովհաննէս',
    'Ա Հովհաննէս': 'Ա Յովհաննէս',
    'Բ Հովհաննէս': 'Բ Յովհաննէս',
    'Գ Հովհաննէս': 'Գ Յովհաննէս',
    'Հուդա': 'Յուդա',
    'Հայտնություն': 'Յայտնութիւն',
    'Հայտնութիւն': 'Յայտնութիւն',
    'Յայտնություն': 'Յայտնութիւն',
    'Ապոկալիպսիս': 'Յայտնութիւն',
  };

  static const _famousQuotes = <List<Object>>[
    [
      ['սիրեց իրեններին', 'սիրեց իրաններին', 'մինչեւ վերջը սիրեց', 'մինչև վերջը սիրեց', 'իրաններին սիրեց'],
      'Յովհաննէս',
      13,
      1,
    ],
    [
      ['այնպես սիրեց աշխարհը', 'այնպէս սիրեց աշխարհը', 'միածին որդին'],
      'Յովհաննէս',
      3,
      16,
    ],
    [
      ['ես եմ ճանապարհը', 'ճանապարհը եւ ճշմարտութիւնը'],
      'Յովհաննէս',
      14,
      6,
    ],
    [
      ['նոր պատուիրանք', 'իրար սիրէք'],
      'Յովհաննէս',
      13,
      34,
    ],
    [
      ['աստված սեր է', 'աստուած սէր է'],
      'Ա Յովհաննէս',
      4,
      8,
    ],
    [
      [
        'տէրն է իմ հովիւը',
        'տերն է իմ հովիվը',
        'տէրն իմ հովիւն է',
        'կարօտութիւն չեմ ունենալ',
        'ոչ մի բան պակաս',
      ],
      'Սաղմոս',
      23,
      1,
    ],
    [
      ['սկզբում էր բանը', 'սկիզբը էր բանը', 'սկզբումն էր բանը'],
      'Յովհաննէս',
      1,
      1,
    ],
    [
      ['ամեն բան կարող եմ', 'ամէն բան կարող եմ'],
      'Փիլիպպեցիս',
      4,
      13,
    ],
    [
      ['գնացէք աշակերտեցրէք', 'գնացեք աշակերտեցրեք'],
      'Մատթէոս',
      28,
      19,
    ],
  ];

  static const _topics = <List<Object>>[
    [
      ['սեր', 'սէր', 'սիրո', 'սիրել', 'սիրում', 'սիրեց', 'սիրով'],
      [
        ['Յովհաննէս', 3, 16],
        ['Ա Յովհաննէս', 4, 8],
        ['Ա Կորնթացիս', 13, 4],
        ['Յովհաննէս', 13, 34],
        ['Յովհաննէս', 15, 13],
        ['Մատթէոս', 22, 37],
        ['Հռովմայեցիս', 5, 8],
      ],
    ],
    [
      ['աղոթ', 'աղօթ', 'աղաչ'],
      [
        ['Մատթէոս', 6, 6],
        ['Մատթէոս', 6, 9],
        ['Փիլիպպեցիս', 4, 6],
        ['Ա Թեսաղոնիկեցիս', 5, 17],
        ['Յակոբոս', 5, 16],
      ],
    ],
    [
      ['հավատ', 'հաւատ', 'հաւատք'],
      [
        ['Եբրայեցիս', 11, 1],
        ['Յովհաննէս', 3, 16],
        ['Եփեսացիս', 2, 8],
        ['Հռովմայեցիս', 10, 9],
        ['Մարկոս', 11, 22],
      ],
    ],
    [
      ['հույս', 'յոյս', 'յուսա'],
      [
        ['Հռովմայեցիս', 15, 13],
        ['Երեմիա', 29, 11],
        ['Եբրայեցիս', 11, 1],
        ['Սաղմոս', 42, 5],
      ],
    ],
    [
      ['խաղաղ'],
      [
        ['Յովհաննէս', 14, 27],
        ['Փիլիպպեցիս', 4, 7],
        ['Եսայիա', 26, 3],
        ['Հռովմայեցիս', 5, 1],
      ],
    ],
    [
      ['ներում', 'ներման', 'ներել', 'թողութ'],
      [
        ['Մատթէոս', 6, 14],
        ['Ա Յովհաննէս', 1, 9],
        ['Եփեսացիս', 4, 32],
        ['Ղուկաս', 6, 37],
      ],
    ],
    [
      ['վախ', 'երկյուղ', 'երկիւղ'],
      [
        ['Եսայիա', 41, 10],
        ['Յեսու', 1, 9],
        ['Սաղմոս', 23, 4],
        ['Բ Տիմոթէոս', 1, 7],
        ['Յովհաննէս', 14, 27],
      ],
    ],
    [
      ['մխիթար', 'տխուր', 'տխրութ', 'լաց'],
      [
        ['Մատթէոս', 5, 4],
        ['Սաղմոս', 34, 18],
        ['Բ Կորնթացիս', 1, 3],
        ['Յովհաննէս', 16, 33],
      ],
    ],
    [
      ['փրկութ', 'փրկիչ', 'փրկել'],
      [
        ['Յովհաննէս', 3, 16],
        ['Գործք Առաքելոց', 4, 12],
        ['Եփեսացիս', 2, 8],
        ['Հռովմայեցիս', 10, 9],
      ],
    ],
    [
      ['համբեր', 'համբերութ'],
      [
        ['Հռովմայեցիս', 12, 12],
        ['Յակոբոս', 1, 3],
        ['Գաղատացիս', 6, 9],
      ],
    ],
    [
      ['ուրախ', 'ցնծ'],
      [
        ['Փիլիպպեցիս', 4, 4],
        ['Սաղմոս', 16, 11],
        ['Յովհաննէս', 15, 11],
      ],
    ],
    [
      ['շնորհք', 'շնորհ'],
      [
        ['Եփեսացիս', 2, 8],
        ['Բ Կորնթացիս', 12, 9],
        ['Եբրայեցիս', 4, 16],
      ],
    ],
    [
      ['իմաստութ', 'իմաստուն'],
      [
        ['Յակոբոս', 1, 5],
        ['Առակաց', 3, 5],
        ['Առակաց', 9, 10],
      ],
    ],
    [
      ['հոգնած', 'հանգիստ', 'հանգստ'],
      [
        ['Մատթէոս', 11, 28],
        ['Սաղմոս', 23, 2],
        ['Ելից', 33, 14],
      ],
    ],
  ];

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
    void add(String alias, String canonical) {
      if (alias.trim().isEmpty) return;
      if (!chapterCounts.containsKey(canonical)) return;
      map.putIfAbsent(alias, () => canonical);
    }

    for (final name in chapterCounts.keys) {
      add(name, name);
    }
    _aliases.forEach(add);

    const latin = {'Ա': '1', 'Բ': '2', 'Գ': '3', 'Դ': '4'};
    for (final entry in Map<String, String>.from(map).entries) {
      final parts = entry.key.split(' ');
      if (parts.length < 2) continue;
      final num = latin[parts.first];
      if (num == null) continue;
      final rest = parts.sublist(1).join(' ');
      add('$num $rest', entry.value);
      add('${parts.first}. $rest', entry.value);
    }

    final entries = map.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    return entries;
  }

  static String _fold(String input) {
    return input
        .toLowerCase()
        .replaceAll('և', 'եւ')
        .replaceAll('է', 'ե')
        .replaceAll('յ', 'հ')
        .replaceAll('։', ':')
        .replaceAll('·', ':')
        .replaceAll('.', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<BiblePassage> passagesForQuestion(String question, {int limit = 6}) {
    ensureReady();
    final verseOnly = wantsVerseOnly(question);
    final cap = verseOnly ? 8 : limit;
    final found = <String, BiblePassage>{};
    if (_parseReferenceSpecs(question).any((s) => s.startVerse != null)) {
      for (final passage in _passagesFromReferences(question)) {
        found[passage.ref] = passage;
      }
      return found.values.take(cap).toList();
    }

    for (final passage in _passagesFromTopics(question, limit: cap)) {
      found[passage.ref] = passage;
    }
    for (final passage in _passagesFromFamousPhrases(question)) {
      found.putIfAbsent(passage.ref, () => passage);
    }
    if (wantsLocateVerse(question) && found.isNotEmpty) {
      return found.values.take(1).toList();
    }

    for (final passage in _passagesFromReferences(question)) {
      found.putIfAbsent(passage.ref, () => passage);
    }

    if (found.length >= cap) {
      return found.values.take(cap).toList();
    }

    for (final passage in _passagesFromPhrase(question, limit: cap)) {
      found.putIfAbsent(passage.ref, () => passage);
      if (found.length >= cap) break;
    }

    if (wantsLocateVerse(question) && found.isNotEmpty) {
      return found.values.take(1).toList();
    }

    if (found.length >= cap) {
      return found.values.take(cap).toList();
    }

    for (final passage in _passagesFromKeywords(
      question,
      limit: cap,
      loose: verseOnly,
    )) {
      found.putIfAbsent(passage.ref, () => passage);
      if (found.length >= cap) break;
    }

    if (wantsLocateVerse(question) && found.isNotEmpty) {
      return found.values.take(1).toList();
    }

    return found.values.take(cap).toList();
  }

  bool wantsVerseOnly(String question) {
    final t = question.toLowerCase();
    if (t.contains('մեկնաբան') ||
        t.contains('նշանակում') ||
        t.contains('բացատր')) {
      return false;
    }
    if (_looksLikeImageAsk(t)) return false;
    if (_parseReferenceSpecs(question).any((s) => s.startVerse != null)) {
      return true;
    }
    if (_passagesFromReferences(question).isNotEmpty) return true;
    if (wantsLocateVerse(question)) return true;
    const keys = [
      'հատված',
      'հատուած',
      'համարներ',
      'հատվածներ',
      'հատուածներ',
      'ուղարկիր համարը',
      'ուղարկիր հատված',
      'ուղարկիր հատուած',
      'տուր համարը',
      'տուր հատված',
      'տուր համարներ',
      'կարդա համարը',
      'կարդա հատված',
    ];
    if (keys.any(t.contains)) return true;
    if (t.contains('մասին') &&
        (t.contains('համար') ||
            t.contains('հատված') ||
            t.contains('հատուած') ||
            t.contains('գրված') ||
            t.contains('գրուած') ||
            t.contains('աստվածաշնչ') ||
            t.contains('աստուածաշնչ'))) {
      return true;
    }
    if ((t.contains('ինչ է գրված') ||
            t.contains('ինչ ա գրված') ||
            t.contains('ինչ է գրուած') ||
            t.contains('ինչ է ասում')) &&
        (t.contains('աստվածաշնչ') ||
            t.contains('աստուածաշնչ') ||
            t.contains('մասին'))) {
      return true;
    }
    return (t.contains('համար') &&
        (t.contains('աստվածաշնչ') ||
            t.contains('աստուածաշնչ') ||
            t.contains('գրք') ||
            t.contains('տուր') ||
            t.contains('ուղարկ')));
  }

  bool _looksLikeImageAsk(String t) {
    if (t.contains('նկարագր') &&
        !t.contains('նկարով') &&
        !t.contains('նկարներ') &&
        !t.contains('նկարիր')) {
      return false;
    }
    return t.contains('նկար') ||
        t.contains('գեներաց') ||
        t.contains('generate') ||
        t.contains('picture') ||
        t.contains('image');
  }

  bool wantsLocateVerse(String question) {
    final t = question.toLowerCase();
    if (!(t.contains('որտեղ') ||
        t.contains('որ համարը') ||
        t.contains('որ հատվածը') ||
        t.contains('որ հատված'))) {
      return false;
    }
    return t.contains('գր') ||
        t.contains('հատված') ||
        t.contains('հատուած') ||
        t.contains('համար');
  }

  String formatQuotedPassages(List<BiblePassage> passages) {
    return passages
        .map((p) => '${p.displayRef}\n${p.text}')
        .join('\n\n');
  }

  bool wantsMoreVerses(String question) {
    final t = question.toLowerCase();
    return t.contains('էլի համար') ||
        t.contains('համարներ էլ') ||
        t.contains('հատվածներ էլ') ||
        t.contains('ուրիշ համար') ||
        t.contains('ուրիշ հատված') ||
        t.contains('էլ տուր') ||
        t.contains('տուր էլի') ||
        ((t.contains('համարներ') || t.contains('հատվածներ')) &&
            (t.contains('էլի') ||
                t.contains('դրա') ||
                t.contains('այդ') ||
                t.contains('նույն')));
  }

  bool looksLikeFollowUp(String question, {required bool hasPriorTurn}) {
    if (!hasPriorTurn) return false;
    if (quoteExplicitReferences(question).matched) return false;
    final t = question.toLowerCase().trim();
    if (t.isEmpty) return false;
    if (wantsMoreVerses(t)) return true;
    const cues = [
      'շարունակ',
      'էլի',
      'ավելի',
      'ինչու',
      'ինչի',
      'իսկ ',
      'դրա',
      'նրա',
      'այդ ',
      'էդ ',
      'էս ',
      'սա ',
      'դա ',
      'նույն',
      'մյուս',
      'ուրիշ',
      'հետո',
      'բացատր',
      'նկատի',
      'նկարով',
      'պատկեր',
    ];
    if (cues.any(t.contains)) return true;
    final topicalNew = t.contains('մասին') &&
        (t.contains('համարներ տուր') || t.contains('հատվածներ տուր'));
    if (topicalNew) return false;
    final words = t.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    return words <= 8;
  }

  bool wantsCommentary(String question) {
    final t = question.toLowerCase();
    if (t.contains('համարներ') ||
        t.contains('հատվածներ') ||
        t.contains('տուր համարը') ||
        t.contains('տուր հատված')) {
      return false;
    }
    return t.contains('մեկնաբան') ||
        t.contains('նշանակում') ||
        t.contains('բացատր');
  }

  /// Quotes the in-app Ararat text for «Book chapter:verse». Never uses AI.
  ({bool matched, String text, List<BiblePassage> passages})
      quoteExplicitReferences(String question) {
    ensureReady();
    final specs = _parseReferenceSpecs(question)
        .where((s) => s.startVerse != null)
        .toList();
    if (specs.isEmpty) {
      return (matched: false, text: '', passages: const <BiblePassage>[]);
    }

    final parts = <String>[];
    final passages = <BiblePassage>[];
    for (final spec in specs) {
      final found = _lookupRange(
        book: spec.book,
        chapter: spec.chapter,
        startVerse: spec.startVerse,
        endVerse: spec.endVerse ?? spec.startVerse,
      );
      if (found.isNotEmpty) {
        parts.add(formatQuotedPassages(found));
        passages.addAll(found);
        continue;
      }
      parts.add(_missingVerseMessage(spec));
    }
    return (matched: true, text: parts.join('\n\n'), passages: passages);
  }

  String _missingVerseMessage(_RefSpec spec) {
    final label = BiblePassage.displayBook(spec.book);
    final verse = spec.startVerse!;
    final end = spec.endVerse ?? verse;
    final ref = end == verse
        ? '$label ${spec.chapter}։$verse'
        : '$label ${spec.chapter}։$verse–$end';
    final chapterText = bibleText[spec.book]?[spec.chapter];
    if (chapterText == null || chapterText.isEmpty) {
      return 'Այս հավելվածի Աստվածաշնչում $label ${spec.chapter}-րդ գլուխը չկա։';
    }
    final verses = VerseHelper.parseVerses(chapterText);
    final last = verses.keys.fold<int>(0, (m, n) => n > m ? n : m);
    if (last == 0) {
      return 'Այս հավելվածի Աստվածաշնչում $ref չկա։';
    }
    return 'Այս հավելվածի Աստվածաշնչում $ref չկա։ Այդ գլուխն ունի $last համար։';
  }

  List<BiblePassage> _passagesFromTopics(String question, {required int limit}) {
    final n = TransliterationHelper.normalizeForSearch(question);
    final out = <String, BiblePassage>{};
    for (final row in _topics) {
      final keys = (row[0] as List).cast<String>();
      final hit = keys.any((key) {
        final kn = TransliterationHelper.normalizeForSearch(key);
        return kn.isNotEmpty && n.contains(kn);
      });
      if (!hit) continue;
      final refs = (row[1] as List);
      for (final ref in refs) {
        final item = (ref as List);
        final found = _lookupRange(
          book: item[0] as String,
          chapter: item[1] as int,
          startVerse: item[2] as int,
          endVerse: item[2] as int,
        );
        for (final passage in found) {
          out.putIfAbsent(passage.ref, () => passage);
          if (out.length >= limit) return out.values.toList();
        }
      }
    }
    return out.values.toList();
  }

  List<BiblePassage> _passagesFromFamousPhrases(String question) {
    final n = TransliterationHelper.normalizeForSearch(question);
    final out = <BiblePassage>[];
    for (final row in _famousQuotes) {
      final phrases = (row[0] as List).cast<String>();
      final hit = phrases.any((phrase) {
        final pn = TransliterationHelper.normalizeForSearch(phrase);
        return pn.isNotEmpty && n.contains(pn);
      });
      if (!hit) continue;
      out.addAll(
        _lookupRange(
          book: row[1] as String,
          chapter: row[2] as int,
          startVerse: row[3] as int,
          endVerse: row[3] as int,
        ),
      );
    }
    return out;
  }

  String _phraseQuery(String question) {
    var q = question.toLowerCase();
    const strips = [
      'որտեղ է գրված',
      'որտեղ է գրուած',
      'որտեղ ա գրված',
      'որտեղ ա գրուած',
      'որտեղ է գրվել',
      'հատվածը',
      'հատուածը',
      'հատված',
      'հատուած',
      'համարը',
      'համարները',
      'համարներ',
      'ուղարկիր',
      'տուր ինձ',
      'տուր',
      'մասին',
      'աստվածաշնչում',
      'աստվածաշնչի',
      'աստուածաշնչում',
    ];
    for (final s in strips) {
      q = q.replaceAll(s, ' ');
    }
    q = q.replaceAll(RegExp(r'\s+'), ' ').trim();
    q = q.replaceAll('իրեններ', 'իրաններ');
    return TransliterationHelper.normalizeForSearch(q);
  }

  List<BiblePassage> _passagesFromPhrase(String question, {required int limit}) {
    final phrase = _phraseQuery(question);
    if (phrase.length < 8) return const [];
    final index = _index ?? const <_IndexedVerse>[];
    final hits = <BiblePassage>[];
    for (final verse in index) {
      if (!verse.normalized.contains(phrase)) continue;
      hits.add(
        BiblePassage(
          book: verse.book,
          chapter: verse.chapter,
          verse: verse.verse,
          text: verse.original,
        ),
      );
      if (hits.length >= limit) break;
    }
    return hits;
  }

  List<_RefSpec> _parseReferenceSpecs(String question) {
    ensureReady();
    final q = ' ${_fold(question)} ';
    final specs = <_RefSpec>[];
    final occupied = <List<int>>[];
    bool overlaps(int start, int end) {
      for (final range in occupied) {
        if (start < range[1] && end > range[0]) return true;
      }
      return false;
    }

    for (final entry in _bookNames) {
      final name = _fold(entry.key);
      final book = entry.value;
      if (name.length < 3 && name != 'ոբ' && name != 'հոբ') continue;
      final escaped = RegExp.escape(name);
      final pattern = RegExp(
        '(^|[^ա-ֆa-z0-9])$escaped(?:ի)?(?:\\s*(?:գիրք|գլուխ))?\\s*(\\d+)\\s*(?:[:]|համար\\s*|հատված\\s*|հատուած\\s*)(\\d+)(?:\\s*[-–]\\s*(\\d+))?',
      );
      for (final match in pattern.allMatches(q)) {
        final start = match.start + (match.group(1)?.length ?? 0);
        final end = match.end;
        if (overlaps(start, end)) continue;
        final chapter = int.tryParse(match.group(2) ?? '');
        if (chapter == null) continue;
        final startVerse = int.tryParse(match.group(3) ?? '');
        final endVerse = int.tryParse(match.group(4) ?? '');
        occupied.add([start, end]);
        specs.add(
          _RefSpec(
            book: book,
            chapter: chapter,
            startVerse: startVerse,
            endVerse: endVerse ?? startVerse,
          ),
        );
      }
    }
    return specs;
  }

  List<BiblePassage> _passagesFromReferences(String question) {
    final results = <BiblePassage>[];
    for (final spec in _parseReferenceSpecs(question)) {
      results.addAll(
        _lookupRange(
          book: spec.book,
          chapter: spec.chapter,
          startVerse: spec.startVerse,
          endVerse: spec.endVerse ?? spec.startVerse,
          maxVerses: 40,
        ),
      );
    }
    return results;
  }

  List<BiblePassage> _lookupRange({
    required String book,
    required int chapter,
    int? startVerse,
    int? endVerse,
    int maxVerses = 12,
  }) {
    final chapterText = bibleText[book]?[chapter];
    if (chapterText == null || chapterText.isEmpty) return const [];
    final verses = VerseHelper.parseVerses(chapterText);
    if (verses.isEmpty) return const [];

    if (startVerse == null) {
      final keys = verses.keys.toList()..sort();
      return keys.take(maxVerses).map((n) {
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
    for (var n = from; n <= to && out.length < maxVerses; n++) {
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

  List<BiblePassage> _passagesFromKeywords(
    String question, {
    required int limit,
    bool loose = false,
  }) {
    final index = _index ?? const <_IndexedVerse>[];
    final concepts = _queryConcepts(question);
    if (concepts.isEmpty) return const [];

    final requiredHits = loose ? 1 : (concepts.length >= 2 ? concepts.length : 1);
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
