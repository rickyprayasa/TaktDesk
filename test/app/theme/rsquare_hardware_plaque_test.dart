import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/widgets/rsquare_hardware_plaque.dart';

void main() {
  group('RsquareHardwarePlaque Tests', () {
    testWidgets('renders RSQUARE logo image asset inside plaque', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: RsquareHardwarePlaque(size: 40),
            ),
          ),
        ),
      );

      expect(find.byType(RsquareHardwarePlaque), findsOneWidget);
      final logoFinder = find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == 'assets/images/rsquare_logo.png',
      );
      expect(logoFinder, findsOneWidget);
    });

    testWidgets('renders micro-rivets when size is 40 and showRivets is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: RsquareHardwarePlaque(
                size: 40,
                showRivets: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('rsquare_plaque_rivet_tl')), findsOneWidget);
      expect(find.byKey(const ValueKey('rsquare_plaque_rivet_tr')), findsOneWidget);
      expect(find.byKey(const ValueKey('rsquare_plaque_rivet_bl')), findsOneWidget);
      expect(find.byKey(const ValueKey('rsquare_plaque_rivet_br')), findsOneWidget);
    });

    testWidgets('omits micro-rivets when showRivets is false or size is small', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: RsquareHardwarePlaque(
                size: 20,
                showRivets: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('rsquare_plaque_rivet_tl')), findsNothing);
    });

    testWidgets('adapts decoration for dark mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: RsquareHardwarePlaque(
                size: 36,
                isDark: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RsquareHardwarePlaque), findsOneWidget);
    });
  });
}
