import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Русский Синодальный перевод (ru_synodal.json).
///
/// Աշխատում է ճիշտ TbsBible-ի պես. գիրքը «Արարատ»-ի հայերեն անունով է
/// պահվում (bookName-ը միշտ araratBookOrder-ից է), իսկ ցուցադրվող
/// ռուսերեն անունը/կարճ անունը վերցվում է ստորև գտնվող աղյուսակներից։
class RuSynodalBible {
  RuSynodalBible._();

  static const assetPath = 'assets/ru_synodal.json';

  /// Նույն հերթականությունը, ինչ TbsBible.araratBookOrder-ում
  /// (ru_synodal.json-ի 66 գրքերը գալիս են ուղիղ այս հերթականությամբ).
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

  /// Ռուսերեն ցուցադրվող անունները, նույն հերթականությամբ, ինչ վերևում։
  static const _ruDisplayNames = <String>[
    'Бытие',
    'Исход',
    'Левит',
    'Числа',
    'Второзаконие',
    'Иисус Навин',
    'Судьи',
    'Руфь',
    '1-я Царств',
    '2-я Царств',
    '3-я Царств',
    '4-я Царств',
    '1-я Паралипоменон',
    '2-я Паралипоменон',
    'Ездра',
    'Неемия',
    'Есфирь',
    'Иов',
    'Псалтирь',
    'Притчи',
    'Екклесиаст',
    'Песнь Песней',
    'Исаия',
    'Иеремия',
    'Плач Иеремии',
    'Иезекииль',
    'Даниил',
    'Осия',
    'Иоиль',
    'Амос',
    'Авдий',
    'Иона',
    'Михей',
    'Наум',
    'Аввакум',
    'Софония',
    'Аггей',
    'Захария',
    'Малахия',
    'От Матфея',
    'От Марка',
    'От Луки',
    'От Иоанна',
    'Деяния',
    'К Римлянам',
    '1-е Коринфянам',
    '2-е Коринфянам',
    'К Галатам',
    'К Ефесянам',
    'К Филиппийцам',
    'К Колоссянам',
    '1-е Фессалоникийцам',
    '2-е Фессалоникийцам',
    '1-е Тимофею',
    '2-е Тимофею',
    'К Титу',
    'К Филимону',
    'К Евреям',
    'Иакова',
    '1-е Петра',
    '2-е Петра',
    '1-е Иоанна',
    '2-е Иоанна',
    '3-е Иоанна',
    'Иуды',
    'Откровение',
  ];

  /// Կարճ (հղումների համար) ռուսերեն անուններ, նույն հերթականությամբ։
  static const _ruShortNames = <String>[
    'Быт', 'Исх', 'Лев', 'Чис', 'Втор', 'Нав', 'Суд', 'Руфь',
    '1Цар', '2Цар', '3Цар', '4Цар', '1Пар', '2Пар', 'Езд', 'Неем',
    'Есф', 'Иов', 'Пс', 'Притч', 'Еккл', 'Песн', 'Ис', 'Иер',
    'Плач', 'Иез', 'Дан', 'Ос', 'Иоил', 'Ам', 'Авд', 'Ион', 'Мих',
    'Наум', 'Авв', 'Соф', 'Агг', 'Зах', 'Мал', 'Мф', 'Мк', 'Лк',
    'Ин', 'Деян', 'Рим', '1Кор', '2Кор', 'Гал', 'Еф', 'Флп', 'Кол',
    '1Фес', '2Фес', '1Тим', '2Тим', 'Тит', 'Флм', 'Евр', 'Иак',
    '1Пет', '2Пет', '1Ин', '2Ин', '3Ин', 'Иуд', 'Откр',
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
    final parsed = await compute(_parseSynodalAsset, <String, dynamic>{
      'json': raw,
      'names': araratBookOrder,
      'titles': _ruDisplayNames,
      'shorts': _ruShortNames,
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

Map<String, dynamic> _parseSynodalAsset(Map<String, dynamic> args) {
  // ru_synodal.json-ի կառուցվածքը՝
  // [ { "abbrev": "gn", "chapters": [ ["1-ին համարի տեքստը", "2-րդ համարի տեքստը", ...], ... ] }, ... ]
  final data = jsonDecode(args['json'] as String) as List<dynamic>;
  final names = (args['names'] as List<dynamic>).cast<String>();
  final titlesList = (args['titles'] as List<dynamic>).cast<String>();
  final shortsList = (args['shorts'] as List<dynamic>).cast<String>();

  final textByBook = <String, Map<int, String>>{};
  final counts = <String, int>{};
  final titles = <String, String>{};
  final shorts = <String, String>{};

  for (var i = 0; i < data.length && i < names.length; i++) {
    final bookName = names[i];
    final bookData = data[i] as Map<String, dynamic>;
    final chapters = bookData['chapters'] as List<dynamic>;
    final chapterMap = <int, String>{};

    for (var c = 0; c < chapters.length; c++) {
      final verses = chapters[c] as List<dynamic>;
      final buffer = StringBuffer();
      for (var v = 0; v < verses.length; v++) {
        buffer
          ..write(v + 1)
          ..write(' ')
          ..write(verses[v])
          ..write(' ');
      }
      chapterMap[c + 1] = buffer.toString().trim();
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
