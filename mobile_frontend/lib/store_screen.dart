import 'package:flutter/material.dart';
import 'store_logic.dart';

/// Dummy book data structure - to be replaced with real data/model as needed.
class Book {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  Book({required this.id, required this.title, required this.author, required this.coverUrl});
}

/// Example static store book list.
final List<Book> storeBooks = [
  Book(id: '1', title: 'Famous Book', author: 'Author X', coverUrl: ''),
  Book(id: '2', title: 'Adventure Book', author: 'Author Y', coverUrl: ''),
  Book(id: '3', title: 'Mystery Novel', author: 'Author Z', coverUrl: ''),
];

/// Store Screen: displays available books and purchase state.
class StoreScreen extends StatefulWidget {
  const StoreScreen({Key? key}) : super(key: key);

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  late StoreLibraryModel _model;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    StoreLibraryModel.getInstance().then((m) {
      _model = m;
      _model.addListener(_onLibraryChanged);
      setState(() {
        _loading = false;
      });
    });
  }

  void _onLibraryChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    if (!_loading) {
      _model.removeListener(_onLibraryChanged);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Store')),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 10, mainAxisSpacing: 10,
        ),
        itemCount: storeBooks.length,
        itemBuilder: (context, i) {
          final book = storeBooks[i];
          final owned = _model.ownsBook(book.id);
          return Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Book cover placeholder.
                Container(
                  height: 120,
                  color: Colors.grey[200],
                  child: Icon(Icons.headphones, size: 48, color: Colors.grey[600]),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(book.author, style: const TextStyle(color: Colors.grey)),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: owned
                        ? null
                        : () async {
                            await _model.purchaseBook(book.id);
                          },
                    child: Text(owned ? "Purchased" : "Buy"),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
