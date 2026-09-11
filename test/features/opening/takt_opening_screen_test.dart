import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/features/desk/presentation/desk_canvas_screen.dart';
import 'package:takt_desk/features/opening/presentation/takt_opening_screen.dart';

void main() {
  testWidgets('TaktOpeningScreen renders initial ignition phase with micro-LED and RSQUARE branding', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TaktOpeningScreen(autoNavigate: false),
        ),
      ),
    );

    // Initial frame
    expect(find.byType(TaktOpeningScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('opening_micro_led')), findsOneWidget);
    expect(find.byKey(const ValueKey('opening_dial_canvas')), findsOneWidget);
    expect(find.textContaining('ENGINEERED BY RSQUARE'), findsOneWidget);

    final logoFinder = find.byWidgetPredicate(
      (w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == 'assets/images/rsquare_logo.png',
    );
    expect(logoFinder, findsOneWidget);

    // Verify scaffold uses dark background by default
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, const Color(0xFF121316));

    // Clean up
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TaktOpeningScreen tap-to-skip immediately navigates to DeskCanvasScreen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TaktOpeningScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(DeskCanvasScreen), findsNothing);

    // Tap anywhere on screen to skip
    await tester.tap(find.byType(TaktOpeningScreen));
    await tester.pumpAndSettle();

    // Now DeskCanvasScreen should be rendered
    expect(find.byType(DeskCanvasScreen), findsOneWidget);
  });

  testWidgets('TaktOpeningScreen automatically navigates to DeskCanvasScreen upon completion', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TaktOpeningScreen(),
        ),
      ),
    );

    // Pump through full 2400ms duration plus transition
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(find.byType(DeskCanvasScreen), findsOneWidget);
  });

  testWidgets('TaktOpeningScreen invokes onComplete callback if provided', (tester) async {
    bool completed = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: TaktOpeningScreen(
            autoNavigate: false,
            onComplete: () {
              completed = true;
            },
          ),
        ),
      ),
    );

    // Tap to skip triggers onComplete
    await tester.tap(find.byType(TaktOpeningScreen));
    await tester.pump();

    expect(completed, isTrue);
  });
}
