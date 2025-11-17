import 'package:flutter_test/flutter_test.dart';
import 'package:the_whiskey_manuscript_app/main.dart';

void main() {
  testWidgets('Dashboard navigation switches between pages', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Raise a Glass'), findsOneWidget);
    expect(find.text('Profile & Cellar'), findsNothing);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Profile & Cellar'), findsOneWidget);
  });
}