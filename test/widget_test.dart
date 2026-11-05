import 'package:flutter_test/flutter_test.dart';
import 'package:lowland_coffee/main.dart';

void main() {
  testWidgets('App basic smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LowlandCoffeeApp());
    expect(find.byType(LowlandCoffeeApp), findsOneWidget);
  });
}
