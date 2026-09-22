import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// King James Version (kjv.json).
///
/// Աշխատում է ճիշտ TbsBible / RuSynodalBible-ի պես. գիրքը «Արարատ»-ի
/// հայերեն անունով է պահվում (bookName-ը միշտ araratBookOrder-ից է),
/// իսկ ցուցադրվող անգլերեն անունը/կարճ անունը վերցվում է ստորև
/// գտնվող աղյուսակներից։
class EnKjvBible {
  EnKjvBible._();

  static const assetPath = 'assets/kjv.json';

  /// Նույն հերթականությունը, ինչ TbsBible.araratBookOrder-ում
  /// (kjv.json-ի book_number 1-66-ն ուղիղ այս հերթականությամբ են).
  static const araratBookOrder = <String>[
    'Ծննդոց',
    'Ելից',
    'Ղևտացոց',
    'Թուոց',
    'Երկրորդ Օրինաց',
    'Յեսու',
    'Դատաւորաց',
    'Հռութ',
    'Ա Թագաւորաց',
    'Բ Թագաւորաց',
    'Գ Թագաւորաց',
    'Դ Թագաւորաց',
    'Ա Մնացորդաց',
    'Բ Մնացորդաց',
    'Եզրաս',
    'Նէեմիա',
    'Եսթեր',
    'Յոբ',
    'Սաղմոս',
    'Առակաց',
    'Ժողովող',
    'Երգ Երգոց',
    'Եսայիա',
    'Երեմիա',
    'Ողբ Երեմիայի',
    'Եզեկիէլ',
    'Դանիէլ',
    'Ովսէ',
    'Հովէլ',
    'Ամովս',
    'Աբդիա',
    'Յովնան',
    'Միքիա',
    'Նաում',
    'Ամբակում',
    'Սոփոնիա',
    'Անգէ',
    'Զաքարիա',
    'Մաղաքիա',
    'Մատթէոս',
    'Մարկոս',
    'Ղուկաս',
    'Յովհաննէս',
    'Գործք Առաքելոց',
    'Հռովմայեցիս',
    'Ա Կորնթացիս',
    'Բ Կորնթացիս',
    'Գաղատացիս',
    'Եփեսացիս',
    'Փիլիպպեցիս',
    'Կողոսացիս',
    'Ա Թեսաղոնիկեցիս',
    'Բ Թեսաղոնիկեցիս',
    'Ա Տիմոթէոս',
    'Բ Տիմոթէոս',
    'Տիտոս',
    'Փիլիմոն',
    'Եբրայեցիս',
    'Յակոբոս',
    'Ա Պետրոս',
    'Բ Պետրոս',
    'Ա Յովհաննէս',
    'Բ Յովհաննէս',
    'Գ Յովհաննէս',
    'Յուդա',
    'Յայտնութիւն',
  ];

  /// Անգլերեն ցուցադրվող անունները, նույն հերթականությամբ, ինչ վերևում։
  static const _enDisplayNames = <String>[
    'Genesis',
    'Exodus',
    'Leviticus',
    'Numbers',
    'Deuteronomy',
    'Joshua',
    'Judges',
    'Ruth',
    '1 Samuel',
    '2 Samuel',
    '1 Kings',
    '2 Kings',
    '1 Chronicles',
    '2 Chronicles',
    'Ezra',
    'Nehemiah',
    'Esther',
    'Job',
    'Psalms',
    'Proverbs',
    'Ecclesiastes',
    'Song of Solomon',
    'Isaiah',
    'Jeremiah',
    'Lamentations',
    'Ezekiel',
    'Daniel',
    'Hosea',
    'Joel',
    'Amos',
    'Obadiah',
    'Jonah',
    'Micah',
    'Nahum',
    'Habakkuk',
    'Zephaniah',
    'Haggai',
    'Zechariah',
    'Malachi',
    'Matthew',
    'Mark',
    'Luke',
    'John',
    'Acts',
    'Romans',
    '1 Corinthians',
    '2 Corinthians',
    'Galatians',
    'Ephesians',
    'Philippians',
    'Colossians',
    '1 Thessalonians',
    '2 Thessalonians',
    '1 Timothy',
    '2 Timothy',
    'Titus',
    'Philemon',
    'Hebrews',
    'James',
    '1 Peter',
    '2 Peter',
    '1 John',
    '2 John',
    '3 John',
    'Jude',
    'Revelation',
  ];

  /// Կարճ (հղումների համար) անգլերեն անուններ, նույն հերթականությամբ։
  static const _enShortNames = <String>[
    'Gen', 'Exod', 'Lev', 'Num', 'Deut', 'Josh', 'Judg', 'Ruth',
    '1Sam', '2Sam', '1Kgs', '2Kgs', '1Chr', '2Chr', 'Ezra', 'Neh',
    'Esth', 'Job', 'Ps', 'Prov', 'Eccl', 'Song', 'Isa', 'Jer',
    'Lam', 'Ezek', 'Dan', 'Hos', 'Joel', 'Amos', 'Obad', 'Jonah',
    'Mic', 'Nah', 'Hab', 'Zeph', 'Hag', 'Zech', 'Mal', 'Matt',
    'Mark', 'Luke', 'John', 'Acts', 'Rom', '1Cor', '2Cor', 'Gal',
    'Eph', 'Phil', 'Col', '1Thess', '2Thess', '1Tim', '2Tim',
    'Titus', 'Phlm', 'Heb', 'Jas', '1Pet', '2Pet', '1John', '2John',
    '3John', 'Jude', 'Rev',
  ];

  static final Map<String, Map<int, String>> textByBook = {};
  static final Map<String, int> chapterCounts = {};
  static final Map<String, String> displayNames = {};
  static final Map<String, String> shortNames = {};

  static Future<void>? _loading;

  static Future<void> ensureLoaded() {
    return _loading ??= _load();
  }

  static Future<void> _load() async {
    final raw = await rootBundle.loadString(assetPath);
    final parsed = await compute(_parseKjvAsset, <String, dynamic>{
      'json': raw,
      'names': araratBookOrder,
      'titles': _enDisplayNames,
      'shorts': _enShortNames,
    });
    final texts = parsed['text'] as Map<String, dynamic>;
    final counts = parsed['counts'] as Map<String, dynamic>;
    final titles = parsed['titles'] as Map<String, dynamic>;
    final shorts = parsed['shorts'] as Map<String, dynamic>;
    textByBook
      ..clear()
      ..addAll(
        texts.map((book, chapters) {
          final chapterMap = chapters as Map<dynamic, dynamic>;
          return MapEntry(
            book,
            chapterMap.map(
              (key, value) => MapEntry(
                key is int ? key : int.parse('$key'),
                value as String,
              ),
            ),
          );
        }),
      );
    chapterCounts
      ..clear()
      ..addAll(
        counts.map(
          (book, count) => MapEntry(book, count is int ? count : int.parse('$count')),
        ),
      );
    displayNames
      ..clear()
      ..addAll(titles.map((book, title) => MapEntry(book, '$title')));
    shortNames
      ..clear()
      ..addAll(shorts.map((book, title) => MapEntry(book, '$title')));
  }

  static String? chapterText(String bookName, int chapterNumber) {
    return textByBook[bookName]?[chapterNumber];
  }

  static int chapterCount(String bookName, int fallback) {
    return chapterCounts[bookName] ?? fallback;
  }

  static String displayName(String bookName) {
    return displayNames[bookName] ?? bookName;
  }

  static String shortName(String bookName) {
    return shortNames[bookName] ?? displayName(bookName);
  }
}

Map<String, dynamic> _parseKjvAsset(Map<String, dynamic> args) {
  // kjv.json-ի կառուցվածքը՝
  // { "resultset": { "row": [ { "field": [id, book_number(1-66), chapter, verse, "text"] }, ... ] } }
  final data = jsonDecode(args['json'] as String) as Map<String, dynamic>;
  final names = (args['names'] as List<dynamic>).cast<String>();
  final titlesList = (args['titles'] as List<dynamic>).cast<String>();
  final shortsList = (args['shorts'] as List<dynamic>).cast<String>();

  final resultset = data['resultset'] as Map<String, dynamic>;
  final rows = resultset['row'] as List<dynamic>;

  // book_number(1..66) -> chapter -> verse -> text
  final raw = <int, Map<int, Map<int, String>>>{};

  for (final row in rows) {
    final field = (row as Map<String, dynamic>)['field'] as List<dynamic>;
    final bookNumber = field[1] as int;
    final chapterNumber = field[2] as int;
    final verseNumber = field[3] as int;
    final text = field[4] as String;

    final chapters = raw.putIfAbsent(bookNumber, () => {});
    final verses = chapters.putIfAbsent(chapterNumber, () => {});
    verses[verseNumber] = text;
  }

  final textByBook = <String, Map<int, String>>{};
  final counts = <String, int>{};
  final titles = <String, String>{};
  final shorts = <String, String>{};

  for (var i = 0; i < names.length; i++) {
    final bookName = names[i];
    final bookNumber = i + 1; // kjv.json-ում 1-ից սկսվող համարակալում
    final chapters = raw[bookNumber] ?? {};
    final chapterMap = <int, String>{};

    final chapterNumbers = chapters.keys.toList()..sort();
    for (final chapterNumber in chapterNumbers) {
      final verses = chapters[chapterNumber]!;
      final verseNumbers = verses.keys.toList()..sort();
      final buffer = StringBuffer();
      for (final verseNumber in verseNumbers) {
        buffer
          ..write(verseNumber)
          ..write(' ')
          ..write(verses[verseNumber])
          ..write(' ');
      }
      chapterMap[chapterNumber] = buffer.toString().trim();
    }

    textByBook[bookName] = chapterMap;
    counts[bookName] = chapterMap.length;
    titles[bookName] = i < titlesList.length ? titlesList[i] : bookName;
    shorts[bookName] = i < shortsList.length ? shortsList[i] : bookName;
  }

  return {
    'text': textByBook,
    'counts': counts,
    'titles': titles,
    'shorts': shorts,
  };
}
