import 'package:flutter/material.dart';

import '../local_store.dart';
import '../theme.dart';

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
  int _count = 0;
  String _playlist = '';
  List<String> _missing = const [];
  bool _applied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_applied) return;
    _applied = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    _count = (args is Map ? args['count'] : null) ?? widget.addedCount;
    _playlist =
        (args is Map ? args['playlist'] : null)?.toString() ?? widget.playlistName;
    if (args is Map && args['missing'] is List) {
      _missing = (args['missing'] as List).map((e) => e.toString()).toList();
    }
    if (args is Map && args['songs'] is List) {
      final songs = (args['songs'] as List)
          .where((e) => e is Map)
          .map((e) => <String, String>{
                'title': (e['title'] ?? '').toString(),
                'artist': (e['artist'] ?? '').toString(),
              })
          .where((s) => (s['title'] ?? '').isNotEmpty)
          .toList();
      _store.addSongs(songs);
    }
    if (_playlist.isNotEmpty) _store.setLastPlaylist(_playlist);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
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
                    boxShadow: const [
                      BoxShadow(color: Color(0x5533E076), blurRadius: 40)
                    ],
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
                if (_missing.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Not found on this service',
                            style: AppText.labelMedium(AppColors.onSurface)),
                        const SizedBox(height: 4),
                        Text(_missing.join(', '),
                            style: AppText.bodySmall(AppColors.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text('Try saving those to the other service from Saved Songs.',
                            style: AppText.bodySmall(AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 34),
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
      ),
    );
  }
}
