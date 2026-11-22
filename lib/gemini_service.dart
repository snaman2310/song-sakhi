import 'package:http/http.dart' as http;
import 'dart:convert';

class GeminiService {
  // TODO: Put your Gemini Flash API key here (obtain from AI Studio).
  static const _apiKey = 'YOUR_GEMINI_API_KEY';

  Future<List<Map<String, String>>> suggestSongs(String transcript) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey');

    final prompt = '''
Given the following transcript from an Instagram reel, list the most likely song titles and artists (max 5). 
Return a JSON array of objects with "title" and "artist" keys only. 
Transcript: "$transcript"
''';

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'contents': [{'role': 'user', 'parts': [{'text': prompt}]}]}),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini error: ${response.body}');
    }

    final jsonBody = json.decode(response.body);
    final text = jsonBody['candidates'][0]['content']['parts'][0]['text'];
    final List<dynamic> list = json.decode(text);
    return list.map((e) => {'title': e['title'], 'artist': e['artist']}).toList();
  }
}