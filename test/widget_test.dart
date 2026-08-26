import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_robo/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RadarApp());
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.byType(RadarApp), findsOneWidget);
  });
}
