import 'package:flutter/material.dart';
import '../auth_service.dart';
import '../theme.dart';
import '../widgets.dart';
import 'mobile_auth_launcher.dart';

class MobileConnectScreen extends StatefulWidget {
  const MobileConnectScreen({super.key});
  @override
  State<MobileConnectScreen> createState() => _MobileConnectScreenState();
}

class _MobileConnectScreenState extends State<MobileConnectScreen> {
  bool _spotifyOn = false;
  bool _ytConnected = false;
  bool _autoAdd = true;
  String? _error;

  Future<void> _connect(String kind) async {
    final err = await startMobileOAuth(kind);
    if (err != null && mounted) setState(() => _error = err);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = AuthService();
    final s = await auth.tokenFor('spotify');
    final y = await auth.tokenFor('google');
    if (!mounted) return;
    setState(() {
      _spotifyOn = s != null && s.isNotEmpty;
      _ytConnected = y != null && y.isNotEmpty;
    });
  }

  Widget _card({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool connected,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: connected ? AppColors.surfaceContainer : AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(16),
        border: connected
            ? Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.4))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
                color: AppColors.surfaceLowest,
                borderRadius: BorderRadius.all(Radius.circular(12))),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.titleLarge(AppColors.onSurface)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: AppText.bodySmall(connected ? AppColors.primary : AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          elevatedToggle(connected, onTap),
        ],
      ),
    );
  }

  Widget elevatedToggle(bool connected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: connected ? AppColors.primaryContainer : AppColors.surfaceHigh,
        ),
        child: Icon(connected ? Icons.check : Icons.add_link,
            size: 18,
            color: connected ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant),
      ),
    );
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
                  Text('Connect your music hub',
                      style: AppText.headlineLarge(AppColors.onSurface)),
                  const SizedBox(height: 8),
                  Text('Choose the services where your playlists live.',
                      style: AppText.bodyMedium(AppColors.onSurfaceVariant)),
                  if (_error != null) ...[
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
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 8),
                  _card(
                    icon: Icons.album,
                    color: AppColors.primaryContainer,
                    title: 'Spotify',
                    subtitle: _spotifyOn ? 'Connected' : 'Tap to connect',
                    connected: _spotifyOn,
                    onTap: () => _connect('spotify'),
                  ),
                  const SizedBox(height: 14),
                  _card(
                    icon: Icons.play_circle,
                    color: AppColors.secondaryContainer,
                    title: 'YouTube Music',
                    subtitle: _ytConnected ? 'Connected' : 'Tap to connect',
                    connected: _ytConnected,
                    onTap: () => _connect('google'),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, size: 20, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text("Auto-add to 'Nudge Discovery'",
                              style: AppText.titleMedium(AppColors.onSurface)),
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
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/home'),
                    child: const Text('Skip for now'),
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
