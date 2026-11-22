import 'package:http/http.dart' as http;
import 'dart:convert';

/// Shared Gemini client. Uses current (2026) model names with fallbacks so the
/// app keeps working when a model is deprecated.
class GeminiService {
  static const _apiKey = 'AQ.Ab8RN6Lc3C8Gq9HZ4aai02zKrmzNaF0IXWyKOhHW9sFBKh3GqA';

  // Ordered newest -> fallback. All support multimodal (text + audio) input.
  static const _models = [
    'gemini-3.6-flash',
    'gemini-3.5-flash-lite',
    'gemini-2.5-flash-lite',
  ];

  Future<Map<String, dynamic>> _generate(List<Map<String, dynamic>> parts) async {
    String last = 'unknown error';
    for (final model in _models) {
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey');
      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'contents': [{'role': 'user', 'parts': parts}],
          }),
        );
        if (response.statusCode == 200) {
          return json.decode(response.body) as Map<String, dynamic>;
        }
        last = '${response.statusCode}: ${response.body}';
        // Bad key / quota -> no point trying other models.
        if (response.statusCode == 400 || response.statusCode == 403) break;
      } catch (e) {
        last = e.toString();
      }
    }
    throw Exception('Gemini error: $last');
  }

  String _extractText(Map<String, dynamic> data) {
    try {
      return data['candidates'][0]['content']['parts'][0]['text'] as String;
    } catch (_) {
      throw Exception('Unexpected Gemini response: ${json.encode(data)}');
    }
  }

  List<dynamic> _parseJsonArray(String raw) {
    var text = raw.trim();
    text = text.replaceAll(RegExp(r'```(?:json)?'), '').trim();
    final start = text.indexOf('[');
    final end = text.lastIndexOf(']');
    if (start == -1 || end == -1 || end <= start) {
      // Model returned something unexpected -> treat as no songs.
      return const [];
    }
    return json.decode(text.substring(start, end + 1)) as List<dynamic>;
  }

  /// Text-only path (web transcript flow).
  Future<List<Map<String, String>>> suggestSongs(String transcript) async {
    final data = await _generate([
      {
        'text': 'Given the following transcript from an Instagram reel, list the '
            'most likely song titles and artists (max 5). Return ONLY a JSON array '
            'of objects with "title" and "artist" keys.\nTranscript: "$transcript"',
      },
    ]);
    return _toSongs(_parseJsonArray(_extractText(data)));
  }

  /// Audio path (mobile reel capture). [base64Audio] is raw file bytes.
  Future<List<Map<String, String>>> identifyFromAudio(
    String base64Audio, {
    String mimeType = 'audio/m4a',
  }) async {
    final data = await _generate([
      {'inline_data': {'mime_type': mimeType, 'data': base64Audio}},
      {
        'text': 'This is a short audio clip from an Instagram reel. First transcribe '
            'any song titles, artist names, or lyrics you hear. Then return ONLY a '
            'JSON array of up to 5 objects with "title" and "artist" keys. '
            'If you cannot identify any songs, return [].',
      },
    ]);
    return _toSongs(_parseJsonArray(_extractText(data)));
  }

  List<Map<String, String>> _toSongs(List<dynamic> list) {
    return list.map((e) => <String, String>{
          'title': (e is Map && e['title'] != null) ? e['title'].toString() : '',
          'artist': (e is Map && e['artist'] != null) ? e['artist'].toString() : '',
        }).toList();
  }
}
