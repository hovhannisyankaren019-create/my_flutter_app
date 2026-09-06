import 'dart:convert';

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

class SpiritualAiService {
  Future<SpiritualAiReply> ask({
    required String message,
    required List<Map<String, String>> history,
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

    final passages =
        BibleContextRetriever.instance.passagesForQuestion(trimmed);

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
            'message': trimmed,
            'history': history,
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
