import 'package:flutter/material.dart';
import '../theme.dart';
import '../local_store.dart';
import '../mobile/nudge_controller.dart';

class SavedSongsScreen extends StatefulWidget {
  const SavedSongsScreen({super.key});
  @override
  State<SavedSongsScreen> createState() => _SavedSongsScreenState();
}

class _SavedSongsScreenState extends State<SavedSongsScreen> {
  final _store = LocalStore();
  int _tab = 0;
  bool _loading = true;
  List<Map<String, String>> _songs = [];
  String _playlist = 'My Playlist';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final songs = await _store.getSavedSongs();
    final playlist = await _store.getLastPlaylist();
    if (!mounted) return;
    setState(() {
      _songs = songs;
      _playlist = playlist;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Songs')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              children: [
                _statsCard(),
                _overlayCard(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent Captures',
                              style: AppText.headlineSmall(AppColors.onSurface)),
                          Text('${_songs.length} tracks',
                              style: AppText.labelMedium(AppColors.onSurfaceVariant)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        )
                      else if (_songs.isEmpty)
                        _emptyState()
                      else
                        for (final song in _songs) _songCard(song),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 100,
            child: SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/nudge'),
                icon: const Icon(Icons.photo_camera, size: 24),
                label: Text('Capture Reel',
                    style: AppText.headlineSmall(AppColors.onPrimary)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  elevation: 12,
                  shadowColor: const Color(0x661DB954),
                ),
              ),
            ),
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: _bottomNav()),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          const Icon(Icons.graphic_eq, size: 56, color: AppColors.primary),
          const SizedBox(height: 16),
          Text('No songs captured yet',
              style: AppText.titleLarge(AppColors.onSurface)),
          const SizedBox(height: 8),
          Text(
            'Tap "Capture Reel", hold your phone near the speaker while a '
            'reel plays, and we\'ll find the songs for you.',
            style: AppText.bodyMedium(AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/nudge'),
            icon: const Icon(Icons.mic),
            label: const Text('Capture first reel'),
          ),
        ],
      ),
    );
  }

  Widget _songCard(Map<String, String> song) {
    return Card(
      color: AppColors.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.music_note, color: AppColors.primary),
        ),
        title: Text(song['title'] ?? 'Unknown',
            style: AppText.titleMedium(AppColors.onSurface)),
        subtitle: Text(song['artist'] ?? 'Unknown artist',
            style: AppText.bodySmall(AppColors.onSurfaceVariant)),
        trailing: const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
      ),
    );
  }

  Widget _statsCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CAPTURED TRACKS',
                    style: AppText.labelSmall(AppColors.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text('${_songs.length} Reel Tracks',
                    style: AppText.headlineSmall(AppColors.onSurface)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('Saved locally',
                      style: AppText.labelSmall(AppColors.primary)),
                ),
                const SizedBox(height: 6),
                Text(_playlist,
                    style: AppText.bodySmall(AppColors.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleNudge(bool on) async {
    final ctrl = NudgeController.instance;
    if (!on) {
      await ctrl.disable();
      return;
    }
    final err = await ctrl.enable();
    if (err != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Widget _overlayCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ValueListenableBuilder<bool>(
          valueListenable: NudgeController.instance.enabled,
          builder: (context, on, _) => Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.all(Radius.circular(8))),
                child: const Icon(Icons.layers, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, '/permissions'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Floating nudge',
                          style: AppText.titleMedium(AppColors.onSurface)),
                      Text(
                          on
                              ? 'On · open Instagram and tap the circle'
                              : 'Off · turn on to float over Instagram',
                          style: AppText.bodySmall(AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
              Switch(value: on, onChanged: _toggleNudge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomNav() {
    final items = [
      (Icons.library_music, 'Saved'),
      (Icons.auto_awesome, 'Discover'),
      (Icons.settings, 'Settings'),
    ];
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        border: const Border(top: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final active = _tab == i;
            return GestureDetector(
              onTap: () {
                if (i == 1) {
                  Navigator.pushNamed(context, '/nudge');
                  return;
                }
                if (i == 2) {
                  Navigator.pushNamed(context, '/settings');
                  return;
                }
                setState(() => _tab = i);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(items[i].$1,
                      color: active ? AppColors.primary : AppColors.onSurfaceVariant),
                  const SizedBox(height: 4),
                  Text(items[i].$2,
                      style: AppText.labelSmall(
                          active ? AppColors.primary : AppColors.onSurfaceVariant)),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
