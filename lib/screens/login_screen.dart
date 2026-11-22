import 'package:flutter/material.dart';
import 'package:music_nudge_app/auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _signInWithSpotify(BuildContext ctx) async {
    final service = AuthService();
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text('Spotify OAuth – placeholder (replace later)')),
    );
    // Navigator.pushReplacementNamed(ctx, '/home');
  }

  void _signInWithYouTube(BuildContext ctx) async {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text('YouTube Music OAuth – placeholder')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Music Nudge – Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Connect your music service:'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _signInWithSpotify(context),
              icon: const Icon(Icons.music_note),
              label: const Text('Spotify'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _signInWithYouTube(context),
              icon: const Icon(Icons.music_note),
              label: const Text('YouTube Music'),
            ),
          ],
        ),
      ),
    );
  }
}