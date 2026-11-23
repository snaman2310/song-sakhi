import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:record/record.dart';

import '../gemini_service.dart';

/// A song found while listening.
class LiveSong {
  final String title;
  final String artist;

  /// True when both pipelines (Whisper lyrics + Gemini audio) found it.
  final bool bothAgree;

  const LiveSong({
    required this.title,
    required this.artist,
    this.bothAgree = false,
  });

  /// Normalised title used to de-duplicate songs heard in overlapping chunks.
  String get key => keyFor(title);

  static String keyFor(String title) => title
      .toLowerCase()
      .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), ' ')
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .trim();
}

/// Listens continuously (up to [maxSeconds]) and reports songs as they are found.
///
/// Audio is captured as a raw 16 kHz mono PCM stream and cut into overlapping
/// 10 s WAV windows every 8 s (the 2 s overlap means a song that straddles a cut
/// is still heard in one piece). Every window is sent to the backend
/// (`/api/identify-chunk`) without blocking the recording, so results appear
/// while the reel is still playing.
///
/// Free-tier budget for a full 40 s listen: 5 windows ≈ 50 s of audio and
/// 5 requests, and near-silent windows are skipped locally.
class LiveListener {
  static const int sampleRate = 16000;
  static const int _bytesPerSecond = sampleRate * 2; // 16-bit mono
  static const int maxSeconds = 40;
  static const int _chunkSeconds = 10;
  static const int _hopSeconds = 8;
  static const int _minTailSeconds = 3;

  /// Windows quieter than this (RMS of 16-bit samples) are not uploaded.
  static const double _silenceRms = 120;

  LiveListener({
    required this.onSongs,
    required this.onElapsed,
    required this.onLevel,
    required this.onNotice,
    required this.onError,
    required this.onStopped,
    required this.onFinished,
  });

  /// New songs, or songs whose "both agree" status was upgraded.
  final void Function(List<LiveSong> songs) onSongs;
  final void Function(int seconds) onElapsed;

  /// Microphone level, roughly 0..1, for the pulsing mic button.
  final void Function(double level) onLevel;
  final void Function(String message) onNotice;
  final void Function(String message) onError;

  /// Recording has ended (tap, or the 40 s limit was reached).
  final void Function() onStopped;

  /// Recording ended AND every pending chunk has been answered.
  final void Function() onFinished;

  final AudioRecorder _recorder = AudioRecorder();
  final GeminiService _gemini = GeminiService();
  final Map<String, LiveSong> _seen = {};

  StreamSubscription<Uint8List>? _sub;
  BytesBuilder _all = BytesBuilder();
  int _nextStart = 0;
  int _dispatched = 0;
  int _pending = 0;
  int _lastElapsed = -1;
  bool _listening = false;
  bool _finishing = false;
  bool _disposed = false;

  bool get isListening => _listening;

  /// Returns false when the microphone permission was denied.
  Future<bool> start() async {
    if (_listening || _finishing) return true;
    if (!await _recorder.hasPermission()) return false;

    _all = BytesBuilder();
    _nextStart = 0;
    _dispatched = 0;
    _pending = 0;
    _lastElapsed = -1;
    _seen.clear();

    // Echo cancellation / noise suppression would try to remove exactly the
    // speaker audio we want to hear, so both are off; auto-gain helps with
    // quiet speakers.
    final stream = await _recorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: sampleRate,
      numChannels: 1,
      autoGain: true,
      echoCancel: false,
      noiseSuppress: false,
    ));
    _listening = true;
    _sub = stream.listen(
      _onData,
      onError: (Object e) {
        onError('Microphone error: $e');
        stop();
      },
    );
    return true;
  }

  void _onData(Uint8List data) {
    if (!_listening || _disposed) return;
    _all.add(data);
    onLevel((_rms(data) / 5000).clamp(0.0, 1.0).toDouble());

    final total = _all.length;
    final elapsed = total ~/ _bytesPerSecond;
    if (elapsed != _lastElapsed) {
      _lastElapsed = elapsed;
      onElapsed(elapsed);
    }

    const chunkBytes = _chunkSeconds * _bytesPerSecond;
    const hopBytes = _hopSeconds * _bytesPerSecond;
    while (total >= _nextStart + chunkBytes) {
      _dispatch(_nextStart, _nextStart + chunkBytes);
      _nextStart += hopBytes;
      _dispatched++;
    }

    if (total >= maxSeconds * _bytesPerSecond) stop();
  }

  Future<void> stop() async {
    if (!_listening) return;
    _listening = false;
    _finishing = true;
    await _sub?.cancel();
    _sub = null;
    try {
      await _recorder.stop();
    } catch (_) {}
    if (_disposed) return;
    onLevel(0);
    onStopped();

    // Analyse whatever audio is left after the last full window.
    const chunkBytes = _chunkSeconds * _bytesPerSecond;
    const hopBytes = _hopSeconds * _bytesPerSecond;
    final total = _all.length;
    final coveredEnd =
        _dispatched == 0 ? 0 : (_nextStart - hopBytes + chunkBytes);
    final minTail = (_dispatched == 0 ? 2 : _minTailSeconds) * _bytesPerSecond;
    if (total - coveredEnd >= minTail) {
      _dispatch(math.max(0, total - chunkBytes), total);
    }
    _checkFinished();
  }

  void _dispatch(int from, int to) {
    final pcm = Uint8List.sublistView(_all.toBytes(), from, to);
    if (_rms(pcm) < _silenceRms) {
      onNotice('Quiet stretch skipped. Keep the speaker closer to the mic.');
      return;
    }
    _analyse(_wav(pcm));
  }

  Future<void> _analyse(Uint8List wav) async {
    _pending++;
    try {
      final found = await _gemini.identifyChunk(wav);
      final updated = <LiveSong>[];
      for (final s in found) {
        final song = LiveSong(
          title: s['title'] ?? '',
          artist: s['artist'] ?? 'Unknown artist',
          bothAgree: (s['via'] ?? '').contains('+'),
        );
        if (song.key.isEmpty) continue;
        final prev = _seen[song.key];
        if (prev == null) {
          _seen[song.key] = song;
          updated.add(song);
        } else if (song.bothAgree && !prev.bothAgree) {
          _seen[song.key] = song;
          updated.add(song);
        }
      }
      if (updated.isNotEmpty && !_disposed) onSongs(updated);
    } on GeminiException catch (e) {
      if (!_disposed) onError(e.message);
    } catch (e) {
      if (!_disposed) onError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _pending--;
      _checkFinished();
    }
  }

  void _checkFinished() {
    if (_finishing && !_listening && _pending == 0 && !_disposed) {
      _finishing = false;
      onFinished();
    }
  }

  void dispose() {
    _disposed = true;
    _sub?.cancel();
    _recorder.dispose();
  }

  static double _rms(Uint8List bytes) {
    final n = bytes.lengthInBytes ~/ 2;
    if (n == 0) return 0;
    final bd = ByteData.sublistView(bytes);
    var sum = 0.0;
    for (var i = 0; i < n; i++) {
      final v = bd.getInt16(i * 2, Endian.little);
      sum += v * v;
    }
    return math.sqrt(sum / n);
  }

  /// Wraps raw 16-bit mono PCM in a 44-byte WAV header.
  static Uint8List _wav(Uint8List pcm) {
    final h = ByteData(44);
    void tag(int offset, String text) {
      for (var i = 0; i < text.length; i++) {
        h.setUint8(offset + i, text.codeUnitAt(i));
      }
    }

    tag(0, 'RIFF');
    h.setUint32(4, 36 + pcm.length, Endian.little);
    tag(8, 'WAVE');
    tag(12, 'fmt ');
    h.setUint32(16, 16, Endian.little); // fmt chunk size
    h.setUint16(20, 1, Endian.little); // PCM
    h.setUint16(22, 1, Endian.little); // mono
    h.setUint32(24, sampleRate, Endian.little);
    h.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    h.setUint16(32, 2, Endian.little); // block align
    h.setUint16(34, 16, Endian.little); // bits per sample
    tag(36, 'data');
    h.setUint32(40, pcm.length, Endian.little);

    final out = BytesBuilder(copy: false)
      ..add(h.buffer.asUint8List())
      ..add(pcm);
    return out.toBytes();
  }
}
