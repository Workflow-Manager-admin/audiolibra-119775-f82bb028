import 'package:flutter/material.dart';

void main() {
  runApp(AudioLibraApp());
}

/// The entrypoint widget for the Audiobook Store & Player app.
/// Provides navigation between Store and Library screens, applying a modern light theme.
/// Stub routes for Detail and Player screens are also initialized for future integration.
// PUBLIC_INTERFACE
class AudioLibraApp extends StatelessWidget {
  /// This widget is the root of the application.
  const AudioLibraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Audiolibra",
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.light(
          primary: Color(0xFF1E88E5), // Store blue
          secondary: Color(0xFF43A047), // Library green
          tertiary: Color(0xFFFBC02D), // Accent yellow
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          elevation: 1,
        ),
        tabBarTheme: TabBarTheme(
          labelColor: Color(0xFF1E88E5),
          unselectedLabelColor: Colors.grey,
        ),
        useMaterial3: true,
      ),
      home: MainNavigationScaffold(),
      routes: {
        '/detail': (context) => DetailScreenPlaceholder(),
        '/player': (context) => PlayerScreenPlaceholder(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

/// The main navigation scaffold with persistent bottom navigation bar.
/// Switches between Store and Library screens.
class MainNavigationScaffold extends StatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _selectedIndex = 0;

  // List of screens: the order must match the navigation bar
  static final List<Widget> _screens = <Widget>[
    StoreScreenPlaceholder(),
    LibraryScreenPlaceholder(),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Store' : 'Library'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Store',
          ),
          NavigationDestination(
            icon: Icon(Icons.my_library_books_outlined),
            selectedIcon: Icon(Icons.my_library_books),
            label: 'Library',
          ),
        ],
      ),
    );
  }
}

/// Placeholder for the Store screen.
/// Replace this with the actual Store content later.
// PUBLIC_INTERFACE
class StoreScreenPlaceholder extends StatelessWidget {
  const StoreScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Store Screen\n(To be implemented)",
        style: Theme.of(context).textTheme.titleLarge,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Placeholder for the Library screen.
/// Replace this with the actual Library content later.
// PUBLIC_INTERFACE
class LibraryScreenPlaceholder extends StatelessWidget {
  const LibraryScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Library Screen\n(To be implemented)",
        style: Theme.of(context).textTheme.titleLarge,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Placeholder for a Detail screen route, for preview/expansion only.
// PUBLIC_INTERFACE
class DetailScreenPlaceholder extends StatelessWidget {
  const DetailScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Audiobook Detail"),
      ),
      body: Center(
        child: Text(
          "Detail Screen\n(Route only)",
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Placeholder for a Player screen route, for preview/expansion only.
// PUBLIC_INTERFACE
class PlayerScreenPlaceholder extends StatelessWidget {
  const PlayerScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Audiobook Player"),
      ),
      body: Center(
        child: Text(
          "Player Screen\n(Route only)",
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
