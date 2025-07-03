import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(AudioLibraApp());
}

/// Main App widget for the Audiobook Store & Player.
class AudioLibraApp extends StatelessWidget {
  // PUBLIC_INTERFACE
  const AudioLibraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AudioLibra',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF1E88E5),
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF1E88E5),
          secondary: const Color(0xFF43A047),
          primaryContainer: const Color(0xFFFBC02D),
        ),
        useMaterial3: true,
      ),
      home: StoreScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Sample data class for Audiobooks.
class Audiobook {
  final String id;
  final String title;
  final String author;
  final double price;
  final String coverUrl;
  final String description;

  Audiobook({
    required this.id,
    required this.title,
    required this.author,
    required this.price,
    required this.coverUrl,
    required this.description,
  });
}

/// Example list of sample audiobooks.
final List<Audiobook> kSampleBooks = [
  Audiobook(
    id: 'a1',
    title: 'The Great Gatsby',
    author: 'F. Scott Fitzgerald',
    price: 12.99,
    coverUrl: 'https://covers.openlibrary.org/b/id/7884866-L.jpg',
    description: 'A literary classic about the roaring 1920s and the mysterious Jay Gatsby.',
  ),
  Audiobook(
    id: 'a2',
    title: '1984',
    author: 'George Orwell',
    price: 10.50,
    coverUrl: 'https://covers.openlibrary.org/b/id/7222246-L.jpg',
    description: 'Dystopian masterpiece warning about state surveillance and repression.',
  ),
  Audiobook(
    id: 'a3',
    title: 'To Kill a Mockingbird',
    author: 'Harper Lee',
    price: 11.25,
    coverUrl: 'https://covers.openlibrary.org/b/id/8228691-L.jpg',
    description: 'A powerful tale about childhood and racial injustice in the Deep South.',
  ),
  Audiobook(
    id: 'a4',
    title: 'Moby Dick',
    author: 'Herman Melville',
    price: 9.75,
    coverUrl: 'https://covers.openlibrary.org/b/id/5555116-L.jpg',
    description: 'A thrilling sea adventure in pursuit of the legendary white whale.',
  ),
  Audiobook(
    id: 'a5',
    title: 'Pride and Prejudice',
    author: 'Jane Austen',
    price: 8.99,
    coverUrl: 'https://covers.openlibrary.org/b/id/8091016-L.jpg',
    description: 'An enduring romance with biting social commentary and brilliant wit.',
  ),
  Audiobook(
    id: 'a6',
    title: 'The Hobbit',
    author: 'J.R.R. Tolkien',
    price: 13.49,
    coverUrl: 'https://covers.openlibrary.org/b/id/6979861-L.jpg',
    description: 'Fantasy adventure that sets the stage for The Lord of the Rings.',
  ),
];

/// Key for storing purchased IDs in SharedPreferences.
const String purchasedBooksKey = 'purchased_books';

/// A utility class for persistence of purchased books.
class PurchaseStore {
  /// Loads the list of purchased book ids.
  static Future<Set<String>> loadPurchased() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(purchasedBooksKey)?.toSet() ?? {};
  }

  /// Adds a purchased book id and persists it.
  static Future<void> purchase(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final purchased = prefs.getStringList(purchasedBooksKey)?.toSet() ?? {};
    purchased.add(id);
    await prefs.setStringList(purchasedBooksKey, purchased.toList());
  }
}

/// The StoreScreen displays a grid of audiobooks.
class StoreScreen extends StatefulWidget {
  // PUBLIC_INTERFACE
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  late Future<Set<String>> _purchasedFuture;
  Set<String> purchasedIds = {};

  @override
  void initState() {
    super.initState();
    _purchasedFuture = PurchaseStore.loadPurchased();
    _refreshPurchased();
  }

  Future<void> _refreshPurchased() async {
    final loaded = await PurchaseStore.loadPurchased();
    setState(() {
      purchasedIds = loaded;
    });
  }

  void _onTapBook(Audiobook book) async {
    final purchased = purchasedIds.contains(book.id);
    // Refactor: Hoist all build context use out of async gaps.
    Future<void> handleBuy() async {
      await PurchaseStore.purchase(book.id);
      await _refreshPurchased();
      if (!mounted) return;
      Navigator.of(context).pop();
      // Show snackbar after navigator pop and before entering new async gap
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchased "${book.title}"!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => BookDetailSheet(
        book: book,
        isPurchased: purchased,
        onBuy: purchased ? null : handleBuy,
      ),
    ).whenComplete(_refreshPurchased);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Set<String>>(
      future: _purchasedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            purchasedIds.isEmpty) {
          // Loading indicator for first load
          return Scaffold(
            appBar: AppBar(
              title: const Text('Audiobook Store'),
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          // Use state value `purchasedIds` for up-to-date purchases
          return Scaffold(
            appBar: AppBar(
              title: const Text('Audiobook Store'),
              backgroundColor: Theme.of(context).primaryColor,
            ),
            body: Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 columns for mobile grid
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.68,
                ),
                itemCount: kSampleBooks.length,
                itemBuilder: (context, index) {
                  final book = kSampleBooks[index];
                  final isPurchased = purchasedIds.contains(book.id);

                  return GestureDetector(
                    onTap: () => _onTapBook(book),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AspectRatio(
                            aspectRatio: 11 / 16,
                            child: ClipRRect(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                              child: Image.network(
                                book.coverUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey[200],
                                  child: Icon(Icons.image_not_supported,
                                      size: 48, color: Colors.grey[400]),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 8, 2),
                            child: Text(
                              book.title,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
                            child: Text(
                              book.author,
                              style: TextStyle(color: Colors.grey[700], fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Spacer(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 4, 8, 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isPurchased ? "Purchased" : "\$${book.price.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    color: isPurchased
                                        ? Theme.of(context).colorScheme.secondary
                                        : Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Icon(Icons.info_outline, size: 21, color: Colors.grey[600])
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            backgroundColor: Colors.grey[50],
          );
        }
      },
    );
  }
}

/// Book detail sheet shown when a book is tapped.
class BookDetailSheet extends StatelessWidget {
  final Audiobook book;
  final bool isPurchased;
  final VoidCallback? onBuy;

  // PUBLIC_INTERFACE
  const BookDetailSheet({
    super.key,
    required this.book,
    required this.isPurchased,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 6,
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          book.coverUrl,
                          height: 100,
                          width: 75,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[200],
                            width: 75,
                            height: 100,
                            child: Icon(Icons.image_not_supported,
                                size: 40, color: Colors.grey[400]),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 19),
                            ),
                            SizedBox(height: 7),
                            Text(
                              book.author,
                              style: TextStyle(
                                  fontSize: 15, color: Colors.grey[700]),
                            ),
                            SizedBox(height: 15),
                            Text(
                              isPurchased
                                  ? "Purchased"
                                  : "\$${book.price.toStringAsFixed(2)}",
                              style: TextStyle(
                                color: isPurchased
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Text(
                    book.description,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: isPurchased
                          ? Icon(Icons.check_circle, color: Colors.white)
                          : Icon(Icons.shopping_bag, color: Colors.white),
                      onPressed: isPurchased ? null : onBuy,
                      label: Text(
                        isPurchased ? 'Book Purchased' : 'Buy Now',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPurchased
                            ? Colors.grey
                            : Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
                        disabledBackgroundColor: Colors.grey[400],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
