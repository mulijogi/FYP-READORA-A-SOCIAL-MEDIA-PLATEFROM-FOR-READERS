import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:readora/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('App starts and shows expected initial UI',
        (WidgetTester tester) async {
      app.main();
      
      // Wait for the app to finish its initial animations/loading
      await tester.pumpAndSettle();

      // Example: We check if the app starts.
      // Depending on your initial screen, you might want to find a specific text or widget.
      // For instance, if your app shows "Readora" on the splash screen or login:
      // expect(find.text('Readora'), findsOneWidget);
      
      // Verify that there is at least a MaterialApp or Scaffold rendered.
      expect(find.byType(MaterialApp), findsWidgets);
    });
  });
}
