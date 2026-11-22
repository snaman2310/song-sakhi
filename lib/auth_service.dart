import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // TODO: Replace these strings with your real keys / secrets once you have them.
  static const _spotifyClientId     = 'YOUR_SPOTIFY_CLIENT_ID';
  static const _spotifyClientSecret = 'YOUR_SPOTIFY_CLIENT_SECRET';
  static const _spotifyRedirectUri  = 'YOUR_SPOTIFY_REDIRECT_URI';

  static const _ytClientId     = 'YOUR_YT_CLIENT_ID';
  static const _ytClientSecret = 'YOUR_YT_CLIENT_SECRET';
  static const _ytRedirectUri  = 'YOUR_YT_REDIRECT_URI';

  Future<void> initialise() async {
    final prefs = await SharedPreferences.getInstance();
    // For the prototype we just initialise – real token handling comes later.
  }

  String getSpotifyAuthUrl() =>
      'https://accounts.spotify.com/authorize?'
      'client_id=$_spotifyClientId'
      '&response_type=code'
      '&redirect_uri=$_spotifyRedirectUri'
      '&scope=playlist-modify-public%20playlist-modify-private%20user-read-email'
      '&state=randomstate&show_dialog=true';

  String getYouTubeAuthUrl() =>
      'https://accounts.google.com/o/oauth2/v2/auth?'
      'client_id=$_ytClientId'
      '&redirect_uri=_ytRedirectUri'
      '&response_type=code'
      '&scope=https://www.googleapis.com/auth/youtube.force-ssl'
      '&access_type=offline';

  Future<Map<String, String>> exchangeCode(String code, {required String kind}) async {
    // For now return dummy tokens so the app doesn’t crash.
    return {'accessToken': 'dummy_$kind_token', 'refreshToken': 'dummy_$kind_refresh'};
  }
}