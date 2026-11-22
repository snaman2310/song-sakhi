// For the web build we use a placeholder transcript.
// On Android/iOS you can later re‑enable the `flutter_whisper` package
// (see the README) to get real on‑device transcription.
class WhisperService {
  Future<String> transcribeRecentClip() async {
    // In a real app you would capture ~3 s of PCM 16 kHz mono audio and pass the bytes
    // to Faster‑Whisper (or a web‑compatible ASR). For now return a placeholder.
    return 'Boys a Lose';
  }
}