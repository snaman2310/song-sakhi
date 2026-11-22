import 'package:flutter/material.dart';
import 'package:music_nudge_app/whisper_service.dart';
import 'package:music_nudge_app/gemini_service.dart';
import 'package:music_nudge_app/screens/suggestions_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class ListeningScreen extends StatefulWidget {
  const ListeningScreen({super.key});
  @override State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen> {
  bool _micGranted = false;
  String _transcript = '';
  final WhisperService _whisper = WhisperService();
  final GeminiService _gemini = GeminiService();

  @override
  void initState() {
    super.initState();
    _requestMic();
  }

  Future<void> _requestMic() async {
    final status = await Permission.microphone.request();
    setState(() => _micGranted = status.isGranted);
  }

  void _startListen() async {
    if (!_micGranted) return;
    final transcript = await _whisper.transcribeRecentClip();
    setState(() => _transcript = transcript);
    final suggestions = await _gemini.suggestSongs(transcript);
    if (suggestions.isNotEmpty && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SuggestionsScreen(suggestions: suggestions),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Listening…')),
      body: _micGranted
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Listening to reel audio…',
                      style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text('Transcript: $_transcript',
                      style: const TextStyle(fontSize: 16)),
                ],
              ),
            )
          : const Center(child: Text('Microphone permission denied')),
      floatingActionButton: FloatingActionButton(
        onPressed: _startListen,
        tooltip: 'Listen',
        child: const Icon(Icons.mic),
      ),
    );
  }
}