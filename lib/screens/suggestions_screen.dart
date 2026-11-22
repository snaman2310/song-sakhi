import 'package:flutter/material.dart';
import 'package:music_nudge_app/screens/playlist_selector_screen.dart';

class SuggestionsScreen extends StatelessWidget {
  final List<Map<String, String>> suggestions;
  const SuggestionsScreen({required this.suggestions, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Song suggestions')),
      body: ListView.builder(
        itemCount: suggestions.length,
        itemBuilder: (ctx, i) {
          final s = suggestions[i];
          return ListTile(
            title: Text(s['title'] ?? ''),
            subtitle: Text(s['artist'] ?? ''),
            trailing: Checkbox(
              value: false,
              onChanged: (_) {},
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/playlist'),
          child: const Text('Select playlist & add songs'),
        ),
      ),
    );
  }
}