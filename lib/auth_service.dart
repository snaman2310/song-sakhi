import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Real public client IDs (safe to ship in a web app).
  static const _spotifyClientId = '3a108eb4fbb846bcafe8c52c359098f6';
  static const _spotifyRedirectUri = 'https://song-sakhi.onrender.com/callback';

  static const _ytClientId =
      '331023929615-ffl7jhc7s3oqspdl5nseifdql59b8u0h.apps.googleusercontent.com';
  static const _ytRedirectUri = 'https://song-sakhi.onrender.com/callback';

  // Token storage keys
  static const _kSpotifyToken = 'spotify_access_token';
  static const _kYoutubeToken = 'youtube_access_token';
  static const _kSpotifyRefresh = 'spotify_refresh_token';
  static const _kYoutubeRefresh = 'youtube_refresh_token';
  static const _kPendingKind = 'oauth_pending_kind';
  static const _kVerifier = 'oauth_pkce_verifier';

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

  // -----------------------------------------------------------------
  // PKCE helpers
  // -----------------------------------------------------------------
  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~';
    final rnd = Random.secure();
    return List.generate(length, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  String _challenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Builds the authorization URL with PKCE and persists the verifier.
  Future<String> buildAuthUrl(String kind) async {
    final verifier = _randomString(64);
    final codeChallenge = _challenge(verifier);
    final state = _randomString(20);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kVerifier, verifier);
    await prefs.setString(_kPendingKind, kind);

    if (kind == 'spotify') {
      final params = {
        'client_id': _spotifyClientId,
        'response_type': 'code',
        'redirect_uri': _spotifyRedirectUri,
        'scope': 'playlist-modify-public playlist-modify-private user-read-email',
        'state': state,
        'code_challenge_method': 'S256',
        'code_challenge': codeChallenge,
      };
      return Uri.https('accounts.spotify.com', '/authorize', params).toString();
    } else {
      final params = {
        'client_id': _ytClientId,
        'redirect_uri': _ytRedirectUri,
        'response_type': 'code',
        'scope': 'https://www.googleapis.com/auth/youtube.force-ssl',
        'state': state,
        'code_challenge_method': 'S256',
        'code_challenge': codeChallenge,
        'access_type': 'offline',
        'prompt': 'consent',
      };
      return Uri.https('accounts.google.com', '/o/oauth2/v2/auth', params).toString();
    }
  }

  /// Exchanges the authorization code for tokens using PKCE (no client secret).
  Future<Map<String, String>> exchangeCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final kind = prefs.getString(_kPendingKind) ?? 'spotify';
    final verifier = prefs.getString(_kVerifier) ?? '';

    final isSpotify = kind == 'spotify';
    final uri = isSpotify
        ? Uri.parse('https://accounts.spotify.com/api/token')
        : Uri.parse('https://oauth2.googleapis.com/token');

    final body = {
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': isSpotify ? _spotifyRedirectUri : _ytRedirectUri,
      'client_id': isSpotify ? _spotifyClientId : _ytClientId,
      'code_verifier': verifier,
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Token exchange failed (${response.statusCode}): ${response.body}');
    }

    final data = json.decode(response.body);
    final access = data['access_token'] as String;
    final refresh = (data['refresh_token'] ?? '').toString();

    await prefs.setString(isSpotify ? _kSpotifyToken : _kYoutubeToken, access);
    if (refresh.isNotEmpty) {
      await prefs.setString(isSpotify ? _kSpotifyRefresh : _kYoutubeRefresh, refresh);
    }
    _accessToken = access;

    return {'accessToken': access, 'refreshToken': refresh, 'kind': kind};
  }
}
