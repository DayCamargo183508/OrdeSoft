import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('App starts smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const OrderSoftApp());
    expect(find.byType(OrderSoftApp), findsOneWidget);
  });
}
