import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../auth_service.dart';
import '../theme.dart';

/// Handles the redirect back from the OAuth backend.
///
/// Backend redirects to either:
///   #/auth-done?provider=google&access_token=...&refresh_token=...
///   #/auth-error?message=...
class CallbackScreen extends StatefulWidget {
  const CallbackScreen({super.key});

  @override
  State<CallbackScreen> createState() => _CallbackScreenState();
}

class _CallbackScreenState extends State<CallbackScreen> {
  String _message = 'Completing sign-in…';
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _handle();
  }

  Future<void> _handle() async {
    try {
      final hash = html.window.location.hash; // e.g. #/auth-done?provider=...
      final uri = Uri.parse(hash.replaceFirst('#', ''));
      final path = uri.path;

      // Clear the fragment immediately so a refresh can't replay the tokens.
      html.window.history.replaceState(null, '', '/#/connect');

      if (path == '/auth-error') {
        final msg = uri.queryParameters['message'] ?? 'Unknown error';
        throw Exception(msg);
      }

      final provider = uri.queryParameters['provider'] ?? '';
      final access = uri.queryParameters['access_token'] ?? '';
      final refresh = uri.queryParameters['refresh_token'] ?? '';

      if (access.isEmpty) {
        throw Exception('No access token received from auth server.');
      }

      final result = await AuthService().storeTokensFromCallback(
        provider: provider,
        accessToken: access,
        refreshToken: refresh,
      );

      if (!mounted) return;
      setState(() => _message = 'Connected to '
          '${result['kind'] == 'spotify' ? 'Spotify' : 'YouTube Music'}!');

      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pushReplacementNamed(context, '/connect');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _message = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _error ? Icons.error_outline : Icons.check_circle,
                size: 72,
                color: _error ? AppColors.secondaryContainer : AppColors.primary,
              ),
              const SizedBox(height: 20),
              Text(
                _error ? 'Could not connect' : 'Connecting…',
                style: AppText.headlineLarge(AppColors.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _message,
                style: AppText.bodyMedium(AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              if (!_error) ...[
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: AppColors.primary),
              ] else ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text('Back to Login'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
