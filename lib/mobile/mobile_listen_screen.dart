import 'package:flutter/material.dart';

import '../gemini_service.dart';
import '../theme.dart';
import 'mobile_live_listener.dart';

/// Live "nudge" screen.
///
/// Tap the mic once to start listening (up to 40 s), tap again to stop early.
/// Songs appear in the list as soon as they are found, while the reel is still
/// playing. When listening ends, pick the ones you want and save them.
class MobileListenScreen extends StatefulWidget {
  const MobileListenScreen({super.key});

  @override
  State<MobileListenScreen> createState() => _MobileListenScreenState();
}

class _MobileListenScreenState extends State<MobileListenScreen> {
  late final LiveListener _listener;
  final List<LiveSong> _songs = [];
  final Set<String> _selected = {};

  bool _listening = false;
  bool _finishing = false;
  bool _heardSomething = false;
  int _elapsed = 0;
  double _level = 0;
  String? _notice;
  String? _error;

  @override
  void initState() {
    super.initState();
    _listener = LiveListener(
      onSongs: _onSongs,
      onElapsed: (s) => _set(() => _elapsed = s),
      onLevel: (l) => _set(() => _level = l),
      onNotice: (m) => _set(() => _notice = m),
      onError: (m) => _set(() => _error = m),
      onStopped: () => _set(() {
        _listening = false;
        _finishing = true;
      }),
      onFinished: () => _set(() => _finishing = false),
    );
    // Wake the (free-tier) backend now so the first chunk is not slow.
    GeminiService().warmUp();
  }

  void _set(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  void _onSongs(List<LiveSong> found) {
    _set(() {
      for (final song in found) {
        final i = _songs.indexWhere((s) => s.key == song.key);
        if (i >= 0) {
          _songs[i] = song;
        } else {
          _songs.add(song);
          _selected.add(song.key);
        }
      }
      _heardSomething = true;
    });
  }

  Future<void> _toggle() async {
    if (_finishing) return;
    if (_listening) {
      await _listener.stop();
      return;
    }
    setState(() {
      _songs.clear();
      _selected.clear();
      _elapsed = 0;
      _level = 0;
      _notice = null;
      _error = null;
      _heardSomething = false;
      _listening = true;
    });
    final ok = await _listener.start();
    if (!ok && mounted) {
      setState(() {
        _listening = false;
        _error = 'Microphone permission was denied. Enable it in Settings → '
            'Nudge & permissions.';
      });
    }
  }

  void _save() {
    final chosen = <Map<String, String>>[
      for (final s in _songs)
        if (_selected.contains(s.key)) {'title': s.title, 'artist': s.artist},
    ];
    if (chosen.isEmpty) return;
    Navigator.pushNamed(context, '/playlist', arguments: chosen);
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  String get _status {
    if (_listening) {
      return 'Listening… ${_elapsed}s / ${LiveListener.maxSeconds}s\n'
          'Tap again when the reel moves on.';
    }
    if (_finishing) return 'Finishing the last bit…';
    if (_heardSomething || _songs.isNotEmpty) {
      return 'Done. Pick the songs you want to save.';
    }
    if (_elapsed > 0) {
      return 'No song recognised. Move the speaker closer and try again.';
    }
    return 'Tap the mic, then play the reel out loud on another device. '
        'Songs show up here as they are found.';
  }

  @override
  Widget build(BuildContext context) {
    final busy = _listening || _finishing;
    final canSave = !busy && _selected.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listen to reel'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: busy ? null : () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(child: _micButton()),
              const SizedBox(height: 18),
              if (_listening)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: (_elapsed / LiveListener.maxSeconds).clamp(0.0, 1.0),
                      minHeight: 5,
                      color: AppColors.primary,
                      backgroundColor: AppColors.surfaceHigh,
                    ),
                  ),
                ),
              Text(
                _status,
                style: AppText.bodyMedium(AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              if (_notice != null && _listening) ...[
                const SizedBox(height: 8),
                Text(_notice!,
                    style: AppText.bodySmall(AppColors.onSurfaceVariant),
                    textAlign: TextAlign.center),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.secondaryContainer.withValues(alpha: 0.4)),
                  ),
                  child: Text(_error!,
                      style: AppText.bodySmall(AppColors.onSurface),
                      textAlign: TextAlign.center),
                ),
              ],
              const SizedBox(height: 16),
              if (_songs.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${_songs.length} song${_songs.length == 1 ? '' : 's'} found',
                    style: AppText.labelLarge(AppColors.primary),
                  ),
                ),
              Expanded(child: _songList()),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: canSave ? _save : null,
                  icon: const Icon(Icons.playlist_add),
                  label: Text(_selected.isEmpty
                      ? 'Save to playlist'
                      : 'Save ${_selected.length} to playlist'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _micButton() {
    final size = 112.0 + (_listening ? _level * 36 : 0);
    return GestureDetector(
      onTap: _finishing ? null : _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: _listening ? 0.22 : 0.12),
          boxShadow: _listening
              ? const [BoxShadow(color: Color(0x6633E076), blurRadius: 44)]
              : const [BoxShadow(color: Color(0x3333E076), blurRadius: 24)],
        ),
        child: _finishing
            ? const Padding(
                padding: EdgeInsets.all(38),
                child: CircularProgressIndicator(
                    strokeWidth: 3, color: AppColors.primary),
              )
            : Icon(_listening ? Icons.stop_rounded : Icons.mic,
                size: 52, color: AppColors.primary),
      ),
    );
  }

  Widget _songList() {
    if (_songs.isEmpty) {
      return Center(
        child: Text(
          _listening ? 'Nothing yet. Keep the reel playing…' : '',
          style: AppText.bodySmall(AppColors.onSurfaceVariant),
        ),
      );
    }
    return ListView.builder(
      itemCount: _songs.length,
      itemBuilder: (context, i) {
        final s = _songs[i];
        final checked = _selected.contains(s.key);
        return Card(
          color: checked
              ? AppColors.primaryContainer.withValues(alpha: 0.15)
              : AppColors.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: checked
                ? const BorderSide(color: AppColors.primary)
                : BorderSide.none,
          ),
          child: CheckboxListTile(
            value: checked,
            activeColor: AppColors.primary,
            controlAffinity: ListTileControlAffinity.trailing,
            onChanged: _listening || _finishing
                ? null
                : (v) => setState(() {
                      if (v == true) {
                        _selected.add(s.key);
                      } else {
                        _selected.remove(s.key);
                      }
                    }),
            title: Text(s.title, style: AppText.titleMedium(AppColors.onSurface)),
            subtitle: Row(
              children: [
                Flexible(
                  child: Text(s.artist,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodySmall(AppColors.onSurfaceVariant)),
                ),
                if (s.bothAgree) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.verified, size: 14, color: AppColors.primary),
                  const SizedBox(width: 3),
                  Text('both models agree',
                      style: AppText.bodySmall(AppColors.primary)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
