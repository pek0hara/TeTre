import 'package:flutter_test/flutter_test.dart';
import 'package:tetre/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TetreApp());
    
    // 単純な起動確認のみ
    expect(find.text('TeTre Trainer'), findsOneWidget);
  });
}