import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class TbsBible {
  TbsBible._();

  static const assetPath = 'assets/tbs_armenian_bible.json';

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

  static final Map<String, Map<int, String>> textByBook = {};
  static final Map<String, int> chapterCounts = {};
  static final Map<String, String> displayNames = {};

  /// Short citation names: Ararat-like length, TBS Eastern spelling.
  static const shortNames = <String, String>{
    'Ծննդոց': 'Ծննդոց',
    'Ելից': 'Ելից',
    'Ղևտացոց': 'Ղևտացիներ',
    'Թուոց': 'Թվոց',
    'Երկրորդ Օրինաց': 'Երկրորդ Օրինաց',
    'Յեսու': 'Հեսու',
    'Դատաւորաց': 'Դատավորներ',
    'Հռութ': 'Հռութ',
    'Ա Թագաւորաց': 'Ա Թագավորներ',
    'Բ Թագաւորաց': 'Բ Թագավորներ',
    'Գ Թագաւորաց': 'Գ Թագավորներ',
    'Դ Թագաւորաց': 'Դ Թագավորներ',
    'Ա Մնացորդաց': 'Ա Մնացորդաց',
    'Բ Մնացորդաց': 'Բ Մնացորդաց',
    'Եզրաս': 'Եզրաս',
    'Նէեմիա': 'Նեեմիա',
    'Եսթեր': 'Եսթեր',
    'Յոբ': 'Հոբ',
    'Սաղմոս': 'Սաղմոս',
    'Առակաց': 'Առակներ',
    'Ժողովող': 'Ժողովող',
    'Երգ Երգոց': 'Երգ Երգոց',
    'Եսայիա': 'Եսայիա',
    'Երեմիա': 'Երեմիա',
    'Ողբ Երեմիայի': 'Ողբեր',
    'Եզեկիէլ': 'Եզեկիել',
    'Դանիէլ': 'Դանիել',
    'Ովսէ': 'Ովսեե',
    'Հովէլ': 'Հովել',
    'Ամովս': 'Ամովս',
    'Աբդիա': 'Աբդիա',
    'Յովնան': 'Հովնան',
    'Միքիա': 'Միքիա',
    'Նաում': 'Նավում',
    'Ամբակում': 'Ամբակում',
    'Սոփոնիա': 'Սոփոնիա',
    'Անգէ': 'Անգե',
    'Զաքարիա': 'Զաքարիա',
    'Մաղաքիա': 'Մաղաքիա',
    'Մատթէոս': 'Մատթեոս',
    'Մարկոս': 'Մարկոս',
    'Ղուկաս': 'Ղուկաս',
    'Յովհաննէս': 'Հովհաննես',
    'Գործք Առաքելոց': 'Գործք Առաքելոց',
    'Հռովմայեցիս': 'Հռոմեացիներ',
    'Ա Կորնթացիս': 'Ա Կորնթացիներ',
    'Բ Կորնթացիս': 'Բ Կորնթացիներ',
    'Գաղատացիս': 'Գաղատացիներ',
    'Եփեսացիս': 'Եփեսացիներ',
    'Փիլիպպեցիս': 'Փիլիպպեցիներ',
    'Կողոսացիս': 'Կողոսացիներ',
    'Ա Թեսաղոնիկեցիս': 'Ա Թեսաղոնիկեցիներ',
    'Բ Թեսաղոնիկեցիս': 'Բ Թեսաղոնիկեցիներ',
    'Ա Տիմոթէոս': 'Ա Տիմոթեոս',
    'Բ Տիմոթէոս': 'Բ Տիմոթեոս',
    'Տիտոս': 'Տիտոս',
    'Փիլիմոն': 'Փիլիմոն',
    'Եբրայեցիս': 'Եբրայեցիներ',
    'Յակոբոս': 'Հակոբոս',
    'Ա Պետրոս': 'Ա Պետրոս',
    'Բ Պետրոս': 'Բ Պետրոս',
    'Ա Յովհաննէս': 'Ա Հովհաննես',
    'Բ Յովհաննէս': 'Բ Հովհաննես',
    'Գ Յովհաննէս': 'Գ Հովհաննես',
    'Յուդա': 'Հուդա',
    'Յայտնութիւն': 'Հայտնություն',
  };
  static Future<void>? _loading;

  static Future<void> ensureLoaded() {
    return _loading ??= _load();
  }

  static Future<void> _load() async {
    final raw = await rootBundle.loadString(assetPath);
    final parsed = await compute(_parseTbsAsset, <String, dynamic>{
      'json': raw,
      'names': araratBookOrder,
    });
    final texts = parsed['text'] as Map<String, dynamic>;
    final counts = parsed['counts'] as Map<String, dynamic>;
    final titles = parsed['titles'] as Map<String, dynamic>;
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
  }

  static String? chapterText(String bookName, int chapterNumber) {
    return textByBook[bookName]?[chapterNumber];
  }

  static int chapterCount(String bookName, int fallback) {
    return chapterCounts[bookName] ?? fallback;
  }

  static String displayName(String bookName) {
    return _readableTitle(displayNames[bookName] ?? bookName);
  }

  static String shortName(String bookName) {
    return shortNames[bookName] ?? displayName(bookName);
  }

  static String _readableTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.isEmpty) return title;
    return lower
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

Map<String, dynamic> _parseTbsAsset(Map<String, dynamic> args) {
  final data = jsonDecode(args['json'] as String) as Map<String, dynamic>;
  final names = (args['names'] as List<dynamic>).cast<String>();
  final books = data['books'] as List<dynamic>;
  final textByBook = <String, Map<int, String>>{};
  final counts = <String, int>{};
  final titles = <String, String>{};

  for (var i = 0; i < books.length && i < names.length; i++) {
    final bookName = names[i];
    final tbsTitle =
        (books[i] as Map<String, dynamic>)['title'] as String? ?? bookName;
    final chapters =
        (books[i] as Map<String, dynamic>)['chapters'] as List<dynamic>;
    final chapterMap = <int, String>{};
    for (final chapter in chapters) {
      final chapterData = chapter as Map<String, dynamic>;
      final number = chapterData['number'] as int;
      final verses = chapterData['verses'] as List<dynamic>;
      final buffer = StringBuffer();
      for (final verse in verses) {
        final verseData = verse as Map<String, dynamic>;
        buffer
          ..write(verseData['number'])
          ..write(' ')
          ..write(verseData['text'])
          ..write(' ');
      }
      chapterMap[number] = buffer.toString().trim();
    }
    textByBook[bookName] = chapterMap;
    counts[bookName] = chapterMap.length;
    titles[bookName] = tbsTitle;
  }

  return {
    'text': textByBook,
    'counts': counts,
    'titles': titles,
  };
}
