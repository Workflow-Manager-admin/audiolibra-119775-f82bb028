import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// -- Data Model for Audiobook --
class Audiobook {
  final String id;
  final String coverUrl;
  final String title;
  final String author;
  final String description;
  final double price;

  Audiobook({
    required this.id,
    required this.coverUrl,
    required this.title,
    required this.author,
    required this.description,
    required this.price,
  });
}

// -- Sample Audiobook Data --
final List<Audiobook> sampleAudiobooks = [
  Audiobook(
    id: '1',
    coverUrl: 'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=500',
    title: 'The Flutter Journey',
    author: 'Jane Dev',
    description: 'Embark on a comprehensive journey through building stunning apps with Flutter, covering widgets, state, navigation, and more.',
    price: 14.99,
  ),
  Audiobook(
    id: '2',
    coverUrl: 'https://images.unsplash.com/photo-1507842217343-583bb7270b66?w=500',
    title: 'Soundscapes: Volume I',
    author: 'Max Harmony',
    description: 'Relax and unwind with beautiful soundscapes and the story behind each track, narrated by Max Harmony.',
    price: 9.99,
  ),
  Audiobook(
    id: '3',
    coverUrl: 'https://images.unsplash.com/photo-1465101046530-73398c7f28ca?w=500',
    title: 'Mystery by Moonlight',
    author: 'Luna Night',
    description: 'A thrilling whodunit unfolds beneath the moonlight. Can you solve the puzzle before the last track?',
    price: 11.49,
  ),
  Audiobook(
    id: '4',
    coverUrl: 'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=500',
    title: 'Code: The Untold Story',
    author: 'Alex Syntax',
    description: 'A fascinating narrative about the evolution of coding, intertwined with personal stories from developers around the globe.',
    price: 16.99,
  ),
  Audiobook(
    id: '5',
    coverUrl: 'https://images.unsplash.com/photo-1503676382389-4809596d5290?w=500',
    title: 'Voices of the Wild',
    author: 'Sam Forest',
    description: 'Adventure deep into the world\'s jungles and deserts with mesmerizing animal tales and sounds.',
    price: 12.49,
  ),
];

// -- Persistent Purchase Store --
class PurchaseStorage with ChangeNotifier {
  static const String _prefsKey = 'purchased_audiobooks';
  Set<String> _purchasedIds = {};

  Set<String> get purchasedIds => _purchasedIds;

  PurchaseStorage() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_prefsKey) ?? [];
    _purchasedIds = Set<String>.from(ids);
    notifyListeners();
  }

  Future<void> purchase(String audiobookId) async {
    if (_purchasedIds.contains(audiobookId)) return;
    _purchasedIds.add(audiobookId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _purchasedIds.toList());
    notifyListeners();
  }

  bool isPurchased(String audiobookId) => _purchasedIds.contains(audiobookId);
}

// -- Main App --
void main() {
  runApp(const AudiolibraApp());
}

// PUBLIC_INTERFACE
class AudiolibraApp extends StatelessWidget {
  const AudiolibraApp({super.key});

  // PUBLIC_INTERFACE
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audiolibra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: Color(0xFF1E88E5),
          secondary: Color(0xFF43A047),
        ),
        appBarTheme: AppBarTheme(
          color: Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          elevation: 1,
        ),
        cardTheme: CardTheme(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        useMaterial3: true,
      ),
      home: StoreScreen(),
    );
  }
}

// PUBLIC_INTERFACE
class StoreScreen extends StatefulWidget {
  // The grid view of audiobooks (Store).
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  late PurchaseStorage purchaseStorage;

  @override
  void initState() {
    super.initState();
    purchaseStorage = PurchaseStorage();
    purchaseStorage.addListener(_onPurchaseChanged);
  }

  @override
  void dispose() {
    purchaseStorage.removeListener(_onPurchaseChanged);
    super.dispose();
  }

  void _onPurchaseChanged() {
    setState(() {});
  }

  void _openDetailsModal(BuildContext modalContext, Audiobook book) {
    showModalBottomSheet(
      context: modalContext,
      isScrollControlled: true,
      showDragHandle: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.93,
        child: AudiobookDetailModal(
          audiobook: book,
          isPurchased: purchaseStorage.isPurchased(book.id),
          onBuy: () {
            // Close the modal immediately before performing async operation to avoid context crossing
            if (Navigator.of(ctx).canPop()) {
              Navigator.of(ctx).pop();
            }
            purchaseStorage.purchase(book.id);
          },
        ),
      ),
    );
  }

  // PUBLIC_INTERFACE
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audiolibra Store', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        actions: [
          IconButton(
            icon: Icon(Icons.library_books, color: Theme.of(context).colorScheme.secondary),
            tooltip: 'Go to Library (to be implemented)',
            onPressed: () {}, // Navigation to Library screen (future work)
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF4F9FD),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: GridView.builder(
            itemCount: sampleAudiobooks.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 18,
              crossAxisSpacing: 14,
              childAspectRatio: 0.67,
            ),
            itemBuilder: (context, i) {
              final book = sampleAudiobooks[i];
              final purchased = purchaseStorage.isPurchased(book.id);

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _openDetailsModal(context, book),
                child: Card(
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          book.coverUrl,
                          height: 135,
                          width: 105,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            color: Colors.grey[200], height: 135, width: 105,
                            child: Icon(Icons.book, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        child: Text(
                          book.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blueGrey[900],
                              fontSize: 15
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        child: Text(
                          book.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w400,
                              color: Colors.blueGrey[600],
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                        decoration: BoxDecoration(
                          color: purchased
                              ? const Color.fromRGBO(67, 160, 71, 0.10)
                              : const Color.fromRGBO(30, 136, 229, 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              purchased ? Icons.check_circle_rounded : Icons.attach_money_rounded,
                              color: purchased ? Color(0xFF43A047) : Color(0xFF1E88E5),
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              purchased ? "Purchased" : book.price.toStringAsFixed(2),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: purchased ? Color(0xFF43A047) : Color(0xFF1E88E5),
                              ),
                            ),
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
      ),
    );
  }
}

// PUBLIC_INTERFACE
class AudiobookDetailModal extends StatelessWidget {
  // Modal displaying the details for an audiobook and handling purchase.
  final Audiobook audiobook;
  final bool isPurchased;
  final VoidCallback onBuy;

  const AudiobookDetailModal({
    super.key,
    required this.audiobook,
    required this.isPurchased,
    required this.onBuy,
  });

  // PUBLIC_INTERFACE
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            height: 6,
            width: 46,
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 7),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.network(
                        audiobook.coverUrl,
                        height: 180,
                        width: 135,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          color: Colors.grey[200], height: 180, width: 135,
                          child: Icon(Icons.book, color: Colors.grey, size: 54),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      audiobook.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.blueGrey[900],
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "by ${audiobook.author}",
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      audiobook.description,
                      style: TextStyle(
                        color: Colors.blueGrey[800],
                        fontSize: 15.5,
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPurchased
                              ? Colors.grey[300]
                              : theme.colorScheme.primary,
                          foregroundColor: isPurchased
                              ? Colors.grey[600]
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 1.5,
                        ),
                        icon: Icon(
                          isPurchased ? Icons.check_circle_outline : Icons.shopping_cart,
                          size: 24,
                        ),
                        label: Text(
                          isPurchased
                              ? "Purchased"
                              : "Buy for \$${audiobook.price.toStringAsFixed(2)}",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        onPressed: isPurchased ? null : onBuy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
