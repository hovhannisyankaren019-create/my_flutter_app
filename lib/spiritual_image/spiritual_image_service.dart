import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'spiritual_image_config.dart';

class SpiritualImageException implements Exception {
  final String message;
  SpiritualImageException(this.message);

  @override
  String toString() => message;
}

class SpiritualImageResult {
  final Uint8List bytes;

  const SpiritualImageResult({required this.bytes});
}

class SpiritualFoundImage {
  final String url;
  final String title;
  final String source;

  const SpiritualFoundImage({
    required this.url,
    required this.title,
    required this.source,
  });
}

class SpiritualLookupResult {
  final List<SpiritualFoundImage> images;
  final String factsText;
  final List<SpiritualFoundImage> sources;

  const SpiritualLookupResult({
    required this.images,
    required this.factsText,
    this.sources = const [],
  });
}

class SpiritualImageService {
  Future<SpiritualImageResult> generate({required String prompt}) async {
    if (!SpiritualImageConfig.isConfigured) {
      throw SpiritualImageException(
        'Նկարի սերվերը դեռ միացված չէ։ Deploy արեք Cloudflare Worker-ը և SPIRITUAL_IMAGE_URL դրեք։',
      );
    }

    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      throw SpiritualImageException('Խնդրում ենք գրել նկարի նկարագրությունը։');
    }
    if (trimmed.length > 500) {
      throw SpiritualImageException('Նկարագրությունը չափազանց երկար է։');
    }

    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
    };
    if (SpiritualImageConfig.gateSecret.isNotEmpty) {
      headers['X-Spiritual-Image-Gate'] = SpiritualImageConfig.gateSecret;
    }

    final uri = Uri.parse(SpiritualImageConfig.generateEndpoint);
    final response = await http
        .post(
          uri,
          headers: headers,
          body: jsonEncode({'prompt': trimmed}),
        )
        .timeout(const Duration(seconds: 90));

    Map<String, dynamic>? decoded;
    try {
      final raw = jsonDecode(response.body);
      if (raw is Map) {
        decoded = Map<String, dynamic>.from(raw);
      }
    } catch (_) {}

    final serverError = decoded?['error']?.toString().trim();
    if (response.statusCode == 429) {
      throw SpiritualImageException(
        serverError ??
            'Շատ հարցումներ եղան։ Խնդրում ենք մի փոքր սպասել։',
      );
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw SpiritualImageException(
        serverError ?? 'Հարցումը մերժվեց սերվերի կողմից։',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SpiritualImageException(
        (serverError != null && serverError.isNotEmpty)
            ? serverError
            : 'Նկարը չհաջողվեց ստեղծել։ Խնդրում ենք նորից փորձել։',
      );
    }

    final b64 = decoded?['image']?.toString().trim() ?? '';
    if (b64.isEmpty) {
      throw SpiritualImageException('Նկարը դատարկ էր։');
    }
    try {
      return SpiritualImageResult(bytes: base64Decode(b64));
    } catch (_) {
      throw SpiritualImageException('Նկարը վնասված էր։');
    }
  }

  Future<SpiritualLookupResult> findHistorical({
    required String prompt,
    List<String> exclude = const [],
  }) async {
    if (!SpiritualImageConfig.isConfigured) {
      throw SpiritualImageException(
        'Նկարի սերվերը դեռ միացված չէ։ Deploy արեք Cloudflare Worker-ը և SPIRITUAL_IMAGE_URL դրեք։',
      );
    }

    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      throw SpiritualImageException('Խնդրում ենք գրել, թե ինչ նկար եք փնտրում։');
    }
    if (trimmed.length > 500) {
      throw SpiritualImageException('Նկարագրությունը չափազանց երկար է։');
    }

    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
    };
    if (SpiritualImageConfig.gateSecret.isNotEmpty) {
      headers['X-Spiritual-Image-Gate'] = SpiritualImageConfig.gateSecret;
    }

    final uri = Uri.parse(SpiritualImageConfig.findEndpoint);
    final response = await http
        .post(
          uri,
          headers: headers,
          body: jsonEncode({
            'prompt': trimmed,
            'exclude': exclude.take(40).toList(),
            'page': exclude.isEmpty ? 0 : exclude.length ~/ 6,
          }),
        )
        .timeout(const Duration(seconds: 45));

    Map<String, dynamic>? decoded;
    try {
      final raw = jsonDecode(response.body);
      if (raw is Map) {
        decoded = Map<String, dynamic>.from(raw);
      }
    } catch (_) {}

    final serverError = decoded?['error']?.toString().trim();
    if (response.statusCode == 429) {
      throw SpiritualImageException(
        serverError ?? 'Շատ հարցումներ եղան։ Խնդրում ենք մի փոքր սպասել։',
      );
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw SpiritualImageException(
        serverError ?? 'Հարցումը մերժվեց սերվերի կողմից։',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SpiritualImageException(
        (serverError != null && serverError.isNotEmpty)
            ? serverError
            : 'Նկարը չհաջողվեց գտնել։ Խնդրում ենք նորից փորձել։',
      );
    }

    final rawImages = decoded?['images'];
    final rawFacts = decoded?['facts'];
    final images = <SpiritualFoundImage>[];
    if (rawImages is List) {
      for (final item in rawImages) {
        if (item is! Map) continue;
        final url = item['url']?.toString().trim() ?? '';
        if (url.isEmpty || !url.startsWith('https://')) continue;
        images.add(
          SpiritualFoundImage(
            url: url,
            title: item['title']?.toString().trim() ?? '',
            source: item['source']?.toString().trim() ?? 'Web',
          ),
        );
      }
    }
    final factParts = <String>[];
    final sources = <SpiritualFoundImage>[];
    if (rawFacts is List) {
      for (final item in rawFacts) {
        if (item is! Map) continue;
        final title = item['title']?.toString().trim() ?? '';
        final extract = item['extract']?.toString().trim() ?? '';
        final source = item['source']?.toString().trim() ?? '';
        final url = item['url']?.toString().trim() ?? '';
        if (extract.isEmpty) continue;
        factParts.add(
          [
            if (source.isNotEmpty) source,
            if (title.isNotEmpty) title,
            if (url.isNotEmpty) url,
            extract,
          ].join(' — '),
        );
        if (url.startsWith('https://')) {
          sources.add(
            SpiritualFoundImage(url: url, title: title, source: source),
          );
        }
      }
    }
    if (images.isEmpty && factParts.isEmpty) {
      throw SpiritualImageException('Համապատասխան պատմական տեղեկություն կամ քարտեզ չգտնվեց։');
    }
    return SpiritualLookupResult(
      images: images,
      factsText: factParts.join('\n\n'),
      sources: sources,
    );
  }
}
