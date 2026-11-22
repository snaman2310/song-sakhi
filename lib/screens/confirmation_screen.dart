import 'package:flutter/material.dart';

class ConfirmationScreen extends StatelessWidget {
  final int addedCount;
  final String playlistName;
  const ConfirmationScreen({
    required this.addedCount,
    required this.playlistName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 100),
            const SizedBox(height: 20),
            Text(
              'Added $addedCount songs to "$playlistName" playlist',
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.popUntil(
                  context, (route) => route.isFirst),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}