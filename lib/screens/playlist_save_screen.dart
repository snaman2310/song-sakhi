import 'package:flutter/material.dart';
import '../auth_service.dart';
import '../playlist_service.dart';
import '../theme.dart';

class PlaylistSaveScreen extends StatefulWidget {
  final List<Map<String, String>> songs;
  const PlaylistSaveScreen({required this.songs, super.key});

  @override
  State<PlaylistSaveScreen> createState() => _PlaylistSaveScreenState();
}

class _PlaylistSaveScreenState extends State<PlaylistSaveScreen> {
  final _service = PlaylistService();
  String _provider = 'spotify';
  List<Playlist> _playlists = [];
  String? _selectedId;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final spotify = await AuthService().tokenFor('spotify');
    final youtube = await AuthService().tokenFor('google');
    if (spotify == null || spotify.isEmpty) {
      if (youtube != null && youtube.isNotEmpty) _provider = 'youtube';
    }
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _selectedId = null;
      _playlists = [];
    });
    try {
      final token = await AuthService().tokenFor(
          _provider == 'spotify' ? 'spotify' : 'google');
      if (token == null || token.isEmpty) {
        throw Exception('Not connected to $_provider. Go back and connect it.');
      }
      final list = _provider == 'spotify'
          ? await _service.spotifyPlaylists(token)
          : await _service.youtubePlaylists(token);
      if (!mounted) return;
      setState(() {
        _playlists = list;
        if (list.isNotEmpty) _selectedId = list.first.id;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_selectedId == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final token = await AuthService().tokenFor(
          _provider == 'spotify' ? 'spotify' : 'google');
      if (token == null || token.isEmpty) throw Exception('Missing access token.');

      final ids = <String>[];
      for (final song in widget.songs) {
        final title = song['title'] ?? '';
        final artist = song['artist'] ?? '';
        if (title.isEmpty) continue;
        final id = _provider == 'spotify'
            ? await _service.spotifyTrackUri(token, title, artist)
            : await _service.youtubeVideoId(token, title, artist);
        if (id != null && id.isNotEmpty) ids.add(id);
      }
      if (ids.isEmpty) {
        throw Exception('None of these songs were found on $_provider.');
      }
      if (_provider == 'spotify') {
        await _service.addToSpotify(token, _selectedId!, ids);
      } else {
        await _service.addToYouTube(token, _selectedId!, ids);
      }
      if (!mounted) return;
      final name = _playlists.firstWhere((p) => p.id == _selectedId).name;
      Navigator.pushReplacementNamed(
        context,
        '/confirmation',
        arguments: {
          'count': ids.length,
          'playlist': name,
          'songs': widget.songs,
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Save to Playlist')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${widget.songs.length} songs selected',
                  style: AppText.labelLarge(AppColors.primary)),
              const SizedBox(height: 16),
              Row(children: [
                _providerChip('Spotify', 'spotify'),
                const SizedBox(width: 10),
                _providerChip('YouTube Music', 'youtube'),
              ]),
              const SizedBox(height: 20),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.secondaryContainer.withValues(alpha: 0.4)),
                  ),
                  child: Text(_error!,
                      style: AppText.bodySmall(AppColors.onSurface)),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primary))
                    : _playlists.isEmpty
                        ? Center(
                            child: Text('No playlists found.',
                                style: AppText.bodyMedium(
                                    AppColors.onSurfaceVariant)))
                        : ListView.builder(
                            itemCount: _playlists.length,
                            itemBuilder: (context, i) {
                              final p = _playlists[i];
                              final selected = p.id == _selectedId;
                              return Card(
                                color: selected
                                    ? AppColors.primaryContainer.withValues(alpha: 0.15)
                                    : AppColors.surfaceContainer,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: selected
                                      ? const BorderSide(color: AppColors.primary)
                                      : BorderSide.none,
                                ),
                                child: ListTile(
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceHigh,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.library_music,
                                        color: AppColors.primary, size: 20),
                                  ),
                                  title: Text(p.name,
                                      style: AppText.titleMedium(AppColors.onSurface)),
                                  subtitle: p.count > 0
                                      ? Text('${p.count} songs',
                                          style: AppText.bodySmall(
                                              AppColors.onSurfaceVariant))
                                      : null,
                                  trailing: selected
                                      ? const Icon(Icons.check_circle,
                                          color: AppColors.primary)
                                      : null,
                                  onTap: () => setState(() => _selectedId = p.id),
                                ),
                              );
                            },
                          ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: (_saving || _selectedId == null) ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(_saving ? 'Saving…' : 'Save to Playlist'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _providerChip(String label, String value) {
    final active = _provider == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_provider != value) setState(() => _provider = value);
          _load();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primaryContainer
                : AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
            child: Text(
              label,
              style: AppText.labelMedium(active
                  ? AppColors.onPrimary
                  : AppColors.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}
