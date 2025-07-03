import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'store_logic.dart';
import 'player_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final libraryStore = Provider.of<LibraryStore>(context);
    final bookIds = libraryStore.ownedBooks.toList();

    // These would come from the persisted catalog in a real app
    final bookData = {
      "b1": {
        "title": "The Swift Journey",
        "author": "Jane Doe",
        "coverUrl": "",
        "audioUrl": "",
      },
      "b2": {
        "title": "Flutter for All",
        "author": "John Smith",
        "coverUrl": "",
        "audioUrl": "",
      },
      "b3": {
        "title": "AI Revolution",
        "author": "Susan Lin",
        "coverUrl": "",
        "audioUrl": "",
      },
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: bookIds.isEmpty
        ? const Center(child: Text("No books in library.\nGo to Store & Buy!", textAlign: TextAlign.center,))
        : ListView.builder(
            itemCount: bookIds.length,
            itemBuilder: (context, idx) {
              final id = bookIds[idx];
              final title = bookData[id]?["title"] ?? "Unknown Title";
              final author = bookData[id]?["author"] ?? "Unknown Author";
              final coverUrl = bookData[id]?["coverUrl"] ?? "";
              final audioUrl = bookData[id]?["audioUrl"] ?? "";
              return ListTile(
                leading: const Icon(Icons.headset, color: Colors.green),
                title: Text(title),
                subtitle: Text(author),
                trailing: const Text('Owned', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => PlayerScreen(
                      bookId: id,
                      title: title,
                      author: author,
                      coverUrl: coverUrl,
                      audioUrl: audioUrl,
                      isOwned: true,
                    ),
                  ));
                },
              );
            }
          ),
    );
  }
}
