import 'package:flutter/material.dart';
import '../theme.dart';

class SongSelectionScreen extends StatefulWidget {
  final List<Map<String, String>>? suggestions;
  const SongSelectionScreen({this.suggestions, super.key});

  @override
  State<SongSelectionScreen> createState() => _SongSelectionScreenState();
}

class _SongSelectionScreenState extends State<SongSelectionScreen> {
  late final List<Map<String, String>> _songs;
  late final Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _songs = widget.suggestions ?? const [];
    _selected = {for (int i = 0; i < _songs.length; i++) i};
  }

  void _next() {
    final chosen = _selected.toList()
      ..sort();
    final songs = chosen.map((i) => _songs[i]).toList();
    Navigator.pushNamed(context, '/playlist', arguments: songs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Detected Songs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _songs.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.music_off, size: 64, color: AppColors.outline),
                    const SizedBox(height: 16),
                    Text('No songs detected', style: AppText.headlineSmall(AppColors.onSurface)),
                    const SizedBox(height: 8),
                    Text('Try capturing again, closer to the speaker.',
                        style: AppText.bodyMedium(AppColors.onSurfaceVariant),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.mic),
                      label: const Text('Capture again'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.graphic_eq, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('${_songs.length} songs found',
                          style: AppText.labelLarge(AppColors.onSurface)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() {
                          if (_selected.length == _songs.length) {
                            _selected.clear();
                          } else {
                            _selected = {for (int i = 0; i < _songs.length; i++) i};
                          }
                        }),
                        child: Text(_selected.length == _songs.length
                            ? 'Clear all'
                            : 'Select all'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _songs.length,
                    itemBuilder: (context, i) {
                      final s = _songs[i];
                      final checked = _selected.contains(i);
                      return Card(
                        color: AppColors.surfaceContainer,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceHigh,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.music_note, color: AppColors.primary),
                          ),
                          title: Text(s['title'] ?? 'Unknown',
                              style: AppText.titleMedium(AppColors.onSurface)),
                          subtitle: Text(s['artist'] ?? 'Unknown artist',
                              style: AppText.bodySmall(AppColors.onSurfaceVariant)),
                          trailing: Checkbox(
                            value: checked,
                            activeColor: AppColors.primaryContainer,
                            onChanged: (v) => setState(() {
                              if (v == true) {
                                _selected.add(i);
                              } else {
                                _selected.remove(i);
                              }
                            }),
                          ),
                          onTap: () => setState(() {
                            if (checked) {
                              _selected.remove(i);
                            } else {
                              _selected.add(i);
                            }
                          }),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _songs.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _selected.isEmpty ? null : _next,
                    icon: const Icon(Icons.playlist_add),
                    label: Text('Next: Select Playlist (${_selected.length})'),
                  ),
                ),
              ),
            ),
    );
  }
}
