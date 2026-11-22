import 'package:flutter/material.dart';
import '../theme.dart';
import '../local_store.dart';

class ConfirmationScreen extends StatefulWidget {
  final int addedCount;
  final String playlistName;
  const ConfirmationScreen({
    this.addedCount = 0,
    this.playlistName = '',
    super.key,
  });

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  final _store = LocalStore();
  late int _count;
  late String _playlist;

  @override
  void initState() {
    super.initState();
    final args = ModalRoute.of(context)?.settings.arguments;
    _count = (args is Map ? args['count'] : null) ?? widget.addedCount;
    _playlist =
        (args is Map ? args['playlist'] : null)?.toString() ?? widget.playlistName;
    if (args is Map && args['songs'] is List) {
      final raw = args['songs'] as List;
      final songs = raw
          .where((e) => e is Map)
          .map((e) => <String, String>{
                'title': (e['title'] ?? '').toString(),
                'artist': (e['artist'] ?? '').toString(),
              })
          .toList();
      _store.addSongs(songs);
    }
    if (_playlist.isNotEmpty) _store.setLastPlaylist(_playlist);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                  boxShadow: const [BoxShadow(color: Color(0x5533E076), blurRadius: 40)],
                ),
                child: const Icon(Icons.check_circle,
                    color: AppColors.primary, size: 64),
              ),
              const SizedBox(height: 28),
              Text('Saved!', style: AppText.headlineLarge(AppColors.onSurface)),
              const SizedBox(height: 12),
              Text(
                '$_count song${_count == 1 ? '' : 's'} added to "$_playlist"',
                style: AppText.bodyMedium(AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, '/home', (r) => false),
                  icon: const Icon(Icons.home),
                  label: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
