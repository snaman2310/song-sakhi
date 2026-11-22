import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/connect_hubs_screen.dart';
import 'screens/permissions_screen.dart';
import 'screens/saved_songs_screen.dart';
import 'screens/nudge_listening_screen.dart';
import 'screens/song_selection_screen.dart';
import 'screens/playlist_save_screen.dart';
import 'screens/confirmation_screen.dart';
import 'screens/callback_screen.dart';

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
      title: 'Song Sakhi – Music Nudge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routes: {
        '/': (ctx) => const LoginScreen(),
        '/login': (ctx) => const LoginScreen(),
        '/connect': (ctx) => const ConnectHubsScreen(),
        '/permissions': (ctx) => const PermissionsScreen(),
        '/home': (ctx) => const SavedSongsScreen(),
        '/nudge': (ctx) => const NudgeListeningScreen(),
        '/suggestions': (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments;
          final songs = args is List<Map<String, String>> ? args : null;
          return SongSelectionScreen(suggestions: songs);
        },
        '/playlist': (ctx) => const PlaylistSaveScreen(),
        '/confirmation': (ctx) => const ConfirmationScreen(),
        '/callback': (ctx) => const CallbackScreen(),
      },
    );
  }
}
