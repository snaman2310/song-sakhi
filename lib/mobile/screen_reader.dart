import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Thin wrapper around the native `CaptureService` (see deploy/android/kotlin).
///
/// The native side holds a screen-capture session and a foreground service. The
/// foreground service is also what keeps the microphone usable while the user is
/// inside Instagram, so it is started even when screen reading is declined.
class ScreenCapture {
  ScreenCapture._();

  static const MethodChannel _channel = MethodChannel('song_sakhi/capture');
  static final StreamController<void> _stopped = StreamController<void>.broadcast();
  static bool _handlerInstalled = false;

  /// Fires when the system or the user ends screen sharing.
  static Stream<void> get stopped {
    _installHandler();
    return _stopped.stream;
  }

  static void _installHandler() {
    if (_handlerInstalled) return;
    _handlerInstalled = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'captureStopped') _stopped.add(null);
      return null;
    });
  }

  /// Asks for screen-capture consent and starts the service. False if declined.
  static Future<bool> start() async {
    _installHandler();
    try {
      return (await _channel.invokeMethod<bool>('start')) ?? false;
    } on PlatformException catch (e) {
      debugPrint('ScreenCapture.start failed: ${e.code} ${e.message}');
      return false;
    }
  }

  /// Starts only the background-mic foreground service (no screen reading).
  static Future<bool> startMicOnly() async {
    _installHandler();
    try {
      return (await _channel.invokeMethod<bool>('startMicOnly')) ?? false;
    } on PlatformException catch (e) {
      debugPrint('ScreenCapture.startMicOnly failed: ${e.code} ${e.message}');
      return false;
    }
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod<bool>('stop');
    } on PlatformException catch (_) {}
  }

  /// Path of a fresh JPEG screenshot, or null (screen unchanged, or not capturing).
  static Future<String?> captureFrame() async {
    try {
      return await _channel.invokeMethod<String>('captureFrame');
    } on PlatformException catch (_) {
      return null;
    }
  }
}

/// Takes a screenshot and reads the text on it, on the device (free, offline).
class ScreenReader {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Text lines currently on screen that could plausibly be song info.
  Future<List<String>> readFrame() async {
    final path = await ScreenCapture.captureFrame();
    if (path == null) return const [];
    final result = await _recognizer.processImage(InputImage.fromFilePath(path));
    final out = <String>[];
    for (final block in result.blocks) {
      for (final line in block.lines) {
        final t = line.text.trim();
        if (_keep(t)) out.add(t);
      }
    }
    return out;
  }

  // App chrome and our own overlay text are never song titles. The backend asks
  // Gemini to ignore the rest, this just saves requests.
  static final RegExp _noise = RegExp(
    r'^(follow(ing)?|like[sd]?|comments?|share|send|reply|view (all )?\d* ?(more )?(replies|comments)|'
    r'see translation|original audio|sponsored|suggested for you|add (a )?comment|more|'
    r'liked by.*|\d+([.,]\d+)?\s?[kKmM]?|\d+\s?[smhdw]|'
    r'listening.*|finishing.*|tap .*|save .*|dismiss|on[- ]screen|both|guess|back|spotify|youtube.*)$',
    caseSensitive: false,
  );
  static final RegExp _letters = RegExp(r'[A-Za-zÀ-ɏ]');

  static bool _keep(String t) {
    if (t.length < 3 || t.length > 90) return false;
    if (t.startsWith('@') || t.startsWith('#')) return false;
    if (_noise.hasMatch(t)) return false;
    return _letters.allMatches(t).length >= 3;
  }

  void dispose() => _recognizer.close();
}
