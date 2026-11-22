import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StepProgress(
                  left: 'System Setup', right: 'Step 2 of 2 (100%)', fraction: 1.0),
              const SizedBox(height: 22),
              Text('Enable Floating Nudge',
                  style: AppText.headlineLarge(AppColors.onSurface)),
              const SizedBox(height: 8),
              Text(
                'To listen and save songs while watching Instagram, Music Nudge '
                'requires 2 Android system permissions.',
                style: AppText.bodyMedium(AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 22),

              _reelPreview(),
              const SizedBox(height: 20),

              const _PermissionCard(
                icon: Icons.picture_in_picture_alt,
                iconColor: AppColors.primary,
                title: 'Display Over Other Apps',
                status: 'Active',
                statusColor: AppColors.primary,
                description:
                    'Allows the compact mirror-glass Nudge button to hover over '
                    'Instagram and TikTok without interrupting playback.',
                granted: true,
                action: 'Manage in Settings',
              ),
              const SizedBox(height: 12),
              const _PermissionCard(
                icon: Icons.mic,
                iconColor: AppColors.secondaryContainer,
                title: 'Media Listener Audio',
                status: 'Action Required',
                statusColor: AppColors.secondary,
                description:
                    "Permits Whisper AI to capture acoustic fingerprints from the "
                    "Reel's active audio track with zero latency.",
                granted: false,
                action: 'Grant Permission',
              ),
              const SizedBox(height: 12),
              const _PermissionCard(
                icon: Icons.battery_saver,
                iconColor: AppColors.tertiary,
                title: 'Battery Restrictions',
                status: 'Recommended',
                statusColor: AppColors.tertiary,
                description:
                    'Disable background battery kill switches to keep Nudge instant '
                    'and responsive when switching heavy apps.',
                granted: false,
                action: 'Exclude from Saver',
              ),
              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user, size: 22, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Audio is only analyzed in volatile memory for live tagging '
                        'and never written to disk or transmitted elsewhere.',
                        style: AppText.bodySmall(AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/home'),
                  icon: const Icon(Icons.arrow_right_alt),
                  label: const Text('All Set! Launch Music Nudge'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reelPreview() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 20)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const _MiniDot(AppColors.secondaryContainer),
              const _MiniDot(AppColors.primaryContainer),
              const _MiniDot(AppColors.primary),
              const SizedBox(width: 8),
              Text('Screen Mockup Preview',
                  style: AppText.labelSmall(AppColors.onSurfaceVariant)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('LIVE OVERLAY', style: AppText.labelSmall(AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 176,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.tertiaryContainer.withValues(alpha: 0.35),
                    AppColors.surfaceLow,
                    AppColors.surfaceLowest,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  SmartImage(
                    url: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAt6n-sutEbu9HNVLsn9fmOHxXtC5EpiANYiNHUL_TgUMjixC_e_6gAgb3VG5ZgoN2NIsLqk2RRcZrXxXnp1puNk3nt6NNHo7LR_GwDFOoAiomirYToxYKTnBWNsDEqQgsHuHyEDrF-rKbWritBqgWIKSTDSxW6y7YdK2vtEhr7yN0qQnB2G521xhq_EZo5M2dSaVjc8chpUfyLEjhndpLgsmrYRglhfr89gObQiaI',
                    fallback: [AppColors.tertiaryContainer, AppColors.surfaceLowest],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, AppColors.surfaceLowest],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [BoxShadow(color: Color(0x5533E076), blurRadius: 18)],
                      ),
                      child: Row(children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: AppColors.primaryContainer),
                          child: const Icon(Icons.music_cast, size: 12, color: AppColors.onPrimary),
                        ),
                        const SizedBox(width: 6),
                        Text('Nudge ready',
                            style: AppText.labelSmall(AppColors.onSurface)),
                      ]),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHigh.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle, color: AppColors.primary),
                              child: const Icon(Icons.graphic_eq, size: 10, color: AppColors.onPrimary),
                            ),
                            const SizedBox(width: 6),
                            Text('Neon Groove • Synth Tribe',
                                style: AppText.labelSmall(AppColors.onSurface)),
                          ]),
                        ),
                        const SizedBox(height: 6),
                        Text('@nightwave_sessions',
                            style: AppText.labelMedium(AppColors.onSurface)),
                      ],
                    ),
                  ),
                  const Positioned(
                    right: 12,
                    bottom: 12,
                    child: Column(children: [
                      _RoundIcon(Icons.favorite),
                      SizedBox(height: 8),
                      _RoundIcon(Icons.chat_bubble),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniDot extends StatelessWidget {
  final Color color;
  const _MiniDot(this.color);
  @override
  Widget build(BuildContext context) => Container(
        width: 10,
        height: 10,
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  const _RoundIcon(this.icon);
  @override
  Widget build(BuildContext context) => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceHigh.withValues(alpha: 0.7),
        ),
        child: Icon(icon, size: 16, color: AppColors.onSurface),
      );
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String status;
  final Color statusColor;
  final String description;
  final bool granted;
  final String action;
  const _PermissionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.status,
    required this.statusColor,
    required this.description,
    required this.granted,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.all(Radius.circular(12))),
            child: Icon(icon, size: 26, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: AppText.titleMedium(AppColors.onSurface),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(children: [
                        Icon(granted ? Icons.check_circle : Icons.lock,
                            size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(status, style: AppText.labelSmall(statusColor)),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(description, style: AppText.bodySmall(AppColors.onSurfaceVariant)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (granted)
                      Row(children: [
                        const _Dot(color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text('Permission Granted',
                            style: AppText.labelSmall(AppColors.primary)),
                      ])
                    else
                      Row(children: [
                        const Icon(Icons.lock, size: 14, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text('System Prompt',
                            style: AppText.labelSmall(AppColors.secondary)),
                      ]),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.surfaceHigh,
                        foregroundColor: AppColors.onSurfaceVariant,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: Text(action, style: AppText.labelMedium(AppColors.onSurfaceVariant)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}
