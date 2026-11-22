import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../auth_service.dart';

class ConnectHubsScreen extends StatefulWidget {
  const ConnectHubsScreen({super.key});
  @override
  State<ConnectHubsScreen> createState() => _ConnectHubsScreenState();
}

class _ConnectHubsScreenState extends State<ConnectHubsScreen> {
  bool _spotifyOn = true;
  bool _ytConnected = false;
  bool _autoAdd = true;

  Future<void> _startOAuth(String kind) async {
    final url = await AuthService().buildAuthUrl(kind);
    html.window.location.href = url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const GlowBackdrop(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const StepProgress(left: 'Step 1 of 2', right: 'Music Sync Engine', fraction: 0.5),
                  const SizedBox(height: 22),

                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryContainer,
                        ),
                        child: Center(
                          child: Text('A',
                              style: AppText.labelSmall(AppColors.onPrimaryContainer)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('alex.music@gmail.com',
                          style: AppText.labelMedium(AppColors.onSurface)),
                      const SizedBox(width: 6),
                      const _Dot(color: AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Welcome, Alex!\nChoose your sync hub.',
                      style: AppText.headlineLarge(AppColors.onSurface)),
                  const SizedBox(height: 10),
                  Text(
                    'Whenever you spot a gem on Instagram Reels, TikTok, or Shorts, '
                    'Nudge injects it right into your library with zero friction.',
                    style: AppText.bodyMedium(AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),

                  _spotifyCard(),
                  const SizedBox(height: 14),
                  _youtubeCard(),
                  const SizedBox(height: 14),
                  _appleCard(),
                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: Color(0x331DB954)),
                          child: const Icon(Icons.auto_awesome,
                              size: 20, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Auto-add to 'Nudge Discovery'",
                                  style: AppText.titleMedium(AppColors.onSurface)),
                              Text(
                                'Creates a clean sandbox playlist for fresh catches '
                                'before mixing them into main favorites.',
                                style: AppText.bodySmall(AppColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _autoAdd,
                          onChanged: (v) => setState(() => _autoAdd = v),
                          activeColor: AppColors.primaryContainer,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/permissions'),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Continue to App Permissions'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Read/Write playlist tokens only. We never access your '
                          'billing, personal tracks, or credentials.',
                          style: AppText.labelSmall(AppColors.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _spotifyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: _spotifyOn
            ? Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.4))
            : null,
        boxShadow: _spotifyOn
            ? const [BoxShadow(color: Color(0x221DB954), blurRadius: 24)]
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                    color: AppColors.surfaceLowest,
                    borderRadius: BorderRadius.all(Radius.circular(12))),
                child: const Icon(Icons.album, size: 28, color: AppColors.primaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('Spotify', style: AppText.titleLarge(AppColors.onSurface)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('PREMIUM', style: AppText.labelSmall(AppColors.primaryFixed)),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.check_circle, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('Connected as alex_beats',
                          style: AppText.bodySmall(AppColors.primary)),
                    ]),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _startOAuth('spotify'),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _spotifyOn ? AppColors.primaryContainer : AppColors.surfaceHigh,
                  ),
                  child: Icon(Icons.check,
                      size: 18,
                      color: _spotifyOn ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
          if (_spotifyOn) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: SmartImage(
                        url: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBvo5XA3ia0FW52DsKvVBS5r4jX28Nay3YRwmPsAmHrDP3R8XsEfmugYawWFmzizMcgJ8pqdgqBJ9ICoY-I-SxzEifZ-rbbzeaiwo19a5UEPOGpT5NnJ8yx5oTOWqJo27jUGWoH8TtDI4jQI8NDjcUub-VeZQQ0lXsBrD1wFv8QekZbeCcwji-VXa1wwMTCqIpKDvUcQN8eoM6NytEjjXHmV_NIqvLQHS1hfkLuM-w',
                        fallback: [AppColors.primaryContainer, AppColors.surfaceLowest],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TARGET DESTINATION',
                            style: AppText.labelSmall(AppColors.outline)),
                        Text('Late Night Vibes',
                            style: AppText.titleMedium(AppColors.onSurface)),
                      ],
                    ),
                  ),
                  Text('42 songs', style: AppText.labelSmall(AppColors.onSurfaceVariant)),
                  const Icon(Icons.expand_more, size: 18, color: AppColors.onSurfaceVariant),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _youtubeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                    color: AppColors.surfaceLowest,
                    borderRadius: BorderRadius.all(Radius.circular(12))),
                child: const Icon(Icons.play_circle, size: 28, color: AppColors.secondaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('YouTube Music',
                        style: AppText.titleLarge(AppColors.onSurface)),
                    Text('Syncs shorts, drops & clips',
                        style: AppText.bodySmall(AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _startOAuth('google'),
                icon: Icon(_ytConnected ? Icons.check : Icons.add_link, size: 16),
                label: Text(_ytConnected ? 'Connected' : 'Connect'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _ytConnected ? AppColors.primary : AppColors.secondary,
                  side: BorderSide(
                    color: _ytConnected ? AppColors.primary : AppColors.secondaryContainer,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.playlist_add, size: 18, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Auto-creates "Saved from Reels"',
                      style: AppText.bodySmall(AppColors.onSurfaceVariant)),
                ),
                Text(_ytConnected ? 'Linked' : 'Unlinked',
                    style: AppText.labelSmall(AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _appleCard() {
    return Opacity(
      opacity: 0.8,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLowest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.all(Radius.circular(12))),
              child: const Icon(Icons.music_note, size: 26, color: AppColors.tertiaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('Apple Music', style: AppText.titleLarge(AppColors.onSurface)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('BETA', style: AppText.labelSmall(AppColors.onSurfaceVariant)),
                    ),
                  ]),
                  Text('MusicKit API sync',
                      style: AppText.bodySmall(AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.onSurfaceVariant,
                side: const BorderSide(color: AppColors.surfaceHigh),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              child: const Text('Notify Me'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color,
            boxShadow: [BoxShadow(color: color, blurRadius: 6)]),
      );
}
