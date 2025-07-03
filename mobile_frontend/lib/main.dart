import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() {
  runApp(AudiolibraApp());
}

// --- MODEL CLASSES ---

/// Represents an Audiobook with relevant details
class Audiobook {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final String audioUrl;
  final String description;
  final double price;

  Audiobook({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.audioUrl,
    required this.description,
    required this.price,
  });
}

// --- MOCK DATA ---

List<Audiobook> allAudiobooks = [
  Audiobook(
    id: '1',
    title: 'The Art Of War',
    author: 'Sun Tzu',
    coverUrl: 'https://covers.openlibrary.org/b/id/7222361-L.jpg',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    description: 'An ancient Chinese military treatise on strategy, tactics and philosophy.',
    price: 11.99,
  ),
  Audiobook(
    id: '2',
    title: 'Pride And Prejudice',
    author: 'Jane Austen',
    coverUrl: 'https://covers.openlibrary.org/b/id/8091016-L.jpg',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    description: 'A classic novel about love, social standing, and misunderstanding.',
    price: 9.99,
  ),
  Audiobook(
    id: '3',
    title: 'Moby Dick',
    author: 'Herman Melville',
    coverUrl: 'https://covers.openlibrary.org/b/id/7222246-L.jpg',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    description: 'A whaling voyage turns into an epic pursuit—and a meditation on obsession.',
    price: 12.49,
  ),
  // Add more if desired...
];

// --- THEME COLORS ---
// Colors: primary: #1E88E5, secondary: #43A047, accent: #FBC02D
const kPrimaryColor = Color(0xFF1E88E5);
const kSecondaryColor = Color(0xFF43A047);
const kAccentColor = Color(0xFFFBC02D);

ThemeData getAppTheme() {
  return ThemeData(
    brightness: Brightness.light,
    primaryColor: kPrimaryColor,
    colorScheme: ColorScheme.light(
      primary: kPrimaryColor,
      secondary: kSecondaryColor,
      // Use 'surface' instead of deprecated 'background'
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
    ),
    scaffoldBackgroundColor: Colors.white,
    // accentColor deprecated: replace usages with colorScheme.secondary or other colors directly
    appBarTheme: AppBarTheme(backgroundColor: kPrimaryColor, foregroundColor: Colors.white),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kAccentColor, foregroundColor: Colors.black87
    ),
    tabBarTheme: const TabBarTheme(labelColor: kPrimaryColor, unselectedLabelColor: Colors.black54),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    fontFamily: 'Roboto',
  );
}

// --- LOCAL STORAGE KEYS ---

const _libraryPrefsKey = "owned_audiobook_ids";
const _playbackPrefsPrefix = "playback_position_";

// --- IN-MEMORY STATE (FOR DEMO PURPOSES) ---

class AppState extends ChangeNotifier {
  // User's library (purchased audiobooks' IDs)
  Set<String> libraryIds = {};
  // Playback positions (audiobookId -> position in seconds)
  Map<String, double> playbackPositions = {};

  // --- Store/load library from storage ---
  Future<void> loadLibrary() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    libraryIds = prefs.getStringList(_libraryPrefsKey)?.toSet() ?? {};
    notifyListeners();
  }

  Future<void> addToLibrary(String audiobookId) async {
    libraryIds.add(audiobookId);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList(_libraryPrefsKey, libraryIds.toList());
    notifyListeners();
  }

  bool isInLibrary(String audiobookId) {
    return libraryIds.contains(audiobookId);
  }

  // --- Playback position (per audiobook), persisted ---
  Future<void> loadPlaybackPositions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, double> loaded = {};
    for (final book in allAudiobooks) {
      double pos = prefs.getDouble(_playbackPrefsPrefix + book.id) ?? 0.0;
      loaded[book.id] = pos;
    }
    playbackPositions = loaded;
    notifyListeners();
  }

  double getPlaybackPosition(String audiobookId) {
    return playbackPositions[audiobookId] ?? 0.0;
  }

  Future<void> savePlaybackPosition(String audiobookId, double position) async {
    playbackPositions[audiobookId] = position;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_playbackPrefsPrefix + audiobookId, position);
    notifyListeners();
  }
}

// --- ROOT APP WIDGET ---

class AudiolibraApp extends StatelessWidget {
  AudiolibraApp({super.key});

  final AppState appState = AppState();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audiolibra',
      debugShowCheckedModeBanner: false,
      theme: getAppTheme(),
      home: AppStateProvider(
        appState: appState,
        child: const AppEntry(),
      ),
    );
  }
}

// --- INHERITED WIDGET FOR STATE (to avoid heavy global state packages) ---

/// PUBLIC_INTERFACE
class AppStateProvider extends InheritedWidget {
  final AppState appState;

  const AppStateProvider({super.key, required this.appState, required super.child});

  static AppState of(BuildContext context) {
    final AppStateProvider? provider =
        context.dependOnInheritedWidgetOfExactType<AppStateProvider>();
    if (provider == null) {
      throw FlutterError("AppStateProvider not found in context");
    }
    return provider.appState;
  }

  @override
  bool updateShouldNotify(AppStateProvider oldWidget) => true;
}

// --- MAIN NAVIGATION ENTRY (Store & Library tabs) ---

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});
  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  int _selectedIndex = 0;

  late Future<void> loadStateFuture;

  @override
  void initState() {
    super.initState();
    final appState = AppStateProvider.of(context);
    loadStateFuture = Future.wait([
      appState.loadLibrary(),
      appState.loadPlaybackPositions()
    ]);
  }

  void _onTabChanged(int idx) {
    setState(() {
      _selectedIndex = idx;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: loadStateFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(_selectedIndex == 0 ? "Store" : "My Library"),
            actions: [
              // Optionally: profile icon or settings
            ],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              StoreScreen(),
              LibraryScreen(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onTabChanged,
            selectedItemColor: kPrimaryColor,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.store),
                label: "Store",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_books),
                label: "Library",
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- STORE SCREEN ---

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        itemCount: allAudiobooks.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.68,
        ),
        itemBuilder: (context, idx) {
          final book = allAudiobooks[idx];
          return AudiobookCard(
            book: book,
            owned: appState.isInLibrary(book.id),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DetailScreen(audiobook: book),
                  fullscreenDialog: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Grid/list item for an Audiobook, showing the cover, title, author, and price or "Owned"
class AudiobookCard extends StatelessWidget {
  final Audiobook book;
  final bool owned;
  final void Function()? onTap;

  const AudiobookCard({super.key, required this.book, required this.owned, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 132,
                width: double.infinity,
                child: Image.network(
                  book.coverUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: Center(child: Icon(Icons.audiotrack, size: 40, color: kSecondaryColor)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(book.author,
                      style: TextStyle(fontSize: 13, color: kSecondaryColor, fontWeight: FontWeight.w500)),
                  SizedBox(height: 6),
                  owned
                      ? Text('Owned',
                          style: TextStyle(
                              color: kAccentColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('\$${book.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                            Icon(Icons.info_outline, color: Colors.grey, size: 18)
                          ],
                        )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- DETAIL SCREEN ---

class DetailScreen extends StatelessWidget {
  final Audiobook audiobook;

  const DetailScreen({super.key, required this.audiobook});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    bool owned = appState.isInLibrary(audiobook.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(audiobook.title),
        backgroundColor: kPrimaryColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                audiobook.coverUrl,
                width: 154,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 154,
                  height: 220,
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(Icons.audiotrack, size: 60, color: kSecondaryColor),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            audiobook.title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            "by ${audiobook.author}",
            style: const TextStyle(
                color: kSecondaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 14),
          Text(audiobook.description),
          const SizedBox(height: 24),
          owned
              ? ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => PlayerScreen(audiobook: audiobook)));
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Listen Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentColor,
                    foregroundColor: Colors.black,
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: () async {
                    await appState.addToLibrary(audiobook.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Purchased! Added to your Library.")));
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: Text(
                      'Buy  •  \$${audiobook.price.toStringAsFixed(2)}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            label: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// --- LIBRARY SCREEN ---

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);

    final List<Audiobook> libraryBooks = allAudiobooks
        .where((book) => appState.isInLibrary(book.id))
        .toList();

    if (libraryBooks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books, color: kSecondaryColor, size: 48),
            SizedBox(height: 12),
            Text("Your library is empty.\nPurchase audiobooks from the Store.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: libraryBooks.length,
      separatorBuilder: (_, __) => Divider(),
      itemBuilder: (context, idx) {
        final book = libraryBooks[idx];
        return ListTile(
          leading: Image.network(
            book.coverUrl,
            width: 48, height: 65, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 48, height: 65,
              color: Colors.grey[200],
              child: Icon(Icons.audiotrack, color: kSecondaryColor)
            ),
          ),
          title: Text(book.title, style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(book.author),
          trailing: IconButton(
            icon: Icon(Icons.play_arrow, color: kAccentColor),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PlayerScreen(audiobook: book)
              ));
            },
          ),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PlayerScreen(audiobook: book)
            ));
          },
        );
      },
    );
  }
}

// --- PLAYER SCREEN (with controls, seekbar, and persistence) ---

class PlayerScreen extends StatefulWidget {
  final Audiobook audiobook;

  const PlayerScreen({super.key, required this.audiobook});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  // For demo: Simulated audio playback (Duration set to 1200s = 20 min)
  static const double _mockAudioDuration = 1200.0;

  bool _isPlaying = false;
  double _currentPosition = 0.0;
  late Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Load persisted playback position for this audiobook
    final appState = AppStateProvider.of(context);
    _currentPosition = appState.getPlaybackPosition(widget.audiobook.id);

    // Pretend to stream audio -- not using real audio for demo
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePlayPause() async {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    if (_isPlaying) {
      _startTimer();
    } else {
      _timer?.cancel();
      // Save position
      await _savePlaybackPosition();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: 500), (timer) async {
      setState(() {
        _currentPosition += 0.5;
        if (_currentPosition >= _mockAudioDuration) {
          _currentPosition = _mockAudioDuration;
          _isPlaying = false;
          _timer?.cancel();
        }
      });
      await _savePlaybackPosition();
    });
  }

  Future<void> _savePlaybackPosition() async {
    final appState = AppStateProvider.of(context);
    await appState.savePlaybackPosition(widget.audiobook.id, _currentPosition);
  }

  void _seekTo(double newPos) {
    setState(() {
      _currentPosition = newPos.clamp(0.0, _mockAudioDuration);
    });
    _savePlaybackPosition();
  }

  void _skipForward() {
    double newPos = (_currentPosition + 30.0).clamp(0.0, _mockAudioDuration);
    _seekTo(newPos);
  }

  void _skipBackward() {
    double newPos = (_currentPosition - 15.0).clamp(0.0, _mockAudioDuration);
    _seekTo(newPos);
  }

  String _formatTime(double seconds) {
    int min = seconds ~/ 60;
    int sec = (seconds % 60).toInt();
    return "$min:${sec.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final audiobook = widget.audiobook;

    return Scaffold(
      appBar: AppBar(
        title: Text('Playing'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 18),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  audiobook.coverUrl,
                  width: 148, height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 148, height: 200,
                    color: Colors.grey[300],
                    child: Icon(Icons.audiotrack, size: 52, color: kSecondaryColor),
                  ),
                ),
              ),
            ),
            SizedBox(height: 18),
            Text(audiobook.title, style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
            Text("by ${audiobook.author}", style: TextStyle(color: kSecondaryColor, fontWeight: FontWeight.w500)),
            SizedBox(height: 18),
            // Seek bar
            Column(
              children: [
                Slider(
                  value: _currentPosition,
                  min: 0.0,
                  max: _mockAudioDuration,
                  onChanged: (double value) {
                    _seekTo(value);
                  },
                  activeColor: kPrimaryColor,
                  inactiveColor: kPrimaryColor.withAlpha((0.3*255).toInt()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatTime(_currentPosition), style: TextStyle(color: Colors.black87)),
                    Text(_formatTime(_mockAudioDuration), style: TextStyle(color: Colors.black45)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            // Controls: skip back, play/pause, skip forward
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.replay_10),
                  iconSize: 35,
                  color: kAccentColor,
                  onPressed: _skipBackward,
                  tooltip: 'Back 15s',
                ),
                SizedBox(width: 26),
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: kPrimaryColor,
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white, size: 40,
                    ),
                  ),
                ),
                SizedBox(width: 26),
                IconButton(
                  icon: Icon(Icons.forward_30),
                  iconSize: 35,
                  color: kAccentColor,
                  onPressed: _skipForward,
                  tooltip: 'Fwd 30s',
                ),
              ],
            ),
            SizedBox(height: 18),
            Text(
              _isPlaying ? "Playing..." : "Paused",
              style: TextStyle(fontSize: 15, color: kPrimaryColor, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 28),
            Text("Last position is automatically saved.",
              style: TextStyle(fontSize: 12, color: Colors.black54),
            )
          ],
        ),
      ),
    );
  }
}

