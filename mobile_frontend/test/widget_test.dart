import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_frontend/main.dart';

void main() {
  testWidgets('App loads and displays correct initial tab', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AudiolibraApp());

    // Should find the Store tab content
    expect(find.textContaining('Store'), findsWidgets);

    // Switch to Library tab by tapping the BottomNavigationBar (second item)
    await tester.tap(find.byIcon(Icons.library_books_outlined));
    await tester.pumpAndSettle();
    expect(find.textContaining('Library'), findsWidgets);
  });
}
