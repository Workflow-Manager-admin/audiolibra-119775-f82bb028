import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'player_screen.dart';

// Model for an Audiobook
class Audiobook {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final String audioUrl;

  Audiobook({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.audioUrl,
  });

  // PUBLIC_INTERFACE
  factory Audiobook.fromMap(Map<String, dynamic> map) {
    return Audiobook(
      id: map['id'],
      title: map['title'],
      author: map['author'],
      coverUrl: map['coverUrl'],
      audioUrl: map['audioUrl'],
    );
  }

  // PUBLIC_INTERFACE
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'audioUrl': audioUrl,
    };
  }
}

/// Provides methods to get and set purchased audiobooks in persistent storage.
class LibraryStorage {
  static const _purchasedBooksKey = 'purchased_audiobooks';

  // PUBLIC_INTERFACE
  static Future<List<Audiobook>> getPurchasedAudiobooks() async {
    final prefs = await SharedPreferences.getInstance();
    final purchasedList = prefs.getStringList(_purchasedBooksKey) ?? [];
    // Each item is a JSON-encoded string map (simple encoding), adjust as needed.
    return purchasedList.map((bookStr) {
      try {
        final map = Map<String, dynamic>.from(Uri.splitQueryString(bookStr));
        return Audiobook.fromMap(map);
      } catch (_) {
        return null;
      }
    }).whereType<Audiobook>().toList();
  }

  // PUBLIC_INTERFACE
  static Future<void> savePurchasedAudiobooks(List<Audiobook> books) async {
    final prefs = await SharedPreferences.getInstance();
    final stringList = books.map((b) => b.toMap().toString()).toList();
    await prefs.setStringList(_purchasedBooksKey, stringList);
  }
}

/// The Library screen displaying user's purchased audiobooks with modern styling.
class LibraryScreen extends StatefulWidget {
  // PUBLIC_INTERFACE
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late Future<List<Audiobook>> _purchasedBooksFuture;

  @override
  void initState() {
    super.initState();
    _purchasedBooksFuture = LibraryStorage.getPurchasedAudiobooks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Library'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: FutureBuilder<List<Audiobook>>(
        future: _purchasedBooksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final books = snapshot.data ?? [];
          if (books.isEmpty) {
            return const Center(
              child: Text(
                'No purchased audiobooks yet.\nBrowse the Store to add to your library!',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            itemCount: books.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final book = books[idx];
              return _AudiobookCard(
                audiobook: book,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlayerScreen(
                        audioSource: book.audioUrl,
                        bookId: book.id,
                        title: book.title,
                        coverImage: book.coverUrl,
                        details: book.author,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _AudiobookCard extends StatelessWidget {
  final Audiobook audiobook;
  final VoidCallback? onTap;

  const _AudiobookCard({required this.audiobook, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      splashColor: theme.colorScheme.primary.withAlpha(25),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: audiobook.coverUrl.isNotEmpty
                  ? Image.network(
                      audiobook.coverUrl,
                      width: 70,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: theme.primaryColorLight,
                        width: 70,
                        height: 100,
                        child: const Icon(Icons.image_not_supported),
                      ),
                    )
                  : Container(
                      width: 70,
                      height: 100,
                      color: theme.primaryColorLight,
                      child: const Icon(Icons.image_not_supported),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      audiobook.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      audiobook.author,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
