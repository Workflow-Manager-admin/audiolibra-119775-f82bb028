import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(AudiolibraApp());
}

/// Root widget for the Audiolibra app with material theme and home set to StoreScreen.
// PUBLIC_INTERFACE
class AudiolibraApp extends StatelessWidget {
  const AudiolibraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audiolibra',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: Color(0xFF1E88E5),
          secondary: Color(0xFF43A047),
        ),
        useMaterial3: true,
      ),
      home: AudiolibraHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Model for Audiobook
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

// Sample data
final List<Audiobook> sampleAudiobooks = [
  Audiobook(
      id: '1',
      title: 'The Alchemist',
      author: 'Paulo Coelho',
      coverUrl: 'https://covers.openlibrary.org/b/id/8885024-L.jpg',
      price: 9.99,
      description: 'An allegorical novel that follows a young Andalusian shepherd on a journey to the Egyptian pyramids.',
      audioUrl: 'https://samplelib.com/mp3/sample-3s.mp3'),
  Audiobook(
      id: '2',
      title: '1984',
      author: 'George Orwell',
      coverUrl: 'https://covers.openlibrary.org/b/id/153541-L.jpg',
      price: 7.49,
      description: 'A dystopian tale about the perils of totalitarianism and government surveillance.',
      audioUrl: 'https://samplelib.com/mp3/sample-6s.mp3'),
  Audiobook(
      id: '3',
      title: 'To Kill a Mockingbird',
      author: 'Harper Lee',
      coverUrl: 'https://covers.openlibrary.org/b/id/10958323-L.jpg',
      price: 8.99,
      description: 'A classic exploration of racial injustice and childhood innocence in the Deep South.',
      audioUrl: 'https://samplelib.com/mp3/sample-9s.mp3'),
  Audiobook(
      id: '4',
      title: 'Atomic Habits',
      author: 'James Clear',
      coverUrl: 'https://covers.openlibrary.org/b/id/9350211-L.jpg',
      price: 11.99,
      description: 'A step-by-step guide to building good habits and breaking bad ones.',
      audioUrl: 'https://samplelib.com/mp3/sample-15s.mp3'),
  Audiobook(
      id: '5',
      title: 'Project Hail Mary',
      author: 'Andy Weir',
      coverUrl: 'https://covers.openlibrary.org/b/id/10582604-L.jpg',
      price: 12.49,
      description: 'A gripping tale of a man who wakes up alone on a spaceship with no memory of who he is.',
      audioUrl: 'https://samplelib.com/mp3/sample-12s.mp3'),
  Audiobook(
      id: '6',
      title: 'Educated',
      author: 'Tara Westover',
      coverUrl: 'https://covers.openlibrary.org/b/id/9270136-L.jpg',
      price: 8.79,
      description: 'A memoir about a young girl who, kept out of school, leaves her survivalist family and earns a PhD.',
      audioUrl: 'https://samplelib.com/mp3/sample-6s.mp3'),
];

// Handles persistent library (purchased audiobooks) with SharedPreferences
class LibraryManager {
  static const _purchasedKey = 'purchased_books';

  /// Loads the list of purchased audiobook IDs from local storage.
  // PUBLIC_INTERFACE
  static Future<Set<String>> loadPurchased() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_purchasedKey);
    if (jsonString == null) return {};
    final List<dynamic> raw = json.decode(jsonString);
    return raw.map((e) => e as String).toSet();
  }

  /// Stores the list of purchased audiobook IDs.
  // PUBLIC_INTERFACE
  static Future<void> savePurchased(Set<String> purchased) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(purchased.toList());
    await prefs.setString(_purchasedKey, jsonString);
  }
}

// Entry with Store and Library tabs
class AudiolibraHome extends StatefulWidget {
  @override
  State<AudiolibraHome> createState() => _AudiolibraHomeState();
}

class _AudiolibraHomeState extends State<AudiolibraHome> {
  int _selectedTab = 0;
  Set<String> _purchased = {};

  @override
  void initState() {
    super.initState();
    _loadPurchased();
  }

  void _loadPurchased() async {
    final library = await LibraryManager.loadPurchased();
    setState(() {
      _purchased = library;
    });
  }

  void _purchaseBook(String id) {
    setState(() {
      _purchased.add(id);
      LibraryManager.savePurchased(_purchased);
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added to your library!')));
  }

  void _goToDetail(Audiobook book) async {
    final purchased = _purchased;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (ctx) => AudiobookDetailScreen(
              book: book,
              purchased: purchased.contains(book.id),
              onPurchase: () => _purchaseBook(book.id),
          )),
    );
    if (result == 'purchased') {
      _loadPurchased(); // refresh after purchase
    }
  }

  Widget _buildStore() {
    return StoreScreen(
      audiobooks: sampleAudiobooks,
      purchased: _purchased,
      onDetail: _goToDetail,
      onPurchase: _purchaseBook,
    );
  }

  Widget _buildLibrary() {
    final owned = sampleAudiobooks.where((b) => _purchased.contains(b.id)).toList();
    return LibraryScreen(audiobooks: owned);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedTab == 0 ? _buildStore() : _buildLibrary(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (idx) => setState(() => _selectedTab = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.store), label: "Store"),
          NavigationDestination(icon: Icon(Icons.library_books), label: "Library"),
        ],
      ),
    );
  }
}

/// StoreScreen displays a grid of audiobooks for sale. Purchases update the library persistently.
/// StoreScreen displays a grid of audiobooks for sale. Purchases update the library persistently.
// PUBLIC_INTERFACE
class StoreScreen extends StatelessWidget {
  final List<Audiobook> audiobooks;
  final Set<String> purchased;
  final void Function(Audiobook book) onDetail;
  final void Function(String id) onPurchase;

  const StoreScreen({
    super.key,
    required this.audiobooks,
    required this.purchased,
    required this.onDetail,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.secondary;
    return Scaffold(
      appBar: AppBar(
        title: Text('Audiolibra Store'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: audiobooks.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 3,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.65,
          ),
          itemBuilder: (ctx, idx) {
            final book = audiobooks[idx];
            final isOwned = purchased.contains(book.id);
            return GestureDetector(
              onTap: () => onDetail(book),
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(
                            book.coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_,__,___) => Container(
                                color: Colors.grey.shade200,
                                child: Icon(Icons.image_not_supported)),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(book.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(book.author,
                                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                            SizedBox(height: 6),
                            Text(isOwned ? "Purchased" : '\$${book.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: isOwned ? accent : Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// AudiobookDetailScreen shows details for a book, with a purchase button or owned state.
// PUBLIC_INTERFACE
class AudiobookDetailScreen extends StatelessWidget {
  final Audiobook book;
  final bool purchased;
  final VoidCallback onPurchase;

  const AudiobookDetailScreen({
    super.key,
    required this.book,
    required this.purchased,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.secondary;
    return Scaffold(
      appBar: AppBar(
        title: Text(book.title,
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: ListView(
        padding: EdgeInsets.all(18),
        children: [
          AspectRatio(
            aspectRatio: 2.6 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                book.coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_,__,___) => Container(
                    color: Colors.grey.shade200,
                    child: Icon(Icons.image_not_supported)),
              ),
            ),
          ),
          SizedBox(height: 18),
          Text(book.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21)),
          Text(book.author, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
          SizedBox(height: 16),
          Text(book.description, style: TextStyle(fontSize: 15)),
          SizedBox(height: 28),
          purchased
              ? ElevatedButton.icon(
                  onPressed: null,
                  icon: Icon(Icons.check, color: accent),
                  label: Text('Already in Library', style: TextStyle(color: accent)),
                  style: ElevatedButton.styleFrom(
                      foregroundColor: accent,
                      backgroundColor: Colors.grey[200],
                      disabledBackgroundColor: Colors.grey[200]),
                )
              : ElevatedButton.icon(
                  onPressed: () {
                    onPurchase();
                    Navigator.pop(context, 'purchased');
                  },
                  icon: Icon(Icons.shopping_cart_checkout),
                  label: Text('Purchase \$${book.price.toStringAsFixed(2)}'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary),
                ),
        ],
      ),
    );
  }
}

/// LibraryScreen shows a list of purchased audiobooks.
// PUBLIC_INTERFACE
class LibraryScreen extends StatelessWidget {
  final List<Audiobook> audiobooks;
  const LibraryScreen({super.key, required this.audiobooks});

  @override
  Widget build(BuildContext context) {
    if (audiobooks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(36.0),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.library_books_outlined, size: 52, color: Colors.grey),
                SizedBox(height: 22),
                Text("Your library is empty!",
                    style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                SizedBox(height: 12),
                Text("Purchase books from the Store.",
                    style: TextStyle(fontSize: 15, color: Colors.grey[500]))
              ]),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Library'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      backgroundColor: Colors.grey[100],
      body: ListView.separated(
        itemCount: audiobooks.length,
        separatorBuilder: (c, i) => Divider(height: 0, indent: 96, endIndent: 20),
        itemBuilder: (ctx, idx) {
          final book = audiobooks[idx];
          return ListTile(
            contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 18),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.network(
                book.coverUrl,
                height: 60,
                width: 48,
                fit: BoxFit.cover,
                errorBuilder: (_,__,___) => Container(
                    color: Colors.grey.shade200,
                    child: Icon(Icons.image_not_supported)),
              ),
            ),
            title: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(book.author),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 18),
            onTap: () {
              Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (ctx) => AudiobookDetailScreen(
                        book: book,
                        purchased: true,
                        onPurchase: () {},
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
