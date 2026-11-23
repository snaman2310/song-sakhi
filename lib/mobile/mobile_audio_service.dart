import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../gemini_service.dart';

/// Records a short audio clip and asks Gemini to identify songs from it.
///
/// The clip is captured as 16 kHz mono WAV because Gemini's inline-audio API
/// officially supports `audio/wav`; the M4A/AAC container produced by the
/// default encoder is frequently rejected with "unsupported MIME type".
class MobileAudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final GeminiService _gemini = GeminiService();

  Future<String?> recordClip({int seconds = 8}) async {
    if (!await _recorder.hasPermission()) return null;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/reel_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
    await Future.delayed(Duration(seconds: seconds));
    final result = await _recorder.stop();
    return result ?? (File(path).existsSync() ? path : null);
  }

  Future<List<Map<String, String>>> identifySongs(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    if (bytes.isEmpty) {
      throw const GeminiException(
        'The recording was empty. Check that the microphone is not blocked and try again.',
        code: 'EMPTY_AUDIO',
      );
    }
    return _gemini.identifyFromAudio(base64Encode(bytes), mimeType: 'audio/wav');
  }

  void dispose() => _recorder.dispose();
}
