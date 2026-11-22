import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/listening_screen.dart';
import 'screens/playlist_selector_screen.dart';
import 'screens/confirmation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService().initialise();
  runApp(const MusicNudgeApp());
}

class MusicNudgeApp extends StatelessWidget {
  const MusicNudgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Nudge',
      theme: ThemeData.dark().copyWith(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF131313),
        primaryColor: const Color(0xFF53E076),
        primaryColorLight: const Color(0xFF72FE8F),
        colorScheme: ColorScheme.dark(
          background: const Color(0xFF131313),
          onBackground: const Color(0xFFE5E2E1),
          surface: const Color(0xFF131313),
          onSurface: const Color(0xFFE5E2E1),
          primary: const Color(0xFF53E076),
          primaryContainer: const Color(0xFF1DB954),
          secondary: const Color(0xFFFDB3AF),
          error: const Color(0xFFFFB4AB),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (ctx) => const LoginScreen(),
        '/home': (ctx) => const HomeScreen(),
        '/listening': (ctx) => const ListeningScreen(),
        '/playlist': (ctx) => const PlaylistSelectorScreen(),
        '/confirmation': (ctx) =>
            const ConfirmationScreen(
              addedCount: 0,
              playlistName: '',
            ),
      },
    );
  }
}