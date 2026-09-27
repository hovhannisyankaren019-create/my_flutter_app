import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

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

  const SpiritualAiReply({
    required this.text,
    this.passages = const [],
  });
}

class SpiritualAiService {
  static const openChatEmails = {
    'hovhannisyankaren019@gmail.com',
    'artopastor@gmail.com',
  };

  static bool openChatFor(User? user) {
    if (user == null) return false;
    final emails = <String>{};
    final own = user.email?.trim().toLowerCase();
    if (own != null && own.isNotEmpty) emails.add(own);
    for (final provider in user.providerData) {
      final email = provider.email?.trim().toLowerCase();
      if (email != null && email.isNotEmpty) emails.add(email);
    }
    return emails.any(openChatEmails.contains);
  }

  Future<SpiritualAiReply> ask({
    required String message,
    required List<Map<String, String>> history,
    bool followUp = false,
    String searchQuery = '',
    String assistant = 'bible',
  }) async {
    if (!SpiritualAiConfig.isConfigured) {
      throw SpiritualAiException(
        'ԱԲ-ն դեռ կարգավորված չէ։ Backend URL-ը պետք է տրվի SPIRITUAL_AI_URL միջոցով։',
      );
    }

    final trimmed = message.trim();

    if (trimmed.isEmpty) {
      throw SpiritualAiException('Խնդրում ենք գրել հարցը։');
    }

    final user = FirebaseAuth.instance.currentUser;
    final isArtopastor = openChatFor(user);
    const usesOpenAi = true;
    final rawChat = usesOpenAi || isArtopastor;

    if (usesOpenAi && user == null) {
      throw SpiritualAiException('ԱԲ-ն բացվում է միայն գրանցված հաշվով։');
    }

    if (trimmed.length > (rawChat ? 12000 : 2000)) {
      throw SpiritualAiException('Հարցը չափազանց երկար է։');
    }

    if (rawChat) {
      final chosen = assistant == 'bible' || assistant.isEmpty
          ? 'chatgpt'
          : assistant;
      final response = await _sendRequest(
        message: trimmed,
        history: history,
        followUp: followUp,
        passages: const [],
        user: user,
        assistant: chosen,
        channel: 'open',
      );

      return SpiritualAiReply(
        text: response,
        passages: const [],
      );
    }

    // ============================================================
    // ՍՈՎՈՐԱԿԱՆ ՀՈԳԵՎՈՐ ԱԲ
    // ============================================================

    final lookupText = followUp && searchQuery.trim().isNotEmpty
        ? searchQuery.trim()
        : trimmed;

    final retriever = BibleContextRetriever.instance;

    await retriever.ensureReady();

    if (retriever.looksLikeImageAsk(trimmed) &&
        !retriever.isBibleRelated(trimmed)) {
      return const SpiritualAiReply(
        text: BibleContextRetriever.imagesOffReply,
      );
    }

    final found = retriever.passagesForQuestion(lookupText);

    final attachPassages = retriever.shouldAttachPassages(
      trimmed,
      followUp: followUp,
    );

    final passages =
        attachPassages ? found : const <BiblePassage>[];

    final quote = retriever.quoteExplicitReferences(trimmed);

    if (quote.matched &&
        !retriever.wantsCommentary(trimmed) &&
        !retriever.wantsRestrictedSources(trimmed)) {
      return SpiritualAiReply(
        text: quote.text,
        passages: quote.passages,
      );
    }

    final dumpVerses = !followUp
        ? retriever.wantsVerseOnly(trimmed)
        : retriever.wantsMoreVerses(trimmed);

    if (dumpVerses &&
        !retriever.wantsCommentary(trimmed) &&
        !retriever.wantsRestrictedSources(trimmed)) {
      if (passages.isNotEmpty) {
        return SpiritualAiReply(
          text: retriever.formatQuotedPassages(passages),
          passages: passages,
        );
      }
    }

    var askMessage = trimmed;

    if (dumpVerses && passages.isEmpty) {
      askMessage =
          '$trimmed\n\n'
          '(Համակարգ. այս թեմայով հավելվածի Աստվածաշնչում համար չգտնվեց։ '
          'Համարներ մի հորինիր, բայց հարցին միևնույն է պատասխանիր հայերենով։)';
    }

    if (retriever.wantsWordMeaning(trimmed) ||
        retriever.wantsInterpretation(trimmed)) {
      askMessage =
          '$askMessage\n\n'
          '(Համակարգ. բացատրիր հայերենով և պարտադիր ավելացրու '
          'Սթրոնգի բառարանի բացատրությունը. Սթրոնգի համարը, '
          'եբրայերեն է թե հունարեն, հայերեն արտասանությունը, իմաստները '
          'և Աստվածաշնչյան գործածությունը։ Անգլերեն բառ մի գրիր։ '
          'Կարճ մի գրիր։)';
    } else if (retriever.wantsRestrictedSources(trimmed)) {
      askMessage =
          '$askMessage\n\n'
          '(Համակարգ. նախ հստակ պատասխանիր հարցին հայերենով, '
          'հետո լիարժեք բացատրիր Աստվածաշնչով։ Աղբյուրների անունները '
          'գրիր միայն հայերենով։ Թիվ մի հորինիր։ Օտար բառ մի գրիր։ '
          'Կարճ մի գրիր։)';
    } else if (retriever.wantsIdentity(trimmed)) {
      askMessage =
          '$askMessage\n\n'
          '(Համակարգ. սա անձի հարց է։ Առաջին նախադասությամբ հստակ '
          'ասա՝ Աստվածաշնչում նա ով է։ Մի շփոթիր համանուն կամ պատահական '
          'համարի հետ։ Հովիվ ասելիս նկատի առ բարի հովիվը՝ Տերն ու Հիսուսը։ '
          'Եթե մի անունով մի քանի հայտնի անձ կա, կարճ նշիր գլխավորներին։ '
          'Համարներ մի հորինիր։)';
    } else {
      askMessage =
          '$askMessage\n\n'
          '(Համակարգ. պատասխանիր միայն հայերենով և միայն Աստվածաշնչով՝ '
          'լիարժեք, ջերմ ու պարզ։ Եթե բառի իմաստ է, ավելացրու Սթրոնգի '
          'բառարանը հայերենով։ Օտար բառ մի գրիր։ Եթե Աստվածաշունչը խոսում '
          'է այս մասին, պատասխանիր և մի ասա թե կապ չունի։ Միայն ակնհայտ '
          'աշխարհիկ բաներին գրիր միայն սա, առանց համարի և առանց թվի. '
          'Այս հարցը Աստվածաշնչի հետ կապ չունի։ Ես պատասխանում եմ միայն '
          'Աստվածաշնչյան հարցերին։)';
    }

    final text = await _sendRequest(
      message: askMessage,
      history: history,
      followUp: followUp,
      passages: passages,
      user: user,
      assistant: isArtopastor ? assistant : '',
    );

    final lower = text.toLowerCase();

    final refusal = lower.contains('չեմ կարող') ||
        lower.contains('չեմ պատասխան') ||
        lower.contains('կապ չունի') ||
        lower.contains('միայն աստվածաշնչյան');

    if (refusal) {
      return const SpiritualAiReply(
        text: BibleContextRetriever.offTopicReply,
      );
    }

    return SpiritualAiReply(
      text: text,
      passages: passages,
    );
  }

  // ============================================================
  // BACKEND REQUEST
  // ============================================================

  Future<String> _sendRequest({
    required String message,
    required List<Map<String, String>> history,
    required bool followUp,
    required List<BiblePassage> passages,
    required User? user,
    String assistant = '',
    String channel = '',
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (SpiritualAiConfig.gateSecret.isNotEmpty) {
      headers['X-Spiritual-Ai-Gate'] =
          SpiritualAiConfig.gateSecret;
    }

    // Guest-ի դեպքում Authorization header չենք ուղարկում։
    //
    // Logged-in user-ի դեպքում ուղարկում ենք Firebase ID token-ը։
    if (user != null) {
      final idToken = await user.getIdToken();

      if (idToken != null && idToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $idToken';
      }
    }

    final uri = Uri.parse(SpiritualAiConfig.endpoint);

    final response = await http
        .post(
          uri,
          headers: headers,
          body: jsonEncode({
            'message': message,
            'history': history,
            'followUp': followUp,
            'passages': passages.map((p) => p.toJson()).toList(),
            if (assistant.isNotEmpty) 'assistant': assistant,
            if (channel.isNotEmpty) 'channel': channel,
          }),
        )
        .timeout(const Duration(seconds: 90));

    if (response.statusCode == 429) {
      throw SpiritualAiException(
        'Շատ հարցումներ եղան։ Խնդրում ենք մի փոքր սպասել և նորից փորձել։',
      );
    }

    if (response.statusCode == 401 ||
        response.statusCode == 403) {
      throw SpiritualAiException(
        'Հարցումը մերժվեց սերվերի կողմից։',
      );
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      final serverError = _serverError(response.body);

      if (serverError == 'Server is not configured') {
        throw SpiritualAiException(
          'Սերվերում OpenAI բանալին դրված չէ։ '
          'Render-ում ավելացրեք OPENAI_API_KEY և նորից փորձեք։',
        );
      }

      throw SpiritualAiException(
        'Չհաջողվեց ստանալ պատասխան (${response.statusCode})։',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw SpiritualAiException(
        'Սերվերը անսպասելի պատասխան տվեց։',
      );
    }

    final text = decoded['reply']?.toString().trim() ?? '';

    if (text.isEmpty) {
      throw SpiritualAiException(
        'Պատասխանը դատարկ էր։',
      );
    }

    return text;
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