import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme.dart';
import '../widgets.dart';

class MobilePermissionsScreen extends StatefulWidget {
  const MobilePermissionsScreen({super.key});
  @override
  State<MobilePermissionsScreen> createState() => _MobilePermissionsScreenState();
}

class _MobilePermissionsScreenState extends State<MobilePermissionsScreen>
    with WidgetsBindingObserver {
  bool _micGranted = false;
  bool _overlayDone = false;
  bool _batteryDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check when the user comes back from Android Settings.
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final status = await Permission.microphone.status;
    if (mounted) setState(() => _micGranted = status.isGranted);
  }

  Future<void> _requestMic() async {
    final status = await Permission.microphone.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }
    if (mounted) setState(() => _micGranted = status.isGranted);
  }

  Future<void> _openSettings() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final allDone = _micGranted && _overlayDone && _batteryDone;
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
                'Music Nudge needs a few Android permissions to listen to reels and '
                'show the floating nudge. Tap each item to open Settings and enable it.',
                style: AppText.bodyMedium(AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),

              _PermCard(
                icon: Icons.picture_in_picture_alt,
                color: AppColors.primary,
                title: 'Display Over Other Apps',
                description: 'Lets the compact Nudge button float above Instagram and '
                    'TikTok while you scroll.',
                done: _overlayDone,
                actionLabel: _overlayDone ? 'Enabled' : 'Open Settings',
                onAction: () async {
                  await _openSettings();
                  if (mounted) setState(() => _overlayDone = true);
                },
              ),
              const SizedBox(height: 12),
              _PermCard(
                icon: Icons.mic,
                color: AppColors.secondaryContainer,
                title: 'Media Listener Audio',
                description: 'Allows the app to capture a short clip of the reel audio '
                    'so Gemini can identify the song.',
                done: _micGranted,
                actionLabel: _micGranted ? 'Granted' : 'Grant Permission',
                onAction: _requestMic,
              ),
              const SizedBox(height: 12),
              _PermCard(
                icon: Icons.battery_saver,
                color: AppColors.tertiary,
                title: 'Battery (Recommended)',
                description: 'Exclude Music Nudge from battery optimisation so the '
                    'nudge stays responsive.',
                done: _batteryDone,
                actionLabel: _batteryDone ? 'Done' : 'Open Settings',
                onAction: () async {
                  await _openSettings();
                  if (mounted) setState(() => _batteryDone = true);
                },
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
                    const Icon(Icons.verified_user,
                        size: 22, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Audio is analysed only for the active capture and never '
                        'stored on disk.',
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
                  onPressed: _micGranted
                      ? () => Navigator.pushReplacementNamed(context, '/home')
                      : null,
                  icon: const Icon(Icons.arrow_right_alt),
                  label: Text(allDone
                      ? 'All Set! Launch Music Nudge'
                      : 'Continue (Microphone required)'),
                ),
              ),
              if (!_micGranted)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'Grant the microphone permission above to continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.secondary, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final bool done;
  final String actionLabel;
  final VoidCallback onAction;

  const _PermCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.done,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: done
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.all(Radius.circular(12))),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(title, style: AppText.titleMedium(AppColors.onSurface)),
                  ),
                  if (done)
                    const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                ]),
                const SizedBox(height: 6),
                Text(description, style: AppText.bodySmall(AppColors.onSurfaceVariant)),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.surfaceHigh,
                      foregroundColor:
                          done ? AppColors.primary : AppColors.onSurface,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    ),
                    child: Text(actionLabel, style: AppText.labelMedium(
                        done ? AppColors.primary : AppColors.onSurface)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
