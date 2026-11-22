import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // TODO: Replace these strings with your real keys / secrets once you have them.
  static const _spotifyClientId     = '3a108eb4fbb846bcafe8c52c359098f6';
  static const _spotifyClientSecret = 'YOUR_SPOTIFY_CLIENT_SECRET';
  static const _spotifyRedirectUri  = 'https://song-sakhi.onrender.com/callback';

  static const _ytClientId     = '331023929615-ffl7jhc7s3oqspdl5nseifdql59b8u0h.apps.googleusercontent.com';
  static const _ytClientSecret = 'YOUR_YT_CLIENT_SECRET';
  static const _ytRedirectUri  = 'https://song-sakhi.onrender.com/callback';

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
      '&redirect_uri=$_ytRedirectUri'
      '&response_type=code'
      '&scope=https://www.googleapis.com/auth/youtube.force-ssl'
      '&access_type=offline';

  Future<Map<String, String>> exchangeCode(String code, {required String kind}) async {
    // For now return dummy tokens so the app doesn’t crash.
    return {
      'accessToken': 'dummy_${kind}_token',
      'refreshToken': 'dummy_${kind}_refresh',
    };
  }
}
