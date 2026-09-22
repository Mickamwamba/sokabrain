import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sokabrain_mobile/main.dart';

class _TestHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  testWidgets('SokaBrain app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SokaBrainApp());
    expect(find.text('SOKA'), findsOneWidget);
    expect(find.text('BRAIN'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });
}
