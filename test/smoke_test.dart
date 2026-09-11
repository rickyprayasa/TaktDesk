import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/features/opening/presentation/takt_opening_screen.dart';
import 'package:takt_desk/main.dart';

void main() {
  test('scaffold baseline smoke test', () {
    const appName = 'Takt Desk';
    expect(appName, equals('Takt Desk'));
  });

  testWidgets('TaktApp launches with TaktOpeningScreen as root widget', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TaktApp(),
      ),
    );

    expect(find.byType(TaktOpeningScreen), findsOneWidget);
  });
}

