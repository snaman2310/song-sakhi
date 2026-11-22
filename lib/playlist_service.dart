import 'package:http/http.dart' as http;
import 'dart:convert';

class PlaylistService {
  Future<void> addSongsToSpotifyPlaylist({
    required String playlistId,
    required List<String> trackUris,
    required String accessToken,
  }) async {
    final url = Uri.parse('https://api.spotify.com/v1/playlists/$playlistId/tracks');
    await http.post(
      url,
      headers: {'Authorization': 'Bearer $accessToken'},
      body: json.encode({'uris': trackUris}),
    );
  }

  Future<void> addSongsToYouTubeMusicPlaylist({
    required String playlistId,
    required List<String> videoIds,
    required String accessToken,
  }) async {
    final url = Uri.parse(
        'https://www.googleapis.com/youtube/v3/playlistItems?part=snippet');
    await http.post(
      url,
      headers: {'Authorization': 'Bearer $accessToken'},
      body: json.encode({
        'playlistId': playlistId,
        'items': videoIds.map((id) => {'snippet': {'resourceId': {'videoId': id}}}).toList(),
      }),
    );
  }
}