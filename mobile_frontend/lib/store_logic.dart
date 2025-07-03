import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Logic for handling book purchases, library state, and persistent storage.
class StoreLibraryModel extends ChangeNotifier {
  static const _libraryKey = 'purchased_books';

  /// Set of bookIds the user has purchased.
  Set<String> _purchasedBooks = {};

  static StoreLibraryModel? _instance;
  StoreLibraryModel._();
  static Future<StoreLibraryModel> getInstance() async {
    if (_instance == null) {
      _instance = StoreLibraryModel._();
      await _instance!._load();
    }
    return _instance!;
  }

  /// Loads purchased book IDs from persistent storage.
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_libraryKey);
    if (ids != null) {
      _purchasedBooks = ids.toSet();
    }
    notifyListeners();
  }

  // PUBLIC_INTERFACE
  /// Returns true if book is owned/purchased.
  bool ownsBook(String bookId) => _purchasedBooks.contains(bookId);

  // PUBLIC_INTERFACE
  /// Adds a book ID to the library (purchases it), persists, and notifies listeners.
  Future<void> purchaseBook(String bookId) async {
    if (_purchasedBooks.contains(bookId)) return;
    _purchasedBooks.add(bookId);
    await _save();
    notifyListeners();
  }

  // PUBLIC_INTERFACE
  /// Returns a copy of the user's purchased book IDs.
  Set<String> get libraryBookIds => Set<String>.from(_purchasedBooks);

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_libraryKey, _purchasedBooks.toList());
  }

  Future<void> clearLibrary() async {
    _purchasedBooks.clear();
    await _save();
    notifyListeners();
  }
}
