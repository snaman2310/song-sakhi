import 'package:flutter/material.dart';

class PlaylistSelectorScreen extends StatefulWidget {
  const PlaylistSelectorScreen({super.key});
  @override State<PlaylistSelectorScreen> createState() =>
      _PlaylistSelectorScreenState();
}

class _PlaylistSelectorScreenState extends State<PlaylistSelectorScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Playlist')),
      body: const Center(
        child: Text(
          'Pick the playlist you want to add the selected songs to.\n'
          '(Implementation pending – add your API calls here.)',
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Songs added! (placeholder)')),
          );
        },
        child: const Icon(Icons.arrow_right),
      ),
    );
  }
}