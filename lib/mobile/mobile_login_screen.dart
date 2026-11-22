import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import 'mobile_auth_launcher.dart';

class MobileLoginScreen extends StatelessWidget {
  const MobileLoginScreen({super.key});

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
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0x14FFFFFF)),
                    ),
                    child: Row(
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
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => startMobileOAuth('google'),
                      icon: const Icon(Icons.g_mobiledata, size: 24),
                      label: const Text('Continue with Google'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user, size: 15, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text('Verified Google OAuth 2.0',
                          style: AppText.bodySmall(AppColors.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const _Feature(Icons.layers, AppColors.primary,
                      'Seamless Instagram Overlay', 'Instant floating nudges while you scroll'),
                  const SizedBox(height: 10),
                  const _Feature(Icons.sync, AppColors.primaryContainer,
                      'Direct Sync to Spotify & YT Music', 'Auto-populates your playlist library'),
                  const SizedBox(height: 10),
                  const _Feature(Icons.shield, AppColors.tertiary,
                      'Zero Audio Storage', 'On-device parsing only'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _Feature(this.icon, this.color, this.title, this.subtitle);

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
                Text(title, style: AppText.titleMedium(AppColors.onSurface)),
                Text(subtitle, style: AppText.bodySmall(AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
