import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

// The overlay runs in its own Flutter engine, so it deliberately uses no
// plugins and no app theme: it only renders the JSON state it receives from
// NudgeController (main isolate) and sends taps back.

const Color _bg = Color(0xF2171717);
const Color _card = Color(0xFF262626);
const Color _green = Color(0xFF53E076);
const Color _amber = Color(0xFFFFB800);
const Color _text = Color(0xFFE5E2E1);
const Color _muted = Color(0xFFA9B5A7);

class NudgeOverlayApp extends StatelessWidget {
  const NudgeOverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const Material(
        color: Colors.transparent,
        child: _OverlayHome(),
      ),
    );
  }
}

class _OverlayHome extends StatefulWidget {
  const _OverlayHome();

  @override
  State<_OverlayHome> createState() => _OverlayHomeState();
}

class _OverlayHomeState extends State<_OverlayHome>
    with SingleTickerProviderStateMixin {
  late final AnimationController _beats = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  Map<String, dynamic> _s = const {'phase': 'idle', 'compact': true};

  String get _phase => (_s['phase'] ?? 'idle').toString();
  bool get _compact => _s['compact'] != false;
  List<Map<String, dynamic>> get _songs => _list('songs');
  List<Map<String, dynamic>> get _playlists => _list('playlists');
  String? get _message => _s['message']?.toString();

  List<Map<String, dynamic>> _list(String key) {
    final v = _s[key];
    if (v is! List) return const [];
    return [
      for (final e in v)
        if (e is Map) Map<String, dynamic>.from(e),
    ];
  }

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen(_onData);
    _send({'a': 'ready'});
  }

  @override
  void dispose() {
    _beats.dispose();
    super.dispose();
  }

  void _onData(dynamic raw) {
    try {
      final d = jsonDecode(raw.toString());
      // Only state messages carry a 'phase'; our own taps echo back without one.
      if (d is! Map || !d.containsKey('phase')) return;
      final next = Map<String, dynamic>.from(d);
      final listening = next['phase'] == 'listening' || next['phase'] == 'finishing';
      if (listening && !_beats.isAnimating) {
        _beats.repeat();
      } else if (!listening && _beats.isAnimating) {
        _beats.stop();
      }
      if (mounted) setState(() => _s = next);
    } catch (_) {}
  }

  void _send(Map<String, dynamic> m) {
    try {
      FlutterOverlayWindow.shareData(jsonEncode(m));
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------

  double _lw = 0;

  // Tell the main isolate how big this window really is (in dp) so it can
  // correct the size units used when resizing.
  void _reportSize(double w, double h) {
    if ((w - _lw).abs() < 1) return;
    _lw = w;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _send({'a': 'size', 'w': w, 'h': h});
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      _reportSize(c.maxWidth, c.maxHeight);
      return _content(c);
    });
  }

  Widget _content(BoxConstraints c) {
    if (_compact) {
      // Nudge 1: just the circle, filling its window.
      final d = (math.min(c.maxWidth, c.maxHeight) - 4).clamp(24.0, 300.0).toDouble();
      return Center(
        child: _BeatsCircle(
          anim: _beats,
          active: _phase == 'listening' || _phase == 'finishing',
          size: d,
          onTap: () => _send({'a': 'tap'}),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x3353E076)),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 14)],
        ),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            const SizedBox(height: 6),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final n = _songs.length;
    final elapsed = _s['elapsed'] ?? 0;
    final max = _s['max'] ?? 40;
    String title;
    String sub;
    switch (_phase) {
      case 'listening':
        title = 'Listening… ${elapsed}s / ${max}s';
        sub = _s['screenOn'] == true ? 'Hearing + reading screen · tap to stop' : 'Tap the circle to stop';
      case 'finishing':
        title = 'Finishing up…';
        sub = 'Checking the last bit';
      case 'selecting':
        title = n == 0 ? 'Nothing found' : '$n song${n == 1 ? '' : 's'} found';
        sub = n == 0 ? 'Tap the circle to try again' : 'Tap songs to choose';
      case 'picking':
        title = 'Save to…';
        sub = 'Pick a playlist';
      case 'saving':
        title = 'Saving…';
        sub = 'Hang on';
      case 'done':
        title = 'Saved!';
        sub = 'Back to the reel';
      default:
        title = '';
        sub = '';
    }
    return Row(
      children: [
        _BeatsCircle(
          anim: _beats,
          active: _phase == 'listening' || _phase == 'finishing',
          size: 44,
          onTap: () => _send({'a': 'tap'}),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: _text, fontSize: 14, fontWeight: FontWeight.w700)),
              Text(sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 11)),
            ],
          ),
        ),
        InkWell(
          onTap: () => _send({'a': 'dismiss'}),
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.close, size: 18, color: _muted),
          ),
        ),
      ],
    );
  }

  Widget _body() {
    switch (_phase) {
      case 'listening':
      case 'finishing':
        return _songList(selectable: false);
      case 'selecting':
        return Column(
          children: [
            Expanded(child: _songList(selectable: true)),
            if (_songs.isNotEmpty) _saveButton(),
          ],
        );
      case 'picking':
        return _picker();
      case 'saving':
        return const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3, color: _green),
          ),
        );
      case 'done':
        return Center(
          child: Text(
            (_s['saved'] ?? 'Saved').toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: _text, fontSize: 13),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // Nudge 2: songs drop in one by one, then become tickable.
  Widget _songList({required bool selectable}) {
    final songs = _songs;
    return Column(
      children: [
        if (_message != null && _phase != 'done')
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(_message!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _amber, fontSize: 11)),
          ),
        Expanded(
          child: songs.isEmpty
              ? const SizedBox.shrink()
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: songs.length,
                  itemBuilder: (context, i) => _SongRow(
                    key: ValueKey(songs[i]['id']),
                    song: songs[i],
                    selectable: selectable,
                    onTap: () => _send({'a': 'toggle', 'id': songs[i]['id']}),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _saveButton() {
    final count = _songs.where((s) => s['selected'] == true).length;
    return SizedBox(
      height: 40,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: count == 0 ? null : () => _send({'a': 'save'}),
        icon: const Icon(Icons.playlist_add, size: 18),
        label: Text(count == 0 ? 'Pick songs to save' : 'Save $count to playlist'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: const Color(0xFF003914),
          disabledBackgroundColor: _card,
          disabledForegroundColor: _muted,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  // Nudge 3: choose where to save.
  Widget _picker() {
    final provider = (_s['provider'] ?? 'spotify').toString();
    final loading = _s['loadingPlaylists'] == true;
    final lists = _playlists;
    return Column(
      children: [
        Row(
          children: [
            _chip('Spotify', provider == 'spotify', () => _send({'a': 'provider', 'v': 'spotify'})),
            const SizedBox(width: 8),
            _chip('YouTube Music', provider == 'youtube', () => _send({'a': 'provider', 'v': 'youtube'})),
          ],
        ),
        const SizedBox(height: 6),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(_message!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _amber, fontSize: 11)),
          ),
        Expanded(
          child: loading
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 3, color: _green),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: lists.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _send({'a': 'pick', 'id': lists[i]['id']}),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.library_music, size: 18, color: _green),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                (lists[i]['name'] ?? '').toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: _text, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
        TextButton(
          onPressed: () => _send({'a': 'back'}),
          child: const Text('Back', style: TextStyle(color: _muted, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? _green : _card,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? const Color(0xFF003914) : _muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One song row. It slides down and fades in the first time it is built, which
/// is what makes songs "drop" into the list as they are found.
class _SongRow extends StatelessWidget {
  final Map<String, dynamic> song;
  final bool selectable;
  final VoidCallback onTap;

  const _SongRow({
    super.key,
    required this.song,
    required this.selectable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = song['selected'] == true;
    final tag = (song['tag'] ?? 'guess').toString();
    final artist = (song['artist'] ?? '').toString();
    final trusted = tag != 'guess';

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, (1 - v) * -22), child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: selectable ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: selectable && selected ? const Color(0x2253E076) : _card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectable && selected ? _green : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                if (selectable)
                  Icon(
                    selected ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 20,
                    color: selected ? _green : _muted,
                  )
                else
                  const Icon(Icons.music_note, size: 18, color: _green),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (song['title'] ?? '').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: _text, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      if (artist.isNotEmpty)
                        Text(
                          artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _muted, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (trusted ? _green : _amber).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tag == 'on-screen' ? 'on screen' : tag,
                    style: TextStyle(
                      color: trusted ? _green : _amber,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Nudge 1. A round button with music beats: calm green bars when idle; while
/// listening the bars become colourful and a wave of colour sweeps left to right.
class _BeatsCircle extends StatelessWidget {
  final Animation<double> anim;
  final bool active;
  final double size;
  final VoidCallback onTap;

  const _BeatsCircle({
    required this.anim,
    required this.active,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF161616),
          border: Border.all(color: _green, width: 2),
          boxShadow: [
            BoxShadow(
              color: _green.withValues(alpha: active ? 0.55 : 0.25),
              blurRadius: active ? 16 : 8,
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: anim,
          builder: (context, _) => CustomPaint(
            painter: _BeatsPainter(t: anim.value, active: active),
          ),
        ),
      ),
    );
  }
}

class _BeatsPainter extends CustomPainter {
  final double t;
  final bool active;

  const _BeatsPainter({required this.t, required this.active});

  static const int _bars = 5;
  static const List<double> _idle = [0.28, 0.55, 0.85, 0.55, 0.28];

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width * 0.09;
    final gap = size.width * 0.065;
    final total = _bars * barWidth + (_bars - 1) * gap;
    final left = (size.width - total) / 2;
    final maxH = size.height * 0.5;

    for (var i = 0; i < _bars; i++) {
      double h;
      Color color;
      if (active) {
        // The peak of the wave moves toward higher i (left to right) over time,
        // and so does the colour.
        final wave = (math.sin(2 * math.pi * t - i * 1.1) + 1) / 2;
        h = maxH * (0.22 + 0.78 * wave);
        final hue = ((t * 360) - i * 55) % 360;
        color = HSVColor.fromAHSV(1, hue < 0 ? hue + 360 : hue, 0.75, 1).toColor();
      } else {
        h = maxH * _idle[i];
        color = _green;
      }
      final x = left + i * (barWidth + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, (size.height - h) / 2, barWidth, h),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_BeatsPainter old) => old.t != t || old.active != active;
}
