import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'library_screen.dart';
import 'store_screen.dart';
import 'player_screen.dart';
import 'store_logic.dart';

// Provides colors and theming for the Audiolibra app.
class AppColors {
  static const primary = Color(0xFF1E88E5);
  static const secondary = Color(0xFF43A047);
  static const accent = Color(0xFFFBC02D);
  static const background = Color(0xFFF5F5F5);
  static const card = Colors.white;
  static const text = Colors.black87;
}

void main() {
  runApp(const AudiolibraApp());
}

/// The main root widget of the Audiolibra Flutter mobile app
class AudiolibraApp extends StatelessWidget {
  const AudiolibraApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final store = LibraryStore();
        store.loadLibrary();
        return store;
      },
      child: MaterialApp(
        title: 'Audiolibra',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: AppColors.primary,
          colorScheme: ColorScheme.fromSwatch().copyWith(
            secondary: AppColors.secondary,
          ),
          scaffoldBackgroundColor: AppColors.background,
          cardColor: AppColors.card,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          textTheme: const TextTheme(
            titleLarge: TextStyle(
              color: AppColors.text, 
              fontWeight: FontWeight.bold, 
              fontSize: 20
            ),
            bodyMedium: TextStyle(color: AppColors.text),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, 
              foregroundColor: Colors.white
            )
          ),
          useMaterial3: true,
        ),
        home: const MainTabsScreen(),
      ),
    );
  }
}

/// Main screen with tab navigation for Store and Library
class MainTabsScreen extends StatefulWidget {
  const MainTabsScreen({super.key});
  @override
  State<MainTabsScreen> createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends State<MainTabsScreen> {
  int _selectedIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget buildBody() {
    if (_selectedIndex == 0) {
      return StoreScreen();
    } else {
      return LibraryScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Audiolibra',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.black54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            label: 'Store',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_outlined),
            label: 'Library',
          ),
        ],
      ),
    );
  }
}
