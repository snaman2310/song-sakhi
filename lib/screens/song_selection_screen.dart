import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';

class SongSelectionScreen extends StatelessWidget {
  final List<Map<String, String>>? suggestions;
  const SongSelectionScreen({this.suggestions, super.key});

  static const defaults = [
    {'title': 'Resonance', 'artist': 'HOME', 'duration': '3:32'},
    {'title': 'Midnight City', 'artist': 'M83', 'duration': '4:03'},
    {'title': 'A Walk', 'artist': 'Tycho', 'duration': '5:16'},
  ];

  static const covers = [
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDqOlNkcF-6zt3hb04niwwn2qHEebocIaeIUawEEWt4pvYW5p1RVZOwtk0jSWl-pZR9nVWka2QwkzMeHfiuwhT593hOgG9AdisfThykpf8oG56MYDrbhE3irBeSeqoAjrAcnMsM_ewE1n-bcQaYUkAwmxSIjVmDk_6jmEdK8ntNuWQtx-09vBai-Pbms2IBliSaepbB6qx-n1_3-XBqRTH7kCJ39C2FE97LSDT5-XQ',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuD7ZoKMExe7f4YUX_sYaFlgCNJrSrUqtu2CNCFROCqaPb1PjD8Y9DLWYgipy17y2dyjP0lulfwtopUL_MyqStAhooZxf3ulazyVj9d5XGkxltfEQWuByAdmnDz7t1_cEmuOLJp67r1lq39n3xoPV1PXCXRUJGrrUQixi4PLSMqEgEzkGHBgoC8ToBETHjNDprEqrp3BTxc2KYRr8YIHEDg_6Nu1az-77P3OyNl1nWs',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuCnzJm-xCX5Q8veb-m-071CyH7J-uXBuG-M6-bDtMR3aDg8ZH_LnGT6CMc_fF5zogpJXCgrjD-OoEc2VpPRLiccRcIzL39DP6yJl8VpudXcXpRpy1lWODwFOc7vsopxPTur4sY_0XWUM0tUkIY55NwBPUIPr1OTsSbdVIoVz39NIy8x5hX1Z107InArZfkSPy0GaSoqI9WIoLWB3gVnA40evGlAUdew1SBDefTSQfw',
  ];

  @override
  Widget build(BuildContext context) {
    final songs = suggestions ?? defaults;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: SmartImage(
              url: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDPropZxCw6Yscim6w_-HnD97_6EEcwRg-sHshstrqwHnp06PgQSXbpdPRQPS0eXI_Nj3-nKowIaK0--cG8xmbCisTajvuUl_VPmWlWCChq0oTiEdUH6JuyptofYSIpHZbKJgY5Qx_oIV5toH_S9Uw2SImtf_ERHIgJxILlEq4_7uuFm4bSkWxr_fzI7v1KOufh_YoQk0x9ETz0KiF-lk0MnIgQttQz6dzHdHSEGCw',
              fallback: [AppColors.primaryContainer, AppColors.surfaceLowest],
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xB3131313), Color(0x55000000), Color(0xE6131313)],
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
                              fontSize: 18,
                              fontWeight: FontWeight.w600)),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.5),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Icon(Icons.photo_camera, size: 20, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: GlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back, size: 17),
                              label: const Text('Back to Reel'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.onSurfaceVariant,
                                backgroundColor: Colors.white10,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                            ),
                            Column(children: [
                              Row(children: [
                                const Icon(Icons.graphic_eq,
                                    size: 18, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text('Detected Songs',
                                    style: AppText.titleMedium(AppColors.onSurface)),
                              ]),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                ),
                                child: Text('GEMINI FLASH • ${songs.length} FOUND',
                                    style: AppText.labelSmall(AppColors.primary)),
                              ),
                            ]),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle, color: Colors.white10),
                              child: const Icon(Icons.close,
                                  size: 16, color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: Colors.white12, height: 1),
                        const SizedBox(height: 12),

                        for (int i = 0; i < songs.length; i++)
                          _songRow(songs[i], i),

                        const SizedBox(height: 14),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/playlist'),
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Next: Select Playlist'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              foregroundColor: AppColors.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),

          // Right rail
          Positioned(
            right: 12,
            bottom: 100,
            child: Column(children: [
              _rail(Icons.favorite, AppColors.secondaryContainer, '24.8K', filled: true),
              const SizedBox(height: 16),
              _rail(Icons.chat_bubble, Colors.white, '412'),
              const SizedBox(height: 16),
              _rail(Icons.send, Colors.white, '3.1K'),
            ]),
          ),

          // Bottom metadata
          Positioned(
            left: 16,
            right: 70,
            bottom: 22,
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
                  Text('synth.drifter',
                      style: AppText.labelLarge(Colors.white)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(999)),
                    child: Text('Follow', style: AppText.labelSmall(Colors.white)),
                  ),
                ]),
                const SizedBox(height: 8),
                const Text(
                  'Late night drive through Shibuya with the windows down 🌃✨ '
                  '#synthwave #nightdrive',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                const Row(children: [
                  Icon(Icons.music_note, size: 15, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text('Resonance • HOME',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _songRow(Map<String, String> song, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 40,
              height: 40,
              child: SmartImage(
                url: index < covers.length ? covers[index] : '',
                fallback: [AppColors.primaryContainer, AppColors.surfaceLowest],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(song['title'] ?? '',
                    style: AppText.titleMedium(AppColors.onSurface),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(children: [
                  Text(song['artist'] ?? '',
                      style: AppText.bodySmall(AppColors.onSurfaceVariant)),
                  const SizedBox(width: 6),
                  const Text('•', style: TextStyle(color: Colors.white38)),
                  const SizedBox(width: 6),
                  Text(song['duration'] ?? '3:00',
                      style: AppText.bodySmall(AppColors.onSurfaceVariant)),
                ]),
              ],
            ),
          ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(Icons.check, size: 14, color: AppColors.onPrimaryFixed),
          ),
        ],
      ),
    );
  }

  Widget _rail(IconData icon, Color color, String label, {bool filled = false}) {
    return Column(children: [
      Icon(icon, size: 28, color: color),
      const SizedBox(height: 4),
      Text(label, style: AppText.labelSmall(Colors.white)),
    ]);
  }
}
