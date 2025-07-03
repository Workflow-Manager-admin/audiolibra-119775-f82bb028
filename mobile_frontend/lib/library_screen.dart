import 'package:flutter/material.dart';
import 'store_logic.dart';
import 'store_screen.dart'; // for Book class and dummy storeBooks

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
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
    final userBookIds = _model.libraryBookIds;
    final userBooks = storeBooks.where((b) => userBookIds.contains(b.id)).toList();
    if (userBooks.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Library')),
        body: const Center(child: Text("No books in your library yet.\nBuy books from the Store!")),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: ListView.builder(
        itemCount: userBooks.length,
        itemBuilder: (context, i) {
          final book = userBooks[i];
          return ListTile(
            leading: Icon(Icons.headphones),
            title: Text(book.title),
            subtitle: Text(book.author),
            // tap: can navigate to Player/Details if desired.
          );
        },
      ),
    );
  }
}
