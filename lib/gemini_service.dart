import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Error thrown by [GeminiService]. [needsKey] is true when the only way
/// forward is for the user to supply a Gemini API key in Settings.
class GeminiException implements Exception {
  final String message;
  final String code;
  final bool needsKey;

  const GeminiException(this.message, {this.code = 'GEMINI_ERROR', this.needsKey = false});

  @override
  String toString() => message;
}

/// Identifies songs from audio using Gemini.
///
/// The API key is **never** bundled in the app:
///   1. Preferred path: the Node backend on Render holds `GEMINI_API_KEY` in its
///      environment and proxies the request (`POST /api/identify`).
///   2. Fallback path: a key the user pasted in Settings is stored on-device and
///      used to call Google directly (useful if the backend has no key yet).
class GeminiService {
  static const backendUrl = 'https://song-sakhi-auth1.onrender.com';
  static const _geminiBase = 'https://generativelanguage.googleapis.com/v1beta/models';
  static const _kLocalKey = 'gemini_api_key';

  /// `gemini-flash-latest` is a stable alias Google keeps pointing at the newest
  /// Flash model, so this list does not rot when a version is retired.
  static const _models = <String>[
    'gemini-flash-latest',
    'gemini-3.5-flash',
    'gemini-3.0-flash',
    'gemini-3.5-flash-lite',
    'gemini-3.0-flash-lite',
  ];

  // ---------------------------------------------------------------------------
  // Local key storage
  // ---------------------------------------------------------------------------
  Future<String?> localKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_kLocalKey)?.trim();
    return (key == null || key.isEmpty) ? null : key;
  }

  Future<void> saveLocalKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocalKey, key.trim());
  }

  Future<void> clearLocalKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLocalKey);
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------
  /// Audio path (mobile reel capture). [base64Audio] is raw file bytes.
  Future<List<Map<String, String>>> identifyFromAudio(
    String base64Audio, {
    String mimeType = 'audio/m4a',
  }) async {
    final payload = {'audioBase64': base64Audio, 'mimeType': mimeType};
    return _identify(payload, directParts: [
      {
        'inline_data': {'mime_type': mimeType, 'data': base64Audio},
      },
      {'text': _songPrompt},
    ]);
  }

  /// Text-only path (web transcript flow).
  Future<List<Map<String, String>>> suggestSongs(String transcript) async {
    final payload = {'transcript': transcript};
    return _identify(payload, directParts: [
      {'text': '$_songPrompt\n\nThe clip transcript was: "$transcript"'},
    ]);
  }

  static const _songPrompt =
      'You identify music from audio clips. Listen to the clip from an Instagram '
      'reel. Use any lyrics, vocals, spoken titles, artist mentions or recognisable '
      'melody. Only include a song if you are reasonably confident it is actually '
      'the one playing; never pad the list with guesses or similar-sounding tracks. '
      'Return ONLY a JSON array (no prose, no markdown) of up to 5 objects shaped like '
      '[{"title":"Song name","artist":"Artist name"}], most likely first. '
      'If you genuinely cannot identify any song, return [].';

  /// Live-listening path: one short WAV chunk -> the songs found in it.
  ///
  /// The backend analyses the chunk with two independent pipelines (Whisper
  /// lyrics + Gemini audio) and returns the merged list. Each song map has
  /// `title`, `artist` and `via` ("lyrics", "audio" or "lyrics+audio").
  Future<List<Map<String, String>>> identifyChunk(Uint8List wav) async {
    final http.Response res;
    try {
      res = await http
          .post(
            Uri.parse('$backendUrl/api/identify-chunk'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'audioBase64': base64Encode(wav),
              'mimeType': 'audio/wav',
            }),
          )
          .timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw const GeminiException(
        'The server took too long to answer. It may be waking up.',
        code: 'BACKEND_TIMEOUT',
      );
    } catch (_) {
      throw const GeminiException(
        'Could not reach the server. Check your connection.',
        code: 'BACKEND_UNREACHABLE',
      );
    }
    if (res.statusCode != 200) throw _backendException(res);

    final body = json.decode(res.body) as Map<String, dynamic>;
    final out = <Map<String, String>>[];
    for (final e in (body['songs'] as List?) ?? const []) {
      if (e is! Map) continue;
      final title = (e['title'] ?? '').toString().trim();
      if (title.isEmpty) continue;
      final artist = (e['artist'] ?? '').toString().trim();
      final via = e['via'] is List ? (e['via'] as List).join('+') : '';
      out.add({
        'title': title,
        'artist': artist.isEmpty ? 'Unknown artist' : artist,
        'via': via,
      });
    }
    return out;
  }

  /// Songs written on screen (OCR text lines from the reel). Each song map has
  /// `title`, `artist` and `via` = "screen".
  Future<List<Map<String, String>>> identifyScreenText(List<String> lines) async {
    if (lines.isEmpty) return const [];
    final http.Response res;
    try {
      res = await http
          .post(
            Uri.parse('$backendUrl/api/identify-text'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'lines': lines}),
          )
          .timeout(const Duration(seconds: 45));
    } on TimeoutException {
      throw const GeminiException(
        'Reading the screen text took too long.',
        code: 'BACKEND_TIMEOUT',
      );
    } catch (_) {
      throw const GeminiException(
        'Could not reach the server. Check your connection.',
        code: 'BACKEND_UNREACHABLE',
      );
    }
    if (res.statusCode != 200) throw _backendException(res);

    final body = json.decode(res.body) as Map<String, dynamic>;
    final out = <Map<String, String>>[];
    for (final e in (body['songs'] as List?) ?? const []) {
      if (e is! Map) continue;
      final title = (e['title'] ?? '').toString().trim();
      if (title.isEmpty) continue;
      out.add({
        'title': title,
        'artist': (e['artist'] ?? '').toString().trim(),
        'via': 'screen',
      });
    }
    return out;
  }

  /// Render's free tier sleeps when idle and takes up to a minute to wake.
  /// Calling this when the listen screen opens wakes it before the first chunk.
  Future<void> warmUp() async {
    try {
      await http
          .get(Uri.parse('$backendUrl/health'))
          .timeout(const Duration(seconds: 60));
    } catch (_) {}
  }

  /// Verifies a key against Google and returns the model that answered.
  /// The key is treated as an opaque string — we validate it by receiving a
  /// successful response from Gemini, not by checking its prefix format.
  Future<String> testKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      throw const GeminiException(
        'No Gemini API key provided.',
        code: 'GEMINI_KEY_EMPTY',
      );
    }
    final errors = <String>[];
    for (final model in _models) {
      try {
        final res = await http
            .post(
              Uri.parse('$_geminiBase/$model:generateContent'),
              headers: {'Content-Type': 'application/json', 'x-goog-api-key': trimmed},
              body: json.encode({
                'contents': [
                  {
                    'role': 'user',
                    'parts': [
                      {'text': 'Reply with exactly: OK'},
                    ],
                  },
                ],
                'generationConfig': {'temperature': 0.0},
              }),
            )
            .timeout(const Duration(seconds: 45));

        if (res.statusCode == 200) {
          final modelName = res.headers['x-goog-model-name'] ?? model;
          return modelName;
        }
        final msg = _googleMessage(res.body);
        if (res.statusCode == 401 || res.statusCode == 403 || msg.toLowerCase().contains('api key')) {
          throw GeminiException('Google rejected this key: $msg', code: 'GEMINI_KEY_INVALID');
        }
        if (res.statusCode == 429) {
          throw GeminiException('This key is valid but out of quota: $msg', code: 'GEMINI_QUOTA');
        }
        errors.add('$model: $msg');
      } on GeminiException {
        rethrow;
      } catch (e) {
        errors.add('$model: $e');
      }
    }
    throw GeminiException(
      'No Gemini model could handle the request.\n${errors.join('\n')}',
      code: 'GEMINI_UNAVAILABLE',
    );
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------
  Future<List<Map<String, String>>> _identify(
    Map<String, dynamic> backendPayload, {
    required List<Map<String, dynamic>> directParts,
  }) async {
    // 1) Backend proxy (key stays on the server). Keep the real reason when it
    //    fails, so a busy model or a sleeping server is not reported as a
    //    missing API key.
    GeminiException? backendError;
    try {
      final res = await http
          .post(
            Uri.parse('$backendUrl/api/identify'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(backendPayload),
          )
          .timeout(const Duration(seconds: 100));

      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        return _toSongs((body['songs'] as List?) ?? const []);
      }
      backendError = _backendException(res);
    } on TimeoutException {
      backendError = const GeminiException(
        'The server took too long to answer. It may be waking up, so try again in a moment.',
        code: 'BACKEND_TIMEOUT',
      );
    } catch (_) {
      backendError = const GeminiException(
        'Could not reach the server. Check your connection and try again.',
        code: 'BACKEND_UNREACHABLE',
      );
    }

    // 2) Direct call with a key the user saved in Settings.
    final key = await localKey();
    if (key != null) {
      try {
        final text = await _generateDirect(key, directParts);
        return _toSongs(_parseJsonArray(text));
      } on GeminiException catch (e) {
        if (e.code == 'GEMINI_KEY_INVALID' || e.code == 'GEMINI_QUOTA') throw e;
      }
    }

    throw backendError ??
        const GeminiException(
          'Song identification needs a Gemini API key. Add one in Settings → '
          'AI Settings (free at aistudio.google.com/apikey).',
          code: 'GEMINI_KEY_MISSING',
          needsKey: true,
        );
  }

  /// Turns an error response from our backend into a [GeminiException].
  GeminiException _backendException(http.Response res) {
    var message = 'Server error (${res.statusCode}).';
    var code = 'BACKEND_ERROR';
    try {
      final map = json.decode(res.body);
      if (map is Map) {
        if (map['error'] != null) message = map['error'].toString();
        if (map['code'] != null) code = map['code'].toString();
      }
    } catch (_) {}
    return GeminiException(message,
        code: code, needsKey: code == 'GEMINI_KEY_MISSING');
  }

  Future<String> _generateDirect(String apiKey, List<Map<String, dynamic>> parts) async {
    final errors = <String>[];
    for (final model in _models) {
      try {
        final res = await http
            .post(
              Uri.parse('$_geminiBase/$model:generateContent'),
              headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
              body: json.encode({
                'contents': [
                  {
                    'role': 'user',
                    'parts': parts,
                  },
                ],
                'generationConfig': {'temperature': 0.2},
              }),
            )
            .timeout(const Duration(seconds: 90));

        if (res.statusCode == 200) {
          final body = json.decode(res.body) as Map<String, dynamic>;
          final text = _extractText(body);
          if (text.trim().isEmpty) {
            errors.add('$model: empty response');
            continue;
          }
          return text;
        }

        final msg = _googleMessage(res.body);
        if (res.statusCode == 401 || res.statusCode == 403) {
          throw GeminiException('Google rejected your API key: $msg',
              code: 'GEMINI_KEY_INVALID');
        }
        if (res.statusCode == 429) {
          throw GeminiException('Gemini quota exceeded for this key: $msg',
              code: 'GEMINI_QUOTA');
        }
        errors.add('$model: $msg');
      } on GeminiException {
        rethrow;
      } catch (e) {
        errors.add('$model: $e');
      }
    }
    throw GeminiException(
      'No Gemini model could handle the request.\n${errors.join('\n')}',
      code: 'GEMINI_UNAVAILABLE',
    );
  }

  String _extractText(Map<String, dynamic> data) {
    final candidates = data['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final parts = candidates[0]?['content']?['parts'];
      if (parts is List) {
        return parts.map((p) => (p?['text'] ?? '').toString()).join();
      }
    }
    final block = data['promptFeedback']?['blockReason'];
    if (block != null) {
      throw GeminiException('Gemini blocked the request ($block).',
          code: 'GEMINI_BLOCKED');
    }
    throw GeminiException('Unexpected response from Gemini.', code: 'GEMINI_BAD_RESPONSE');
  }

  List<dynamic> _parseJsonArray(String raw) {
    final text = raw.replaceAll(RegExp(r'```(?:json)?', caseSensitive: false), '').trim();
    final start = text.indexOf('[');
    final end = text.lastIndexOf(']');
    if (start == -1 || end == -1 || end <= start) return const [];
    try {
      final decoded = json.decode(text.substring(start, end + 1));
      return decoded is List ? decoded : const [];
    } catch (_) {
      return const [];
    }
  }

  List<Map<String, String>> _toSongs(List<dynamic> list) {
    final out = <Map<String, String>>[];
    for (final e in list) {
      if (e is! Map) continue;
      final title = (e['title'] ?? e['song'] ?? e['track'] ?? '').toString().trim();
      final artist = (e['artist'] ?? e['artistName'] ?? '').toString().trim();
      if (title.isEmpty) continue;
      out.add({'title': title, 'artist': artist.isEmpty ? 'Unknown artist' : artist});
      if (out.length == 5) break;
    }
    return out;
  }

  String _googleMessage(String body) {
    try {
      final map = json.decode(body);
      if (map is Map) {
        if (map['error'] is Map && map['error']['message'] != null) {
          return map['error']['message'].toString();
        }
        if (map['error'] != null) return map['error'].toString();
        if (map['message'] != null) return map['message'].toString();
      }
    } catch (_) {}
    return body.length > 300 ? '${body.substring(0, 300)}…' : body;
  }
}