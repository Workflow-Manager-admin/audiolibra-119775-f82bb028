import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// GLOBAL library state - just stores owned book IDs.
class LibraryStore extends ChangeNotifier {
  static const String _ownedBooksKey = 'owned_books';

  Set<String> _ownedBookIds = {};

  Future<void> loadLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    _ownedBookIds = prefs.getStringList(_ownedBooksKey)?.toSet() ?? {};
    notifyListeners();
  }

  bool isOwned(String bookId) {
    return _ownedBookIds.contains(bookId);
  }

  Future<void> addBook(String bookId) async {
    if (!_ownedBookIds.contains(bookId)) {
      final prefs = await SharedPreferences.getInstance();
      _ownedBookIds.add(bookId);
      await prefs.setStringList(_ownedBooksKey, _ownedBookIds.toList());
      notifyListeners();
    }
  }

  Set<String> get ownedBooks => _ownedBookIds;

  Future<void> clearLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    _ownedBookIds.clear();
    await prefs.remove(_ownedBooksKey);
    notifyListeners();
  }
}
