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
  }

  static String? chapterText(String bookName, int chapterNumber) {
    return textByBook[bookName]?[chapterNumber];
  }

  static int chapterCount(String bookName, int fallback) {
    return chapterCounts[bookName] ?? fallback;
  }
}

Map<String, dynamic> _parseTbsAsset(Map<String, dynamic> args) {
  final data = jsonDecode(args['json'] as String) as Map<String, dynamic>;
  final names = (args['names'] as List<dynamic>).cast<String>();
  final books = data['books'] as List<dynamic>;
  final textByBook = <String, Map<int, String>>{};
  final counts = <String, int>{};

  for (var i = 0; i < books.length && i < names.length; i++) {
    final bookName = names[i];
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
  }

  return {
    'text': textByBook,
    'counts': counts,
  };
}
