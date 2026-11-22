import 'package:flutter_whisper/flutter_whisper.dart';

class WhisperService {
  final FlutterWhisper _whisper = FlutterWhisper();

  Future<String> transcribeRecentClip() async {
    // In a real app you would capture ~3 s of PCM 16 kHz mono audio and pass the bytes.
    // For now return a placeholder.
    return 'Boys a Lose';
  }
}