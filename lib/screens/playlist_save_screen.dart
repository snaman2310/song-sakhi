import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';

class PlaylistSaveScreen extends StatefulWidget {
  const PlaylistSaveScreen({super.key});
  @override
  State<PlaylistSaveScreen> createState() => _PlaylistSaveScreenState();
}

class _PlaylistSaveScreenState extends State<PlaylistSaveScreen> {
  int _selected = 0;

  static const playlists = [
    ('Late Night Vibes', '42 songs',
     'https://lh3.googleusercontent.com/aida-public/AB6AXuC2NKJWZFuwELCh8dQ0aTxIn5a2-NPPZ-GxuT2z9HqJeY_eBwUzxHkxYM6jNDZTmtH8dGL8XxyHizHbGpC7FJwwXOj86axEUFglqOD8842KiuOdTku4wAAW_zvVV-opdT5paGaHSrBg2PXx-GlX5POvxh6qpbAXXi09JEGR3BrhINlZh7PE2OCqYkZCbK5XYAAnhwpOHO4Id7Nckx3LV1y_tRwgboV8f-U1hPyDhCQ',
     [Color(0xFF0B6E4F), Color(0xFF0A0A0A)]),
    ('Deep Focus & Flow', '88 songs',
     'https://lh3.googleusercontent.com/aida-public/AB6AXuDzC6KdUKSOf2PMgtu9IudqkkpAt36zghLANQy_9j2-OxgnKZXml2Id6D-_xQ5d6VGEmN6RiLW1D6X9duY6vK-xie_GuIhYXCXsnacuJ4jV2lrTDbxtJGnDYefRnI2-wj_VtzC_TKsR-6XuRmUfpSF2M3bvqZi0KsyUgAPZao7_ua431VxbGG0t3zl6S_sVDEWh12IZfpbUfI78uKFHPa8h_YhqV2XI3Rc3FnGOc4Y',
     [Color(0xFF1A4E5A), Color(0xFF0A0A0A)]),
    ('Chill Lo-Fi', '120 songs',
     'https://lh3.googleusercontent.com/aida-public/AB6AXuAs3qEuIqumw693CCA4N1tTQ5K0rYzVHRGCAb2AuiuYds1cy9fwp31vkoSczlbuJTPfwsSaRDHZR9f4x_BdXUJocSFkJWG4Tw9W3WpJeHqC4EmFrsMV_8PHJoTBmb8A77OW7sVVVAmYpqaJwSo5h--m7uCU93ig6cSxAY_mN31SJYKFsLCg7ZzL65jAqTKaq25DdwsgibFk9d61Cn3-kL0HHxT5lgqq9rifljnSwUM',
     [Color(0xFF6B4A2F), Color(0xFF0A0A0A)]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: SmartImage(
              url: 'https://lh3.googleusercontent.com/aida-public/AB6AXuD3EkUCEZlqTAAiOvxNHWrRm6mrjhFvRgA_W0WckWEF9ovw6NS3RCHHXZj7a1vUPPoOhF_ljCO5DFHtwcy8zQSLPKu01xtimOKFn-cEB30JBu6mdTgfCEyYiG1rIgb16m1rqX1xQ2xBOwEbnuMkv62wBAc3QJfgWoeGURfvp1fNWR3Qc5OA8CeyS-64l5XVybdLmZ-GR-cWXD0WnFhJ43Igu6e8Do5TDX2nK0x_d9A',
              fallback: [AppColors.primaryContainer, AppColors.surfaceLowest],
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xCC131313), Color(0x66000000), Color(0xE6131313)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Reels',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600)),
                      const Icon(Icons.photo_camera, size: 24, color: Colors.white),
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: GlassCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                      shape: BoxShape.circle, color: Colors.white10),
                                  child: const Icon(Icons.arrow_back,
                                      size: 19, color: AppColors.onSurface),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Row(children: [
                                    Text('Save to Playlist',
                                        style: AppText.titleMedium(Colors.white)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryContainer.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(
                                            color: AppColors.primary.withValues(alpha: 0.4)),
                                      ),
                                      child: Text('3 songs selected',
                                          style: AppText.labelSmall(AppColors.primaryFixed)),
                                    ),
                                  ]),
                                ),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                      shape: BoxShape.circle, color: Colors.white10),
                                  child: const Icon(Icons.close,
                                      size: 18, color: Colors.white70),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Divider(color: Colors.white12, height: 1),

                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white38, style: BorderStyle.solid),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: const Icon(Icons.add,
                                      size: 16, color: AppColors.primary),
                                ),
                                const SizedBox(width: 10),
                                Text('Create new playlist',
                                    style: AppText.labelMedium(Colors.white)),
                              ]),
                            ),

                            const SizedBox(height: 8),
                            for (int i = 0; i < playlists.length; i++)
                              _playlistRow(playlists[i], i),
                            const SizedBox(height: 10),

                            SizedBox(
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pushNamed(context, '/confirmation'),
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Save to Playlist'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryContainer,
                                  foregroundColor: AppColors.onPrimary,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999)),
                                  shadowColor: const Color(0x661DB954),
                                  elevation: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom metadata
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.surfaceHigh,
                                child: Icon(Icons.person, size: 16, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              Text('midnight.crate',
                                  style: AppText.labelLarge(Colors.white)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(999)),
                                child: Text('Follow',
                                    style: AppText.labelSmall(Colors.white)),
                              ),
                            ]),
                            const SizedBox(height: 8),
                            const Text(
                              'Found this hidden gem on vinyl tonight... 🎧✨ #lofi #latenightvibes',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            const Row(children: [
                              Icon(Icons.music_note, size: 15, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text('Original Audio • Midnight Crate',
                                  style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(children: const [
                        Icon(Icons.favorite, size: 26, color: Colors.white),
                        Text('42.8K', style: TextStyle(color: Colors.white, fontSize: 11)),
                        SizedBox(height: 10),
                        Icon(Icons.chat_bubble, size: 26, color: Colors.white),
                        Text('1,204', style: TextStyle(color: Colors.white, fontSize: 11)),
                        SizedBox(height: 10),
                        Icon(Icons.send, size: 26, color: Colors.white),
                        Text('8.4K', style: TextStyle(color: Colors.white, fontSize: 11)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _playlistRow((String, String, String, List<Color>) p, int index) {
    final active = _selected == index;
    return GestureDetector(
      onTap: () => setState(() => _selected = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primaryContainer.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? AppColors.primary.withValues(alpha: 0.5)
                : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 40,
                height: 40,
                child: SmartImage(url: p.$3, fallback: p.$4),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.$1, style: AppText.titleMedium(Colors.white)),
                  const SizedBox(height: 2),
                  Text(p.$2, style: AppText.bodySmall(AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? AppColors.primaryContainer : Colors.white10,
                border: active ? null : Border.all(color: Colors.white24),
              ),
              child: Icon(Icons.check,
                  size: 16,
                  color: active ? AppColors.onPrimary : Colors.transparent),
            ),
          ],
        ),
      ),
    );
  }
}
