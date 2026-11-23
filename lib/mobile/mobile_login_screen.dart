import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import 'mobile_auth_launcher.dart';

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({super.key});
  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen> {
  String? _error;

  Future<void> _signIn() async {
    final err = await startMobileOAuth('google');
    if (err != null && mounted) {
      setState(() => _error = err);
    }
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
                  const StatusPill(text: 'BETA • GEMINI FLASH'),
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
                    'Catch every track. Instantly. Identify the song playing in a '
                    'reel and drop it straight into your playlist.',
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
                      onPressed: _signIn,
                      icon: const Icon(Icons.g_mobiledata, size: 24),
                      label: const Text('Continue with Google'),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.secondaryContainer.withValues(alpha: 0.4)),
                      ),
                      child: Text(_error!,
                          style: AppText.bodySmall(AppColors.onSurface),
                          textAlign: TextAlign.center),
                    ),
                  ],
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/connect'),
                    child: const Text('Skip — connect Spotify instead'),
                  ),
                  const SizedBox(height: 4),
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
                  const _Feature(Icons.mic, AppColors.primary,
                      'One-tap reel capture', 'Listen for a few seconds to identify the song'),
                  const SizedBox(height: 10),
                  const _Feature(Icons.sync, AppColors.primaryContainer,
                      'Sync to Spotify & YT Music', 'Adds the track straight to your playlist'),
                  const SizedBox(height: 10),
                  const _Feature(Icons.shield, AppColors.tertiary,
                      'Audio never stored', 'Analysed for the capture, then discarded'),
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
