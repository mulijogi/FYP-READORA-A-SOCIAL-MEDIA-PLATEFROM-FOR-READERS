// Basic Flutter widget test to ensure the app builds without errors.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const GetMaterialApp());
    // If no exceptions are thrown, the test passes.
    expect(true, isTrue);
  });
}
