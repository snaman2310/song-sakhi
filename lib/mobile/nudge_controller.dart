import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';

import '../auth_service.dart';
import '../gemini_service.dart';
import '../local_store.dart';
import '../playlist_service.dart';
import 'mobile_live_listener.dart';
import 'screen_reader.dart';

enum NudgePhase { idle, listening, finishing, selecting, picking, saving, done }

/// A song found during a nudge session.
class NudgeSong {
  final String key;
  String title;
  String artist;
  bool selected;

  /// Seen as text on the reel (the creator typed it, so we trust it most).
  bool onScreen;

  /// Both audio pipelines (lyrics + audio) agreed on it.
  bool bothModels;

  /// The user toggled it by hand, so later evidence must not override that.
  bool touched = false;

  NudgeSong({
    required this.key,
    required this.title,
    required this.artist,
    this.selected = false,
    this.onScreen = false,
    this.bothModels = false,
  });

  bool get trusted => onScreen || bothModels;

  String get tag => onScreen ? 'on-screen' : (bothModels ? 'both' : 'guess');
}

/// Runs the floating nudge.
///
/// This lives in the main Dart isolate. The overlay (see nudge_overlay.dart) is
/// only a renderer: it receives the full state as JSON and sends back taps.
///
/// One session = up to 40 s of listening. While it runs, the microphone (audio
/// pipelines) and the screen (OCR of reel text) are both read, and every song
/// is added to the overlay the moment it is found.
class NudgeController {
  NudgeController._();
  static final NudgeController instance = NudgeController._();

  static const int _overlayWidth = 300;

  /// True while the floating circle is shown.
  final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);

  final PlaylistService _playlists = PlaylistService();
  final GeminiService _gemini = GeminiService();
  final ScreenReader _reader = ScreenReader();

  StreamSubscription<dynamic>? _overlaySub;
  StreamSubscription<void>? _captureStopSub;
  LiveListener? _listener;
  Timer? _ocrTimer;
  Timer? _doneTimer;

  int _session = 0;
  NudgePhase _phase = NudgePhase.idle;
  final List<NudgeSong> _songs = [];
  bool _screenOn = false;
  int _elapsed = 0;
  String? _message;
  String? _savedLabel;
  String _provider = 'spotify';
  List<Playlist> _playlistList = [];
  bool _loadingPlaylists = false;

  bool _audioDone = false;
  bool _ocrDone = false;
  bool _ocrBusy = false;
  DateTime _lastFlush = DateTime.now();
  final Set<String> _lineSeen = {};
  final List<String> _pendingLines = [];

  int _lastW = 0;
  int _lastH = 0;

  // ------------------------------------------------------------------------
  // Turning the nudge on / off (called from the Home screen)
  // ------------------------------------------------------------------------

  /// Returns null on success, otherwise a message to show the user.
  Future<String?> enable() async {
    if (enabled.value) return null;

    var overlayOk = await FlutterOverlayWindow.isPermissionGranted();
    if (!overlayOk) {
      overlayOk = (await FlutterOverlayWindow.requestPermission()) ?? false;
    }
    if (!overlayOk) {
      return 'Allow "Display over other apps" for Song Sakhi so the nudge can float over reels.';
    }

    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      return 'Microphone permission is needed to listen to reels.';
    }
    await Permission.notification.request(); // optional, only for the status notice

    // Screen reading (OCR). If declined we still start the background mic
    // service, because the nudge must keep hearing audio inside Instagram.
    _screenOn = await ScreenCapture.start();
    if (!_screenOn) {
      final micService = await ScreenCapture.startMicOnly();
      if (!micService) {
        return 'Could not start the background listener. Check notification and microphone permissions.';
      }
    }

    try {
      await FlutterOverlayWindow.showOverlay(
        height: 64,
        width: 64,
        alignment: OverlayAlignment.centerRight,
        enableDrag: true,
        overlayTitle: 'Song Sakhi nudge',
        overlayContent: 'Tap the circle over a reel to find its songs',
      );
    } catch (e) {
      await ScreenCapture.stop();
      return 'Could not show the floating nudge: $e';
    }

    _lastW = 64;
    _lastH = 64;
    _overlaySub = FlutterOverlayWindow.overlayListener.listen(_onOverlayMessage);
    _captureStopSub = ScreenCapture.stopped.listen((_) {
      _screenOn = false;
      _message = 'Screen reading stopped. Turn the nudge off and on to bring it back.';
      _push();
    });

    _resetToIdle();
    enabled.value = true;
    if (!_screenOn) {
      _message = 'Screen reading is off, so only audio is used.';
    }
    _push();
    return null;
  }

  Future<void> disable() async {
    await _teardownSession();
    _doneTimer?.cancel();
    await _overlaySub?.cancel();
    _overlaySub = null;
    await _captureStopSub?.cancel();
    _captureStopSub = null;
    try {
      await FlutterOverlayWindow.closeOverlay();
    } catch (_) {}
    await ScreenCapture.stop();
    _screenOn = false;
    _resetToIdle();
    enabled.value = false;
  }

  // ------------------------------------------------------------------------
  // Messages from the overlay
  // ------------------------------------------------------------------------

  void _onOverlayMessage(dynamic raw) {
    final Map<String, dynamic> m;
    try {
      final decoded = jsonDecode(raw.toString());
      if (decoded is! Map) return;
      m = Map<String, dynamic>.from(decoded);
    } catch (_) {
      return;
    }
    // State messages we sent ourselves have no 'a' key and are ignored here.
    switch (m['a']) {
      case 'ready':
        _lastW = 0; // force a resize + state push for a freshly started overlay
        _push();
      case 'tap':
        _onCircleTap();
      case 'toggle':
        _toggleSong(m['id']?.toString());
      case 'save':
        _openPicker();
      case 'provider':
        final v = m['v']?.toString();
        if (v == 'spotify' || v == 'youtube') {
          _provider = v!;
          _loadPlaylists();
        }
      case 'pick':
        final id = m['id']?.toString();
        if (id != null) _saveTo(id);
      case 'back':
        if (_phase == NudgePhase.picking) {
          _phase = NudgePhase.selecting;
          _message = null;
          _push();
        }
      case 'dismiss':
        _dismiss();
    }
  }

  void _onCircleTap() {
    switch (_phase) {
      case NudgePhase.listening:
        _stopSession();
      case NudgePhase.idle:
      case NudgePhase.selecting:
      case NudgePhase.done:
        _startSession();
      case NudgePhase.finishing:
      case NudgePhase.picking:
      case NudgePhase.saving:
        break;
    }
  }

  void _toggleSong(String? id) {
    if (_phase != NudgePhase.selecting || id == null) return;
    for (final s in _songs) {
      if (s.key == id) {
        s.selected = !s.selected;
        s.touched = true;
      }
    }
    _message = null;
    _push();
  }

  Future<void> _dismiss() async {
    await _teardownSession();
    _resetToIdle();
    _push();
  }

  // ------------------------------------------------------------------------
  // A listening session: audio + screen at the same time
  // ------------------------------------------------------------------------

  Future<void> _startSession() async {
    await _teardownSession();
    _doneTimer?.cancel();
    final id = ++_session;

    _songs.clear();
    _lineSeen.clear();
    _pendingLines.clear();
    _elapsed = 0;
    _message = null;
    _savedLabel = null;
    _audioDone = false;
    _ocrDone = !_screenOn;
    _phase = NudgePhase.listening;
    _push();

    final listener = LiveListener(
      onSongs: (found) {
        if (id != _session) return;
        for (final s in found) {
          _upsert(title: s.title, artist: s.artist, bothModels: s.bothAgree);
        }
        _push();
      },
      onElapsed: (s) {
        if (id != _session) return;
        _elapsed = s;
        _push();
      },
      onLevel: (_) {},
      onNotice: (m) {
        if (id != _session) return;
        _message = m;
        _push();
      },
      onError: (m) {
        if (id != _session) return;
        _message = m;
        _push();
      },
      onStopped: () {
        // The 40 s limit ended the recording on its own.
        if (id == _session && _phase == NudgePhase.listening) _stopSession();
      },
      onFinished: () {
        if (id != _session) return;
        _audioDone = true;
        _maybeFinish();
      },
    );
    _listener = listener;

    final ok = await listener.start();
    if (id != _session) return;
    if (!ok) {
      _message = 'Microphone permission was denied.';
      _resetToIdle(keepMessage: true);
      _push();
      return;
    }

    if (_screenOn) {
      _lastFlush = DateTime.now();
      _ocrTimer = Timer.periodic(const Duration(seconds: 2), (_) => _ocrTick());
    }
  }

  Future<void> _stopSession() async {
    if (_phase != NudgePhase.listening) return;
    final id = _session;
    _phase = NudgePhase.finishing;
    _push();

    _ocrTimer?.cancel();
    _ocrTimer = null;
    await _listener?.stop();

    if (_screenOn) {
      var waited = 0;
      while (_ocrBusy && waited < 8000) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        waited += 100;
      }
      await _ocrTick(last: true);
    }
    if (id != _session) return;
    _ocrDone = true;
    _maybeFinish();
  }

  Future<void> _teardownSession() async {
    _session++; // invalidates every callback of the old session
    _ocrTimer?.cancel();
    _ocrTimer = null;
    final l = _listener;
    _listener = null;
    if (l != null) {
      try {
        await l.stop();
      } catch (_) {}
      l.dispose();
    }
  }

  void _maybeFinish() {
    if (_phase != NudgePhase.finishing || !_audioDone || !_ocrDone) return;
    // Trusted songs (on screen / both models) first.
    final trusted = _songs.where((s) => s.trusted).toList();
    final rest = _songs.where((s) => !s.trusted).toList();
    _songs
      ..clear()
      ..addAll(trusted)
      ..addAll(rest);
    _phase = NudgePhase.selecting;
    if (_songs.isEmpty) {
      _message = 'No song found. Tap the circle to try again.';
    }
    _push();
  }

  // ------------------------------------------------------------------------
  // Screen reading
  // ------------------------------------------------------------------------

  Future<void> _ocrTick({bool last = false}) async {
    if (_ocrBusy) return;
    if (!last && _phase != NudgePhase.listening) return;
    _ocrBusy = true;
    try {
      final lines = await _reader.readFrame();
      for (final l in lines) {
        final k = _lineKey(l);
        if (k.isNotEmpty && _lineSeen.add(k)) _pendingLines.add(l);
      }
      final due = last || DateTime.now().difference(_lastFlush).inSeconds >= 5;
      if (_pendingLines.isNotEmpty && due) await _flushLines();
    } catch (e) {
      debugPrint('OCR tick failed: $e');
    } finally {
      _ocrBusy = false;
    }
  }

  Future<void> _flushLines() async {
    final batch = List<String>.from(_pendingLines);
    _pendingLines.clear();
    _lastFlush = DateTime.now();
    final id = _session;
    try {
      final found = await _gemini.identifyScreenText(batch);
      if (id != _session) return;
      for (final s in found) {
        _upsert(title: s['title'] ?? '', artist: s['artist'] ?? '', onScreen: true);
      }
      _push();
    } on GeminiException catch (e) {
      if (id != _session) return;
      _message = e.message;
      _push();
    }
  }

  static String _lineKey(String l) =>
      l.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

  // ------------------------------------------------------------------------
  // Song bookkeeping
  // ------------------------------------------------------------------------

  static bool _validArtist(String a) {
    final t = a.trim().toLowerCase();
    return t.isNotEmpty && !t.startsWith('unknown');
  }

  void _upsert({
    required String title,
    required String artist,
    bool onScreen = false,
    bool bothModels = false,
  }) {
    final key = LiveSong.keyFor(title);
    if (key.isEmpty) return;
    NudgeSong? existing;
    for (final s in _songs) {
      if (s.key == key) existing = s;
    }
    if (existing == null) {
      final song = NudgeSong(
        key: key,
        title: title.trim(),
        artist: _validArtist(artist) ? artist.trim() : '',
        onScreen: onScreen,
        bothModels: bothModels,
      );
      // Without screen reading every song is a guess, so keep them all ticked.
      song.selected = song.trusted || !_screenOn;
      _songs.add(song);
      return;
    }
    existing.onScreen = existing.onScreen || onScreen;
    existing.bothModels = existing.bothModels || bothModels;
    if (onScreen) existing.title = title.trim(); // what the creator typed wins
    if (_validArtist(artist) && (onScreen || !_validArtist(existing.artist))) {
      existing.artist = artist.trim();
    }
    if (!existing.touched && existing.trusted) existing.selected = true;
  }

  // ------------------------------------------------------------------------
  // Saving to a playlist
  // ------------------------------------------------------------------------

  Future<void> _openPicker() async {
    if (_phase != NudgePhase.selecting) return;
    if (!_songs.any((s) => s.selected)) {
      _message = 'Tick at least one song first.';
      _push();
      return;
    }
    final auth = AuthService();
    final spotify = await auth.isConnected('spotify');
    final youtube = await auth.isConnected('google');
    _provider = spotify ? 'spotify' : (youtube ? 'youtube' : 'spotify');
    _phase = NudgePhase.picking;
    _message = (!spotify && !youtube)
        ? 'Connect Spotify or YouTube Music in the app first.'
        : null;
    _playlistList = [];
    _push();
    if (spotify || youtube) await _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    _loadingPlaylists = true;
    _playlistList = [];
    _message = null;
    _push();
    try {
      final token = await AuthService()
          .freshToken(_provider == 'spotify' ? 'spotify' : 'google');
      if (token == null || token.isEmpty) {
        throw Exception('Not connected to ${_provider == 'spotify' ? 'Spotify' : 'YouTube Music'}.');
      }
      _playlistList = _provider == 'spotify'
          ? await _playlists.spotifyPlaylists(token)
          : await _playlists.youtubePlaylists(token);
      if (_playlistList.isEmpty) _message = 'No playlists found on this service.';
    } catch (e) {
      _message = e.toString().replaceAll('Exception: ', '');
    } finally {
      _loadingPlaylists = false;
      _push();
    }
  }

  Future<void> _saveTo(String playlistId) async {
    if (_phase != NudgePhase.picking) return;
    final chosen = _songs.where((s) => s.selected).toList();
    if (chosen.isEmpty) return;
    _phase = NudgePhase.saving;
    _message = null;
    _push();

    try {
      final token = await AuthService()
          .freshToken(_provider == 'spotify' ? 'spotify' : 'google');
      if (token == null || token.isEmpty) throw Exception('Missing access token.');

      final ids = <String>[];
      final missing = <String>[];
      for (final s in chosen) {
        final id = _provider == 'spotify'
            ? await _playlists.spotifyTrackUri(token, s.title, s.artist)
            : await _playlists.youtubeVideoId(token, s.title, s.artist);
        if (id != null && id.isNotEmpty) {
          ids.add(id);
        } else {
          missing.add(s.title);
        }
      }
      if (ids.isEmpty) {
        throw Exception('None of these songs were found on this service. Try the other one.');
      }
      if (_provider == 'spotify') {
        await _playlists.addToSpotify(token, playlistId, ids);
      } else {
        await _playlists.addToYouTube(token, playlistId, ids);
      }

      final name = _playlistList
          .firstWhere((p) => p.id == playlistId,
              orElse: () => const Playlist(id: '', name: 'your playlist', count: 0))
          .name;
      final store = LocalStore();
      await store.addSongs(<Map<String, String>>[
        for (final s in chosen) {'title': s.title, 'artist': s.artist},
      ]);
      await store.setLastPlaylist(name);

      _savedLabel = '${ids.length} song${ids.length == 1 ? '' : 's'} added to "$name"'
          '${missing.isEmpty ? '' : '\nNot found: ${missing.join(', ')}'}';
      _phase = NudgePhase.done;
      _push();
      _doneTimer?.cancel();
      _doneTimer = Timer(const Duration(seconds: 4), () {
        if (_phase == NudgePhase.done) {
          _resetToIdle();
          _push();
        }
      });
    } catch (e) {
      _phase = NudgePhase.picking;
      _message = e.toString().replaceAll('Exception: ', '');
      _push();
    }
  }

  // ------------------------------------------------------------------------
  // State -> overlay
  // ------------------------------------------------------------------------

  void _resetToIdle({bool keepMessage = false}) {
    _songs.clear();
    _lineSeen.clear();
    _pendingLines.clear();
    _playlistList = [];
    _loadingPlaylists = false;
    _elapsed = 0;
    _savedLabel = null;
    if (!keepMessage) _message = null;
    _phase = NudgePhase.idle;
  }

  ({int w, int h, bool compact}) _layout() {
    final n = _songs.length;
    final p = _playlistList.length;
    return switch (_phase) {
      NudgePhase.idle => (w: 64, h: 64, compact: true),
      NudgePhase.listening || NudgePhase.finishing => n == 0
          ? (w: 64, h: 64, compact: true)
          : (w: _overlayWidth, h: (120 + n * 58).clamp(180, 440).toInt(), compact: false),
      NudgePhase.selecting => (
          w: _overlayWidth,
          h: n == 0 ? 170 : (190 + n * 58).clamp(250, 520).toInt(),
          compact: false
        ),
      NudgePhase.picking => (
          w: _overlayWidth,
          h: (210 + p * 56).clamp(290, 520).toInt(),
          compact: false
        ),
      NudgePhase.saving || NudgePhase.done => (w: _overlayWidth, h: 160, compact: false),
    };
  }

  Map<String, dynamic> _stateJson(bool compact) => {
        'phase': _phase.name,
        'compact': compact,
        'elapsed': _elapsed,
        'max': LiveListener.maxSeconds,
        'screenOn': _screenOn,
        'message': _message,
        'provider': _provider,
        'loadingPlaylists': _loadingPlaylists,
        'saved': _savedLabel,
        'songs': [
          for (final s in _songs)
            {
              'id': s.key,
              'title': s.title,
              'artist': s.artist,
              'selected': s.selected,
              'tag': s.tag,
            },
        ],
        'playlists': [
          for (final p in _playlistList) {'id': p.id, 'name': p.name},
        ],
      };

  void _push() {
    if (!enabled.value && _overlaySub == null) return;
    _syncOverlay();
  }

  Future<void> _syncOverlay() async {
    final l = _layout();
    try {
      if (l.w != _lastW || l.h != _lastH) {
        _lastW = l.w;
        _lastH = l.h;
        await FlutterOverlayWindow.resizeOverlay(l.w, l.h);
      }
      await FlutterOverlayWindow.shareData(jsonEncode(_stateJson(l.compact)));
    } catch (e) {
      debugPrint('Overlay sync failed: $e');
    }
  }
}
