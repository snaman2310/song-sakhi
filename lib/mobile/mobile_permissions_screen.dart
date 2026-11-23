import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme.dart';
import '../widgets.dart';

/// Real system-setup screen. Every action launches the corresponding Android
/// permission page and the state is re-read when the user comes back.
class MobilePermissionsScreen extends StatefulWidget {
  const MobilePermissionsScreen({super.key});

  @override
  State<MobilePermissionsScreen> createState() => _MobilePermissionsScreenState();
}

class _MobilePermissionsScreenState extends State<MobilePermissionsScreen>
    with WidgetsBindingObserver {
  bool _mic = false;
  bool _overlay = false;
  bool _battery = false;

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
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final mic = await Permission.microphone.status;
    final overlay = await Permission.systemAlertWindow.status;
    final battery = await Permission.ignoreBatteryOptimizations.status;
    if (!mounted) return;
    setState(() {
      _mic = mic.isGranted;
      _overlay = overlay.isGranted;
      _battery = battery.isGranted;
    });
  }

  Future<void> _request(Permission permission) async {
    final status = await permission.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    await _check();
  }

  @override
  Widget build(BuildContext context) {
    final micOnly = _mic;
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
              Text('Enable the Nudge',
                  style: AppText.headlineLarge(AppColors.onSurface)),
              const SizedBox(height: 8),
              Text(
                'Each button below opens the exact Android setting it needs. '
                'Come back to this screen afterwards — statuses refresh automatically.',
                style: AppText.bodyMedium(AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),

              _PermCard(
                icon: Icons.mic,
                color: AppColors.primary,
                title: 'Microphone (required)',
                description: 'Needed to capture the reel audio so songs can be '
                    'identified. Opens the system permission dialog.',
                done: _mic,
                actionLabel: _mic ? 'Granted' : 'Allow microphone',
                onAction: _mic ? null : () => _request(Permission.microphone),
              ),
              const SizedBox(height: 12),
              _PermCard(
                icon: Icons.picture_in_picture_alt,
                color: AppColors.secondaryContainer,
                title: 'Display over other apps',
                description: 'Lets the floating Nudge button appear above Instagram '
                    'and TikTok. Opens Settings → Special app access → Display over '
                    'other apps.',
                done: _overlay,
                actionLabel: _overlay ? 'Enabled' : 'Open setting',
                onAction: _overlay ? null : () => _request(Permission.systemAlertWindow),
              ),
              const SizedBox(height: 12),
              _PermCard(
                icon: Icons.battery_saver,
                color: AppColors.tertiary,
                title: 'Battery optimisation (recommended)',
                description: 'Stops Android from killing the nudge in the background. '
                    'Opens the system "ignore battery optimisation" prompt.',
                done: _battery,
                actionLabel: _battery ? 'Exempt' : 'Open setting',
                onAction:
                    _battery ? null : () => _request(Permission.ignoreBatteryOptimizations),
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
                        'Only the clip you capture is sent for identification. '
                        'Nothing is recorded in the background.',
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
                  onPressed: micOnly
                      ? () => Navigator.pushNamedAndRemoveUntil(
                          context, '/home', (r) => false)
                      : null,
                  icon: const Icon(Icons.arrow_right_alt),
                  label: Text(micOnly ? 'Continue to Song Sakhi' : 'Microphone required'),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/settings'),
                child: const Text('Open full settings'),
              ),
              if (!micOnly)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Tap "Allow microphone" above to continue. The other two are optional.',
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
  final VoidCallback? onAction;

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
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Icon(icon, size: 24, color: color),
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
                          style: AppText.titleMedium(AppColors.onSurface)),
                    ),
                    if (done)
                      const Icon(Icons.check_circle,
                          size: 16, color: AppColors.primary),
                  ],
                ),
                const SizedBox(height: 6),
                Text(description,
                    style: AppText.bodySmall(AppColors.onSurfaceVariant)),
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
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    ),
                    child: Text(
                      actionLabel,
                      style: AppText.labelMedium(
                          done ? AppColors.primary : AppColors.onSurface),
                    ),
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
