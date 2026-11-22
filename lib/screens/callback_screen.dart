import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../auth_service.dart';
import '../theme.dart';

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
      // In Flutter web's default hash routing, the code arrives in the hash:
      //   https://song-sakhi.onrender.com/#/callback?code=...&state=...
      String? code;
      final hash = html.window.location.hash;
      if (hash.isNotEmpty) {
        final uri = Uri.parse(hash.replaceFirst('#', ''));
        code = uri.queryParameters['code'];
      }
      // Fallback: query on the base URL
      code ??= Uri.base.queryParameters['code'];

      if (code == null || code.isEmpty) {
        throw Exception('No authorization code found in callback URL.');
      }

      final tokens = await AuthService().exchangeCode(code);
      if (!mounted) return;
      setState(() => _message =
          'Connected to ${tokens['kind'] == 'spotify' ? 'Spotify' : 'YouTube Music'}!');

      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) Navigator.pushReplacementNamed(context, '/connect');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _message = 'Sign-in failed: ${e.toString().replaceAll('Exception: ', '')}';
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
                  onPressed: () => Navigator.pushReplacementNamed(context, '/connect'),
                  child: const Text('Back'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
