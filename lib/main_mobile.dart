import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'auth_service.dart';
import 'theme.dart';
import 'mobile/mobile_login_screen.dart';
import 'mobile/mobile_connect_screen.dart';
import 'mobile/mobile_callback_screen.dart';
import 'mobile/mobile_capture_screen.dart';
import 'mobile/mobile_permissions_screen.dart';
import 'screens/saved_songs_screen.dart';
import 'screens/song_selection_screen.dart';
import 'screens/playlist_save_screen.dart';
import 'screens/confirmation_screen.dart';

final _linkController = StreamController<Uri>.broadcast();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService().initialise();

  final appLinks = AppLinks();
  final initial = await appLinks.getInitialLink();
  if (initial != null) _linkController.add(initial);
  appLinks.uriLinkStream.listen((uri) => _linkController.add(uri));

  runApp(const MobileApp());
}

class MobileApp extends StatefulWidget {
  const MobileApp({super.key});
  @override
  State<MobileApp> createState() => _MobileAppState();
}

class _MobileAppState extends State<MobileApp> {
  final _navKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = _linkController.stream.listen((uri) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (uri.host == 'auth' || uri.host == 'auth-error') {
          _navKey.currentState?.pushNamed('/callback', arguments: uri.toString());
        }
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navKey,
      title: 'Song Sakhi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: '/',
      routes: {
        '/': (ctx) => const MobileLoginScreen(),
        '/connect': (ctx) => const MobileConnectScreen(),
        '/callback': (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments;
          return MobileCallbackScreen(uriString: args is String ? args : null);
        },
        '/permissions': (ctx) => const MobilePermissionsScreen(),
        '/home': (ctx) => const SavedSongsScreen(),
        // "Capture Reel" FAB / Discover tab -> real audio capture flow.
        '/nudge': (ctx) => const MobileCaptureScreen(),
        '/capture': (ctx) => const MobileCaptureScreen(),
        '/suggestions': (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments;
          final songs = args is List<Map<String, String>> ? args : null;
          return SongSelectionScreen(suggestions: songs);
        },
        '/playlist': (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments;
          final songs = args is List<Map<String, String>> ? args : const [];
          return PlaylistSaveScreen(songs: songs);
        },
        '/confirmation': (ctx) => const ConfirmationScreen(),
      },
    );
  }
}
