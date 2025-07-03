import 'package:flutter/material.dart';

class PlayerScreen extends StatelessWidget {
  final String bookId;
  final String title;
  final String author;
  final String coverUrl;
  final String audioUrl;
  final bool isOwned;

  const PlayerScreen({
    super.key,
    required this.bookId,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.audioUrl,
    required this.isOwned,
  });

  @override
  Widget build(BuildContext context) {
    // Replace with actual player logic
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.headset, size: 80, color: Colors.blueGrey),
            const SizedBox(height: 30),
            Text("Player for \"$title\"", style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 20),
            Text(
              isOwned ? "You own this audiobook." : "Demo Preview",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Text("Playback UI coming soon"),
          ],
        ),
      ),
    );
  }
}
