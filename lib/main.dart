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
      // Use a route resolver so OAuth callbacks in the hash are handled even
      // when the fragment contains a query string (e.g. #/callback?code=...).
      onGenerateInitialRoutes: (initialRoute) {
        final path = _cleanPath(initialRoute);
        if (path == '/auth-done' || path == '/auth-error' || path == '/callback') {
          return [MaterialPageRoute(builder: (_) => const CallbackScreen())];
        }
        return [MaterialPageRoute(builder: (_) => const LoginScreen())];
      },
      onGenerateRoute: (settings) {
        final path = _cleanPath(settings.name ?? '/');
        switch (path) {
          case '/':
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/connect':
            return MaterialPageRoute(builder: (_) => const ConnectHubsScreen());
          case '/permissions':
            return MaterialPageRoute(builder: (_) => const PermissionsScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const SavedSongsScreen());
          case '/nudge':
            return MaterialPageRoute(builder: (_) => const NudgeListeningScreen());
          case '/suggestions':
            return MaterialPageRoute(builder: (_) => const SongSelectionScreen());
          case '/playlist':
            final songs = settings.arguments;
            return MaterialPageRoute(
              builder: (_) => PlaylistSaveScreen(
                songs: songs is List<Map<String, String>> ? songs : const [],
              ),
            );
          case '/confirmation':
            return MaterialPageRoute(builder: (_) => const ConfirmationScreen());
          case '/callback':
          case '/auth-done':
          case '/auth-error':
            return MaterialPageRoute(builder: (_) => const CallbackScreen());
          default:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
      },
    );
  }

  /// Strips the leading `#` and any query string from a route/hash value.
  String _cleanPath(String raw) {
    var p = raw;
    if (p.startsWith('#')) p = p.substring(1);
    final q = p.indexOf('?');
    if (q != -1) p = p.substring(0, q);
    if (p.isEmpty) return '/';
    if (!p.startsWith('/')) p = '/$p';
    return p;
  }
}
