import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../gemini_service.dart';

/// Records a short audio clip and asks Gemini to identify songs from it.
class MobileAudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final GeminiService _gemini = GeminiService();

  Future<String?> recordClip({int seconds = 5}) async {
    if (!await _recorder.hasPermission()) return null;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/reel_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 96000, sampleRate: 44100),
      path: path,
    );
    await Future.delayed(Duration(seconds: seconds));
    return await _recorder.stop();
  }

  Future<List<Map<String, String>>> identifySongs(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    return _gemini.identifyFromAudio(base64Encode(bytes));
  }

  void dispose() => _recorder.dispose();
}
