import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Records a short audio clip and asks Gemini to identify songs from it.
class MobileAudioService {
  final AudioRecorder _recorder = AudioRecorder();
  static const _geminiKey = String.fromEnvironment('GEMINI_KEY');

  Future<String?> recordClip({int seconds = 5}) async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return null;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/reel_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 96000, sampleRate: 44100),
      path: path,
    );
    await Future.delayed(Duration(seconds: seconds));
    final result = await _recorder.stop();
    return result;
  }

  Future<List<Map<String, String>>> identifySongs(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final base64Audio = base64Encode(bytes);

    // If no build-time key, try the runtime constant from gemini_service.
    final key = _geminiKey.isNotEmpty
        ? _geminiKey
        : _runtimeKey();

    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$key');

    final prompt =
        'This audio is from an Instagram reel. Transcribe any song titles or artist names you hear, '
        'then return a JSON array of up to 5 objects with "title" and "artist" keys only. '
        'If you cannot identify songs, return an empty array [].';

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'inline_data': {'mime_type': 'audio/m4a', 'data': base64Audio}},
              {'text': prompt},
            ],
          }
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini audio error ${response.statusCode}: ${response.body}');
    }

    final data = json.decode(response.body);
    final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
    final cleaned = text.replaceAll(RegExp(r'```(?:json)?'), '').trim();
    final List<dynamic> list = json.decode(cleaned);
    return list.map((e) => <String, String>{
          'title': (e['title'] ?? '').toString(),
          'artist': (e['artist'] ?? '').toString(),
        }).toList();
  }

  String _runtimeKey() {
    // Gemini key is committed in gemini_service.dart for this prototype.
    return 'AQ.Ab8RN6Lc3C8Gq9HZ4aai02zKrmzNaF0IXWyKOhHW9sFBKh3GqA';
  }

  void dispose() => _recorder.dispose();
}
