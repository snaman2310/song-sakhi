import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Music Nudge')),
      body: const Center(
        child: Text('Instagram open – tap the Nudge FAB'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/listening'),
        tooltip: 'Nudge',
        child: const Icon(Icons.mic),
      ),
    );
  }
}