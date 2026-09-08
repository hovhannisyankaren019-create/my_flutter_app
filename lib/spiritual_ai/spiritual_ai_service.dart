import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'bible_context.dart';
import 'spiritual_ai_config.dart';

class SpiritualAiException implements Exception {
  final String message;
  SpiritualAiException(this.message);

  @override
  String toString() => message;
}

class SpiritualAiReply {
  final String text;
  final List<BiblePassage> passages;

  const SpiritualAiReply({required this.text, required this.passages});
}

class SpiritualAiImage {
  final String? imageUrl;
  final Uint8List? imageBytes;

  const SpiritualAiImage({this.imageUrl, this.imageBytes});
}

class SpiritualAiService {
  Future<SpiritualAiReply> ask({
    required String message,
    required List<Map<String, String>> history,
    bool followUp = false,
    String searchQuery = '',
  }) async {
    if (!SpiritualAiConfig.isConfigured) {
      throw SpiritualAiException(
        'Հոգևոր ԱԲ-ն դեռ կարգավորված չէ։ Backend URL-ը պետք է տրվի SPIRITUAL_AI_URL միջոցով։',
      );
    }

    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      throw SpiritualAiException('Խնդրում ենք գրել հարցը։');
    }
    if (trimmed.length > 2000) {
      throw SpiritualAiException('Հարցը չափազանց երկար է։');
    }

    final lookupText = followUp && searchQuery.trim().isNotEmpty
        ? searchQuery.trim()
        : trimmed;
    final passages =
        BibleContextRetriever.instance.passagesForQuestion(lookupText);
    final retriever = BibleContextRetriever.instance;
    final lower = trimmed.toLowerCase();
    final imageAsk = lower.contains('նկար') ||
        lower.contains('գեներաց') ||
        lower.contains('generate') ||
        lower.contains('picture') ||
        lower.contains('image');
    final quote = retriever.quoteExplicitReferences(trimmed);
    if (!imageAsk && quote.matched && !retriever.wantsCommentary(trimmed)) {
      return SpiritualAiReply(
        text: quote.text,
        passages: quote.passages,
      );
    }
    final dumpVerses = !followUp
        ? retriever.wantsVerseOnly(trimmed)
        : retriever.wantsMoreVerses(trimmed);
    if (!imageAsk && dumpVerses && !retriever.wantsCommentary(trimmed)) {
      if (passages.isNotEmpty) {
        return SpiritualAiReply(
          text: retriever.formatQuotedPassages(passages),
          passages: passages,
        );
      }
    }

    var askMessage = trimmed;
    if (!imageAsk && dumpVerses && passages.isEmpty) {
      askMessage =
          '$trimmed\n\n(Համակարգ. այս թեմայով հավելվածի Աստվածաշնչում համար չգտնվեց։ Համարներ մի հորինիր, բայց հարցին միևնույն է պատասխանիր հայերենով։)';
    }
    if (!imageAsk && retriever.wantsIdentity(trimmed)) {
      askMessage =
          '$askMessage\n\n(Համակարգ. սա անձի հարց է։ Առաջին նախադասությամբ հստակ ասա՝ Աստվածաշնչում նա ով է։ Մի շփոթիր համանուն կամ պատահական համարի հետ։ Հովիվ ասելիս նկատի առ բարի հովիվը՝ Տերն ու Հիսուսը։ Եթե մի անունով մի քանի հայտնի անձ կա, կարճ նշիր գլխավորներին։ Համարներ մի հորինիր։)';
    } else if (!imageAsk) {
      askMessage =
          '$askMessage\n\n(Համակարգ. կարճ, հայերեն, ըստ Աստվածաշնչի, առանց փիլիսոփայության։)';
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (SpiritualAiConfig.gateSecret.isNotEmpty) {
      headers['X-Spiritual-Ai-Gate'] = SpiritualAiConfig.gateSecret;
    }

    final uri = Uri.parse(SpiritualAiConfig.endpoint);
    final response = await http
        .post(
          uri,
          headers: headers,
          body: jsonEncode({
            'message': askMessage,
            'history': history,
            'followUp': followUp,
            'passages': passages.map((p) => p.toJson()).toList(),
          }),
        )
        .timeout(const Duration(seconds: 90));

    if (response.statusCode == 429) {
      throw SpiritualAiException(
        'Շատ հարցումներ եղան։ Խնդրում ենք մի փոքր սպասել և նորից փորձել։',
      );
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw SpiritualAiException('Հարցումը մերժվեց սերվերի կողմից։');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final serverError = _serverError(response.body);
      if (serverError == 'Server is not configured') {
        throw SpiritualAiException(
          'Սերվերում OpenAI բանալին դրված չէ։ Render-ում ավելացրեք OPENAI_API_KEY և նորից փորձեք։',
        );
      }
      throw SpiritualAiException(
        'Չհաջողվեց ստանալ պատասխան (${response.statusCode})։',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw SpiritualAiException('Սերվերը անսպասելի պատասխան տվեց։');
    }
    final text = decoded['reply']?.toString().trim() ?? '';
    if (text.isEmpty) {
      throw SpiritualAiException('Պատասխանը դատարկ էր։');
    }
    return SpiritualAiReply(text: text, passages: passages);
  }

  Future<SpiritualAiImage> generateImage({required String prompt}) async {
    if (!SpiritualAiConfig.isConfigured) {
      throw SpiritualAiException(
        'Հոգևոր ԱԲ-ն դեռ կարգավորված չէ։ Backend URL-ը պետք է տրվի SPIRITUAL_AI_URL միջոցով։',
      );
    }

    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      throw SpiritualAiException('Խնդրում ենք գրել, թե ինչ նկար եք ուզում։');
    }
    if (trimmed.length > 800) {
      throw SpiritualAiException('Նկարի նկարագրությունը չափազանց երկար է։');
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (SpiritualAiConfig.gateSecret.isNotEmpty) {
      headers['X-Spiritual-Ai-Gate'] = SpiritualAiConfig.gateSecret;
    }

    final uri = Uri.parse(SpiritualAiConfig.imageEndpoint);
    final response = await http
        .post(
          uri,
          headers: headers,
          body: jsonEncode({'prompt': trimmed}),
        )
        .timeout(const Duration(seconds: 120));

    if (response.statusCode == 429) {
      throw SpiritualAiException(
        'Շատ հարցումներ եղան։ Խնդրում ենք մի փոքր սպասել և նորից փորձել։',
      );
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw SpiritualAiException('Հարցումը մերժվեց սերվերի կողմից։');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final serverError = _serverError(response.body);
      if (serverError == 'Image API is not configured') {
        throw SpiritualAiException(
          'Սերվերում նկարի API բանալին դրված չէ։ Render-ում ավելացրեք GEMINI_API_KEY։',
        );
      }
      throw SpiritualAiException(
        'Չհաջողվեց գեներացնել նկարը (${response.statusCode})։',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw SpiritualAiException('Սերվերը անսպասելի պատասխան տվեց։');
    }
    final imageUrl = decoded['imageUrl']?.toString().trim();
    final b64 = decoded['imageBase64']?.toString().trim() ?? '';
    Uint8List? bytes;
    if (b64.isNotEmpty) {
      try {
        bytes = base64Decode(b64);
      } catch (_) {
        throw SpiritualAiException('Նկարը վնասված էր։');
      }
    }
    if ((imageUrl == null || imageUrl.isEmpty) && bytes == null) {
      throw SpiritualAiException('Նկարը դատարկ էր։');
    }
    return SpiritualAiImage(imageUrl: imageUrl, imageBytes: bytes);
  }

  String? _serverError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return decoded['error']?.toString();
      }
    } catch (_) {}
    return null;
  }
}
