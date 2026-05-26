import 'package:flutter_test/flutter_test.dart';
import 'package:chess_park/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ChessParkApp());
    expect(find.text('象棋乐园'), findsOneWidget);
  });
}
