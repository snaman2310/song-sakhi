import 'package:flutter/material.dart';
import '../auth_service.dart';
import '../theme.dart';

class MobileCallbackScreen extends StatefulWidget {
  final String? uriString;
  const MobileCallbackScreen({this.uriString, super.key});

  @override
  State<MobileCallbackScreen> createState() => _MobileCallbackScreenState();
}

class _MobileCallbackScreenState extends State<MobileCallbackScreen> {
  String _message = 'Completing sign-in…';
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _handle();
  }

  Future<void> _handle() async {
    try {
      final raw = widget.uriString ?? '';
      final uri = Uri.parse(raw);
      if (uri.host == 'auth-error') {
        throw Exception(uri.queryParameters['message'] ?? 'Unknown error');
      }
      final provider = uri.queryParameters['provider'] ?? '';
      final access = uri.queryParameters['access_token'] ?? '';
      final refresh = uri.queryParameters['refresh_token'] ?? '';
      if (access.isEmpty) throw Exception('No access token received.');

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
              Icon(_error ? Icons.error_outline : Icons.check_circle,
                  size: 72,
                  color: _error ? AppColors.secondaryContainer : AppColors.primary),
              const SizedBox(height: 20),
              Text(_error ? 'Could not connect' : 'Connecting…',
                  style: AppText.headlineLarge(AppColors.onSurface)),
              const SizedBox(height: 12),
              Text(_message,
                  style: AppText.bodyMedium(AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center),
              if (!_error)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                    child: const Text('Back to Login'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
