import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;

/// Plays Armenian aloud via Google hy TTS, without device-voice effects.
class ArmenianTts {
  ArmenianTts() {
    _player.setReleaseMode(ReleaseMode.stop);
    _player.setVolume(1);
    _player.setPlaybackRate(1);
    unawaited(
      _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.speech,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.defaultToSpeaker},
          ),
        ),
      ),
    );
  }

  final AudioPlayer _player = AudioPlayer();
  Completer<void>? _chunkDone;
  bool _cancelled = false;

  Future<void> stop() async {
    _cancelled = true;
    await _player.stop();
    final pending = _chunkDone;
    if (pending != null && !pending.isCompleted) pending.complete();
    _chunkDone = null;
  }

  Future<void> speak(String text) async {
    final spoken = text.trim();
    if (spoken.isEmpty) return;
    _cancelled = false;
    await _player.stop();
    _cancelled = false;
    await _speakGoogleHy(spoken);
  }

  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }

  Future<bool> _speakGoogleHy(String text) async {
    final chunks = _chunks(text);
    if (chunks.isEmpty) return false;
    var any = false;
    for (final chunk in chunks) {
      if (_cancelled) return any;
      final bytes = await _fetchChunk(chunk);
      if (bytes == null || bytes.isEmpty) {
        if (any) continue;
        return false;
      }
      any = true;
      await _playBytes(bytes);
    }
    return any;
  }

  Future<void> _playBytes(Uint8List bytes) async {
    if (_cancelled) return;
    await _player.stop();
    _chunkDone = Completer<void>();
    unawaited(
      _player.onPlayerComplete.first.then((_) {
        final pending = _chunkDone;
        if (pending != null && !pending.isCompleted) pending.complete();
      }),
    );
    await _player.play(BytesSource(bytes, mimeType: 'audio/mpeg'));
    await _chunkDone?.future;
  }

  Future<Uint8List?> _fetchChunk(String chunk) async {
    final queries = [
      {
        'ie': 'UTF-8',
        'client': 'gtx',
        'tl': 'hy',
        'q': chunk,
      },
      {
        'ie': 'UTF-8',
        'client': 'tw-ob',
        'tl': 'hy-AM',
        'q': chunk,
      },
    ];
    final hosts = ['translate.googleapis.com', 'translate.google.com'];
    for (final host in hosts) {
      for (final params in queries) {
        final uri = Uri.https(host, '/translate_tts', params);
        try {
          final response = await http.get(
            uri,
            headers: const {
              'User-Agent':
                  'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/122.0.0.0 Mobile Safari/537.36',
              'Accept': 'audio/mpeg,audio/*;q=0.9,*/*;q=0.8',
              'Accept-Language': 'hy-AM,hy;q=0.9',
              'Referer': 'https://translate.google.com/',
            },
          ).timeout(const Duration(seconds: 20));
          if (response.statusCode < 200 || response.statusCode >= 300) {
            continue;
          }
          if (response.bodyBytes.length < 80) continue;
          final type = response.headers['content-type'] ?? '';
          if (type.contains('json') || type.contains('html')) continue;
          return response.bodyBytes;
        } catch (_) {}
      }
    }
    return null;
  }

  List<String> _chunks(String text) {
    final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return const [];
    final out = <String>[];
    var rest = cleaned;
    while (rest.length > 180) {
      var cut = rest.lastIndexOf(RegExp('[։.!?]'), 180);
      if (cut < 50) cut = rest.lastIndexOf(' ', 180);
      if (cut < 50) cut = 180;
      out.add(rest.substring(0, cut + 1).trim());
      rest = rest.substring(cut + 1).trim();
    }
    if (rest.isNotEmpty) out.add(rest);
    return out;
  }
}
