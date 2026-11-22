import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';

class SavedSongsScreen extends StatefulWidget {
  const SavedSongsScreen({super.key});
  @override
  State<SavedSongsScreen> createState() => _SavedSongsScreenState();
}

class _SavedSongsScreenState extends State<SavedSongsScreen> {
  int _tab = 0;
  bool _overlayOn = true;
  int _filter = 0;
  bool _showToast = false;

  static const tracks = [
    _Track('Resonance', 'HOME', '3:32', '@synth.drifter', 'Late Night Vibes',
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDBtyWOGBPHYxsXXJy_RRr6IFwAq_5ur_zU430LubuxtWTe1HIKZCRkNrv4O1c5nV9ypgZyufN_Zz1lEcycmuBjRIVYNdTxPy_m3eYxaPXDeTKEsRW51DR7pLFbg5evg1_N7Xy_FWH7jTSEIEJMGpmUJVop3r3lS19pUsby8euNcAnGXpO-zJmjc_v5_SeQ9HDrjZ-JN3cKoeIo1DVc2sGr7C9py4WYIyUD9gJXQ1E',
        [Color(0xFF7B2CBF), Color(0xFF1A0B2E)]),
    _Track('Midnight City', 'M83', '4:03', '@lofi_producer', 'Deep Focus & Flow',
        'https://lh3.googleusercontent.com/aida-public/AB6AXuBPOMKJYGvdAuMfzk-0w9pm_8vd7ViPvvwkBY5gUhayc3dY9O-j0BXIfcY8-7pFAubFmWmLXyPdy-pHTGTz7gDCEk6etJ6oJwJH6RxROvgYzeJ1j1vVtT00Z2CypUa8HtaBtYVpaYMlO5pUp_-_9EhioM3ueomY5YdCOf-v1AW_sODFbGXW1n_IYgVHgHH7ZnbtcQmbmCOuMdZLEmiQaKBvNJzFUHp3Yx6ITqtVMwM',
        [Color(0xFF00B4D8), Color(0xFF03071E)]),
    _Track('A Walk', 'Tycho', '5:16', '@midnight.crates', 'Late Night Vibes',
        'https://lh3.googleusercontent.com/aida-public/AB6AXuCqJuhDrRumC-7KmaclOlCJkJewQWT-v0D5WLXHlSsnTMXDBcapG5nIogdK6L0xvbu0HxS1_In_lblySYdSfsoFjytypLhNoMAc4Ml91x6Mi61RPJ8nFQY94RK2e6EtiUuyP12_Zw0K4Hjk-FIaqgFnApMKwocNVe26F_09Y3y5obRxDnQicqc3hqnYT4nLb5dsRyxOJuH4KwzekVzV8wSr0ZCYV2QrWJvTWrN84i8',
        [Color(0xFFE07A5F), Color(0xFF1A1A1A)]),
    _Track('Cirrus', 'Bonobo', '5:52', '@tokyo_beats', 'Morning Coffee',
        'https://lh3.googleusercontent.com/aida-public/AB6AXuCAKPVJpAGGJ-_sV17DyImk98cL0OO0FIQCxkuT_ddgCtM3hUcdrMZBSfGnS7iBJCUnVnQIQodBbdfKlg0sxp_mXpcM-MoBY70-m2F7T7EgVSflTkUneJpDwBMouBkAGhXym1Vx6I6D7wcGEelcZ9ofpJjCBmzXpjvRt9sgqset-bcBUcFDYFldh_dDnmtcFDXkCVrxK119LoO6JYK8pORoBpS4sdYadkFm-u2WzLM',
        [Color(0xFF4361EE), Color(0xFF0B0B0B)]),
    _Track('Days to Come', 'Seven Lions', '3:58', '@soundwave_diaries', 'Dubstep Gold',
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDxf6Rb2ILqVfMlCtKODT642k5ojRsS6dzn57Uwcz8kr8qJxhRv2QYs2Np66a2Uf4y55-gx2YBBSRSFe7KLMve9z8iGiialI48BM-8AUjtXnUioZi5Q6sQ9Jwv5WwdV13Ormi-d50AH-4OThfK8nXQtl131tS4yMZq1fEg18XS5yJF_RvHhM78B-a0ntkT_PRMYhwO_RDlA897AWuFT1UKtmy6msj1XWr0xgpqHRVk',
        [Color(0xFF9D4EDD), Color(0xFF10002B)]),
  ];

  void _triggerToast() {
    setState(() => _showToast = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showToast = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              children: [
                _statsCard(),
                _overlayCard(),
                _filterPills(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent Captures',
                              style: AppText.headlineSmall(AppColors.onSurface)),
                          TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.sync, size: 16),
                            label: const Text('Batch Sync'),
                            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (final t in tracks) _trackCard(t),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Floating "Capture Reel" FAB
          Positioned(
            right: 16,
            bottom: 100,
            child: SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/nudge'),
                icon: const Icon(Icons.photo_camera, size: 24),
                label: Text('Capture Reel', style: AppText.headlineSmall(AppColors.onPrimary)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shadowColor: const Color(0x661DB954),
                  elevation: 12,
                ),
              ),
            ),
          ),

          // Simulated nudge toast
          if (_showToast)
            Positioned(
              top: 60,
              left: 16,
              right: 16,
              child: _toast(),
            ),

          // Bottom navigation
          Positioned(left: 0, right: 0, bottom: 0, child: _bottomNav()),
        ],
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
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('INSTAGRAM CAPTURES',
                    style: AppText.labelSmall(AppColors.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text('34 Reel Tracks', style: AppText.headlineSmall(AppColors.onSurface)),
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
                  child: Row(children: [
                    const _PulseDot(),
                    const SizedBox(width: 6),
                    Text('Spotify', style: AppText.labelSmall(AppColors.onSurface)),
                  ]),
                ),
                const SizedBox(height: 6),
                Text('Synced 2m ago',
                    style: AppText.bodySmall(AppColors.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _overlayCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.all(Radius.circular(8))),
                  child: const Icon(Icons.layers, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text('Instagram Overlay',
                            style: AppText.titleMedium(AppColors.onSurface)),
                        const SizedBox(width: 8),
                        const _PulseDot(),
                      ]),
                      const SizedBox(height: 4),
                      Text(
                        'Active overlay monitoring background audio across Instagram '
                        'Reels & Stories in real time.',
                        style: AppText.bodySmall(AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _overlayOn,
                  onChanged: (v) => setState(() => _overlayOn = v),
                  activeColor: AppColors.primaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: _triggerToast,
                  icon: const Icon(Icons.bolt, size: 16, color: AppColors.tertiary),
                  label: const Text('Test Nudge Pop-up'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onSurface,
                    side: const BorderSide(color: AppColors.surfaceBright),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                ),
                Text('Tap to simulate capture',
                    style: AppText.labelSmall(AppColors.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterPills() {
    const labels = ['All Reels', 'By Creator', 'Latest First', 'Saved Playlists'];
    const icons = [null, Icons.person, Icons.schedule, Icons.playlist_add_check];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final active = _filter == i;
          final icon = icons[i];
          return GestureDetector(
            onTap: () => setState(() => _filter = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: active ? AppColors.onSurface : AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16,
                        color: active ? AppColors.surfaceLowest : AppColors.onSurfaceVariant),
                    const SizedBox(width: 6),
                  ],
                  Text(labels[i],
                      style: AppText.labelMedium(active
                          ? AppColors.surfaceLowest
                          : AppColors.onSurfaceVariant)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _trackCard(_Track t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x0FFFFFFF)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: SmartImage(url: t.url, fallback: t.fallback),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.title, style: AppText.titleMedium(AppColors.onSurface)),
                    const SizedBox(height: 3),
                    Text('${t.artist} • ${t.duration}',
                        style: AppText.bodySmall(AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              _TinyIcon(Icons.photo_camera, AppColors.secondary),
              const SizedBox(width: 4),
              _TinyIcon(Icons.play_circle, AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              _TinyIcon(Icons.more_vert, AppColors.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(children: [
                  const Icon(Icons.movie, size: 14, color: AppColors.secondary),
                  const SizedBox(width: 4),
                  Text('Reel ${t.reel}', style: AppText.labelSmall(AppColors.onSurfaceVariant)),
                ]),
              ),
              Row(children: [
                const Icon(Icons.check_circle, size: 15, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(t.playlist, style: AppText.labelSmall(AppColors.onSurface)),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toast() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 30)],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
            child: const Icon(Icons.hearing, color: AppColors.onPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Listening to Instagram...',
                    style: AppText.titleMedium(AppColors.onSurface)),
                const SizedBox(height: 2),
                Text('Match found: "Resonance - HOME"',
                    style: AppText.bodySmall(AppColors.primary)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.onSurfaceVariant),
            onPressed: () => setState(() => _showToast = false),
          ),
        ],
      ),
    );
  }

  Widget _bottomNav() {
    final items = [
      (Icons.library_music, 'Saved Songs'),
      (Icons.auto_awesome, 'Discover'),
      (Icons.layers, 'Overlay'),
      (Icons.tune, 'Profile'),
    ];
    return Container(
      height: 82,
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest.withValues(alpha: 0.94),
        border: const Border(top: BorderSide(color: Color(0x14FFFFFF))),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final active = _tab == i;
            return GestureDetector(
              onTap: () {
                setState(() => _tab = i);
                if (i == 1) Navigator.pushNamed(context, '/nudge');
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(items[i].$1,
                      size: 24,
                      color: active ? AppColors.primary : AppColors.onSurfaceVariant),
                  const SizedBox(height: 4),
                  Text(items[i].$2,
                      style: AppText.labelMedium(
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

class _PulseDot extends StatelessWidget {
  const _PulseDot();
  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
          boxShadow: [BoxShadow(color: AppColors.primary, blurRadius: 6)],
        ),
      );
}

class _TinyIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _TinyIcon(this.icon, this.color);
  @override
  Widget build(BuildContext context) => Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceContainer),
        child: Icon(icon, size: 18, color: color),
      );
}

class _Track {
  final String title;
  final String artist;
  final String duration;
  final String reel;
  final String playlist;
  final String url;
  final List<Color> fallback;
  const _Track(this.title, this.artist, this.duration, this.reel, this.playlist,
      this.url, this.fallback);
}
