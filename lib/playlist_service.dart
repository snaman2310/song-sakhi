import 'package:http/http.dart' as http;
import 'dart:convert';

class Playlist {
  final String id;
  final String name;
  final int count;
  const Playlist({required this.id, required this.name, required this.count});
}

class PlaylistService {
  static const _spotify = 'https://api.spotify.com/v1';
  static const _youtube = 'https://www.googleapis.com/youtube/v3';

  Map<String, String> _auth(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  // ---------------- Spotify ----------------
  Future<List<Playlist>> spotifyPlaylists(String token) async {
    final r = await http.get(
      Uri.parse('$_spotify/me/playlists?limit=20'),
      headers: _auth(token),
    );
    if (r.statusCode != 200) {
      throw Exception('Spotify playlists (${r.statusCode}): ${r.body}');
    }
    final data = json.decode(r.body) as Map<String, dynamic>;
    final items = (data['items'] as List?) ?? const [];
    return items.map((e) => Playlist(
          id: e['id'].toString(),
          name: e['name'].toString(),
          count: (e['tracks']?['total'] ?? 0) as int,
        )).toList();
  }

  Future<String?> spotifyTrackUri(String token, String title, String artist) async {
    // Double quotes inside a title/artist would break the quoted field filters.
    final t = title.replaceAll('"', '');
    final a = artist.replaceAll('"', '');
    final q = Uri.encodeComponent('track:"$t" artist:"$a"');
    final r = await http.get(
      Uri.parse('$_spotify/search?q=$q&type=track&limit=1'),
      headers: _auth(token),
    );
    if (r.statusCode != 200) return null;
    final data = json.decode(r.body) as Map<String, dynamic>;
    final items = (((data['tracks'] as Map?)?['items']) as List?) ?? const [];
    if (items.isEmpty) return null;
    return items[0]['uri']?.toString();
  }

  Future<void> addToSpotify(
    String token,
    String playlistId,
    List<String> uris,
  ) async {
    if (uris.isEmpty) return;
    final r = await http.post(
      Uri.parse('$_spotify/playlists/$playlistId/tracks'),
      headers: _auth(token),
      body: json.encode({'uris': uris}),
    );
    if (r.statusCode >= 300) {
      throw Exception('Spotify add (${r.statusCode}): ${r.body}');
    }
  }

  // ---------------- YouTube Music ----------------
  Future<List<Playlist>> youtubePlaylists(String token) async {
    final r = await http.get(
      Uri.parse('$_youtube/playlists?part=snippet&mine=true&maxResults=20'),
      headers: _auth(token),
    );
    if (r.statusCode != 200) {
      throw Exception('YouTube playlists (${r.statusCode}): ${r.body}');
    }
    final data = json.decode(r.body) as Map<String, dynamic>;
    final items = (data['items'] as List?) ?? const [];
    return items.map((e) => Playlist(
          id: e['id'].toString(),
          name: (e['snippet']?['title'] ?? 'Untitled').toString(),
          count: 0,
        )).toList();
  }

  Future<String?> youtubeVideoId(String token, String title, String artist) async {
    final q = Uri.encodeComponent('$title $artist official audio');
    final r = await http.get(
      Uri.parse('$_youtube/search?part=snippet&type=video&maxResults=1&q=$q'),
      headers: _auth(token),
    );
    if (r.statusCode != 200) return null;
    final data = json.decode(r.body) as Map<String, dynamic>;
    final items = (data['items'] as List?) ?? const [];
    if (items.isEmpty) return null;
    return items[0]['id']?['videoId']?.toString();
  }

  Future<void> addToYouTube(
    String token,
    String playlistId,
    List<String> videoIds,
  ) async {
    for (final id in videoIds) {
      final r = await http.post(
        Uri.parse('$_youtube/playlistItems?part=snippet'),
        headers: _auth(token),
        body: json.encode({
          'snippet': {
            'playlistId': playlistId,
            'resourceId': {
              'kind': 'youtube#video',
              'videoId': id,
            },
          },
        }),
      );
      if (r.statusCode >= 300) {
        throw Exception('YouTube add (${r.statusCode}): ${r.body}');
      }
    }
  }
}
