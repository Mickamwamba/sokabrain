import 'package:flutter_test/flutter_test.dart';
import 'package:sokabrain_mobile/main.dart';

void main() {
  testWidgets('SokaBrain app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SokaBrainApp());
    expect(find.text('SOKA'), findsOneWidget);
    expect(find.text('BRAIN'), findsOneWidget);
  });
}
