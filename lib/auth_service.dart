import 'package:shared_preferences/shared_preferences.dart';

/// Auth service for the Flutter web app.
///
/// OAuth is handled by the small Node backend on Render, which holds the
/// client secrets in environment variables. The app only:
///   1. redirects the browser to  <backend>/auth/google | /auth/spotify
///   2. receives the tokens back in the URL fragment (#/auth-done?...)
///   3. stores them locally.
class AuthService {
  // Public backend that performs the OAuth code -> token exchange.
  static const _backendUrl = 'https://song-sakhi-auth.onrender.com';

  // Token storage keys
  static const _kSpotifyToken = 'spotify_access_token';
  static const _kYoutubeToken = 'youtube_access_token';
  static const _kSpotifyRefresh = 'spotify_refresh_token';
  static const _kYoutubeRefresh = 'youtube_refresh_token';

  String? _accessToken;
  String? get accessToken => _accessToken;
  set accessToken(String? value) => _accessToken = value;

  Future<void> initialise() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_kSpotifyToken) ?? prefs.getString(_kYoutubeToken);
  }

  Future<String?> tokenFor(String kind) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kind == 'spotify' ? _kSpotifyToken : _kYoutubeToken);
  }

  /// Returns the backend URL that starts the OAuth flow for [kind].
  /// The backend holds the secrets and performs the token exchange.
  String buildAuthUrl(String kind) {
    final path = (kind == 'spotify') ? '/auth/spotify' : '/auth/google';
    return '$_backendUrl$path';
  }

  /// Stores tokens received from the backend callback.
  Future<Map<String, String>> storeTokensFromCallback({
    required String provider,
    required String accessToken,
    String refreshToken = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final isSpotify = provider == 'spotify';

    await prefs.setString(
      isSpotify ? _kSpotifyToken : _kYoutubeToken,
      accessToken,
    );
    if (refreshToken.isNotEmpty) {
      await prefs.setString(
        isSpotify ? _kSpotifyRefresh : _kYoutubeRefresh,
        refreshToken,
      );
    }
    _accessToken = accessToken;

    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'kind': provider,
    };
  }
}
