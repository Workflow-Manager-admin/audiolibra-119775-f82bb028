import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'store_logic.dart';
import 'player_screen.dart';

// Declare model class in one place, to match main.dart.
class Audiobook {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final double price;
  final String description;
  final String audioUrl;

  Audiobook({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.price,
    required this.description,
    required this.audioUrl,
  });
}

// Dummy store; should use defaultStoreBooks from main.dart for real.
final _storeBooks = [
  Audiobook(
    id: "b1",
    title: "The Swift Journey",
    author: "Jane Doe",
    coverUrl: "",
    price: 8.99,
    description: "A modern journey through code.",
    audioUrl: "",
  ),
  Audiobook(
    id: "b2",
    title: "Flutter for All",
    author: "John Smith",
    coverUrl: "",
    price: 12.99,
    description: "Beginning mobile with Flutter.",
    audioUrl: "",
  ),
  Audiobook(
    id: "b3",
    title: "AI Revolution",
    author: "Susan Lin",
    coverUrl: "",
    price: 13.99,
    description: "AI's impact on society.",
    audioUrl: "",
  ),
];

class StoreScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final libraryStore = Provider.of<LibraryStore>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Store')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _storeBooks.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 12, mainAxisSpacing: 12,
        ),
        itemBuilder: (context, idx) {
          final book = _storeBooks[idx];
          final owned = libraryStore.isOwned(book.id);
          return GestureDetector(
            onTap: owned
                ? () {
                    // Navigate to player if owned
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => PlayerScreen(
                          bookId: book.id,
                          title: book.title,
                          author: book.author,
                          coverUrl: book.coverUrl,
                          audioUrl: book.audioUrl,
                          isOwned: true,
                        )));
                  }
                : null,
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Icon(Icons.headset, size: 48, color: owned ? Colors.green : Colors.grey),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(book.title,
                        style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(book.author, style: const TextStyle(color: Colors.black54)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: owned
                            ? null
                            : () async {
                                await libraryStore.addBook(book.id);
                                // Optionally show confirmation here.
                              },
                        child: Text(owned ? 'Owned' : 'Buy'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: owned ? Colors.grey : Colors.blue),
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
