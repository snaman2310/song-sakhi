import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import '../auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _continue(BuildContext ctx) {
    // Auth keys are added later; for now move through the onboarding flow.
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: const Text('Google OAuth – connect your keys to enable sign-in'),
        backgroundColor: AppColors.surfaceHighest,
      ),
    );
    Navigator.pushNamed(ctx, '/connect');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const GlowBackdrop(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  const StatusPill(text: 'V2.4 PRO • REALTIME AI'),
                  const SizedBox(height: 28),
                  const SoundwaveLogo(),
                  const SizedBox(height: 24),
                  Text(
                    'Catch every track.\nInstantly.',
                    textAlign: TextAlign.center,
                    style: AppText.headlineLarge(AppColors.onSurface).copyWith(height: 1.2),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Intelligent background reel listening and instant playlist '
                    'curation powered by Gemini 1.5 Flash.',
                    textAlign: TextAlign.center,
                    style: AppText.bodyMedium(AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),

                  // Ambient Reel Radar card
                  _radarCard(),
                  const SizedBox(height: 20),

                  // Google sign-in
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _continue(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceHighest,
                        foregroundColor: AppColors.onSurface,
                        side: const BorderSide(color: Color(0x22FFFFFF)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _GoogleG(),
                          const SizedBox(width: 12),
                          Text('Continue with Google',
                              style: AppText.titleMedium(AppColors.onSurface)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user, size: 15, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text('One-tap authentication with verified Google OAuth 2.0',
                          style: AppText.bodySmall(AppColors.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Feature pillars
                  const _FeatureCard(
                    icon: Icons.layers,
                    color: AppColors.primary,
                    title: 'Seamless Instagram Overlay',
                    subtitle: 'Instant floating nudges while you scroll reels',
                    trailing: Icons.bolt,
                  ),
                  const SizedBox(height: 10),
                  const _FeatureCard(
                    icon: Icons.sync_saved_locally,
                    color: AppColors.primaryContainer,
                    title: 'Direct Sync to Spotify & YT Music',
                    subtitle: 'Auto-populates your selected playlist library',
                    trailing: Icons.library_music,
                  ),
                  const SizedBox(height: 10),
                  const _FeatureCard(
                    icon: Icons.lock_person,
                    color: AppColors.tertiary,
                    title: 'Zero Audio Storage • 100% Privacy',
                    subtitle: 'On-device acoustic fingerprint parsing only',
                    trailing: Icons.shield,
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.graphic_eq, size: 18, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text('SPOTIFY API', style: AppText.labelSmall(AppColors.onSurface)),
                      const SizedBox(width: 12),
                      Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.outline)),
                      const SizedBox(width: 12),
                      const Icon(Icons.play_circle, size: 18, color: AppColors.secondaryContainer),
                      const SizedBox(width: 6),
                      Text('YOUTUBE MUSIC', style: AppText.labelSmall(AppColors.onSurface)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Terms of Service   •   Privacy Shield',
                      style: AppText.bodySmall(AppColors.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Text('Version 2.4.2 (Build 88) • Powered by Gemini Neural Core',
                      style: AppText.labelSmall(AppColors.onSurfaceVariant)
                          .copyWith(color: AppColors.onSurfaceVariant.withValues(alpha: 0.5))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _radarCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x14FFFFFF)),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 18)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.radio, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ambient Reel Radar', style: AppText.titleMedium(AppColors.onSurface)),
                    Text('Instagram & TikTok In-feed Sync',
                        style: AppText.bodySmall(AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              const StatusPill(text: 'LIVE READY', filled: true),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: 0.8,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(colors: [
                            AppColors.primary,
                            AppColors.tertiary,
                            AppColors.primaryFixed,
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.graphic_eq, size: 16, color: AppColors.onSurfaceVariant),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final IconData trailing;
  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceHigh),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.titleMedium(AppColors.onSurface),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: AppText.bodySmall(AppColors.onSurfaceVariant),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Icon(trailing, size: 18, color: AppColors.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// Multi-colour Google "G" mark drawn with four arcs.
class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(22, 22), painter: _GPainter());
  }
}

class _GPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 1;
    final rect = Rect.fromCircle(center: c, radius: r);
    void arc(Color color, double start, double sweep) {
      canvas.drawArc(rect, start, sweep, true,
          Paint()..color = color..style = PaintingStyle.fill);
    }
    arc(const Color(0xFFEA4335), 3.5, 2.4);
    arc(const Color(0xFFFBBC05), 2.3, 1.3);
    arc(const Color(0xFF34A853), 1.0, 1.4);
    arc(const Color(0xFF4285F4), 5.2, 1.5);
    canvas.drawCircle(c + const Offset(r * 0.35, 0), r * 0.42,
        Paint()..color = AppColors.surfaceHighest);
    canvas.drawRect(
      Rect.fromLTWH(c.dx, c.dy - 2, r * 0.9, 4),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
