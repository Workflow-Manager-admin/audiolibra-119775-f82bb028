import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/main.dart';

void main() {
  testWidgets('App boots and displays tab bar', (WidgetTester tester) async {
    await tester.pumpWidget(AudiolibraApp());

    // Should show Store and Library tabs
    expect(find.text('Store'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
  });
}
