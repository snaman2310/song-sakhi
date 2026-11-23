import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Auth service for the Flutter app.
///
/// OAuth is handled by the small Node backend on Render, which holds the
/// client secrets in environment variables. The app only:
///   1. redirects the browser to  <backend>/auth/google | /auth/spotify
///   2. receives the tokens back in the URL fragment (#/auth-done?...)
///   3. stores them locally and refreshes them through the backend.
class AuthService {
  // Public backend that performs the OAuth code -> token exchange.
  static const backendUrl = 'https://song-sakhi-auth1.onrender.com';

  // Token storage keys
  static const _kSpotifyToken = 'spotify_access_token';
  static const _kYoutubeToken = 'youtube_access_token';
  static const _kSpotifyRefresh = 'spotify_refresh_token';
  static const _kYoutubeRefresh = 'youtube_refresh_token';
  static const _kSpotifyIssued = 'spotify_token_issued_at';
  static const _kYoutubeIssued = 'youtube_token_issued_at';

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

  Future<bool> isConnected(String kind) async {
    final token = await tokenFor(kind);
    return token != null && token.isNotEmpty;
  }

  /// Returns a usable access token, refreshing it through the backend when it is
  /// missing, older than ~50 minutes, or when [force] is set.
  ///
  /// Access tokens from Google/Spotify expire after ~1 hour, so without this the
  /// playlist save would start failing with 401 after the first hour.
  Future<String?> freshToken(String kind, {bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final isSpotify = kind == 'spotify';
    final accessKey = isSpotify ? _kSpotifyToken : _kYoutubeToken;
    final refreshKey = isSpotify ? _kSpotifyRefresh : _kYoutubeRefresh;
    final issuedKey = isSpotify ? _kSpotifyIssued : _kYoutubeIssued;

    final access = prefs.getString(accessKey);
    final refresh = prefs.getString(refreshKey);
    final issued = prefs.getInt(issuedKey) ?? 0;

    final age = DateTime.now().millisecondsSinceEpoch - issued;
    final stale = access == null ||
        access.isEmpty ||
        (issued > 0 && age > const Duration(minutes: 50).inMilliseconds);

    if (!force && !stale) return access;
    if (refresh == null || refresh.isEmpty) return access;

    try {
      final res = await http
          .post(
            Uri.parse('$backendUrl/api/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'provider': isSpotify ? 'spotify' : 'google',
              'refreshToken': refresh,
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final newAccess = data['access_token']?.toString();
        if (newAccess != null && newAccess.isNotEmpty) {
          await prefs.setString(accessKey, newAccess);
          final newRefresh = data['refresh_token']?.toString();
          if (newRefresh != null && newRefresh.isNotEmpty) {
            await prefs.setString(refreshKey, newRefresh);
          }
          await prefs.setInt(issuedKey, DateTime.now().millisecondsSinceEpoch);
          _accessToken = newAccess;
          return newAccess;
        }
      }
    } catch (_) {
      // Offline or backend asleep – fall back to the stored token.
    }
    return access;
  }

  /// Removes every stored OAuth token (used by Sign out / Reconnect).
  Future<void> clearTokens({String? kind}) async {
    final prefs = await SharedPreferences.getInstance();
    if (kind == 'spotify') {
      await prefs.remove(_kSpotifyToken);
      await prefs.remove(_kSpotifyRefresh);
      await prefs.remove(_kSpotifyIssued);
    } else if (kind == 'google') {
      await prefs.remove(_kYoutubeToken);
      await prefs.remove(_kYoutubeRefresh);
      await prefs.remove(_kYoutubeIssued);
    } else {
      await prefs.remove(_kSpotifyToken);
      await prefs.remove(_kYoutubeToken);
      await prefs.remove(_kSpotifyRefresh);
      await prefs.remove(_kYoutubeRefresh);
      await prefs.remove(_kSpotifyIssued);
      await prefs.remove(_kYoutubeIssued);
    }
    _accessToken = null;
  }

  /// Returns the backend URL that starts the OAuth flow for [kind].
  /// The backend holds the secrets and performs the token exchange.
  String buildAuthUrl(String kind) {
    final path = (kind == 'spotify') ? '/auth/spotify' : '/auth/google';
    return '$backendUrl$path';
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
    await prefs.setInt(
      isSpotify ? _kSpotifyIssued : _kYoutubeIssued,
      DateTime.now().millisecondsSinceEpoch,
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
