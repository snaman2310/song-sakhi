import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  static const _key = 'saved_songs';
  static const _playlistKey = 'saved_songs_playlist';

  Future<List<Map<String, String>>> getSavedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = json.decode(raw) as List<dynamic>;
      return list
          .map((e) => <String, String>{
                'title': (e['title'] ?? '').toString(),
                'artist': (e['artist'] ?? '').toString(),
              })
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> addSongs(List<Map<String, String>> songs) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getSavedSongs();
    final merged = <Map<String, String>>[...current, ...songs];
    await prefs.setString(_key, json.encode(merged));
  }

  Future<String> getLastPlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_playlistKey) ?? 'My Playlist';
  }

  Future<void> setLastPlaylist(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playlistKey, name);
  }
}
