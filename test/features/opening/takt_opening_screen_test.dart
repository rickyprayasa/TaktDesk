import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/features/desk/presentation/desk_canvas_screen.dart';
import 'package:takt_desk/features/opening/presentation/takt_opening_screen.dart';

void main() {
  testWidgets('TaktOpeningScreen renders initial ignition phase with Pomodoro clock dial, and bold ZYKL branding without developer logo', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TaktOpeningScreen(autoNavigate: false),
        ),
      ),
    );

    // Initial frame
    expect(find.byType(TaktOpeningScreen), findsOneWidget);
    // No power LED on the opening: the only LED is the desk's timer status LED.
    expect(find.byKey(const ValueKey('opening_micro_led')), findsNothing);
    expect(find.byKey(const ValueKey('opening_dial_canvas')), findsOneWidget);

    // Assert prominent ZYKL identity and Pomodoro system subtitle
    expect(find.text('ZYKL'), findsOneWidget);
    expect(find.text('POMODORO FOCUS TIMER'), findsOneWidget);

    // Assert NO developer logo image or developer text is displayed
    expect(find.byType(Image), findsNothing);
    expect(find.textContaining('ENGINEERED BY RSQUARE'), findsNothing);
    expect(find.textContaining('DEVELOPED BY RSQUARE'), findsNothing);

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

  testWidgets('TaktOpeningScreen automatically navigates to DeskCanvasScreen upon completion (4.2s boot sequence)', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TaktOpeningScreen(),
        ),
      ),
    );

    // Not yet: the cinematic boot is still running at 2 s
    await tester.pump(const Duration(milliseconds: 2000));
    expect(find.byType(DeskCanvasScreen), findsNothing);

    // Pump through the 4.2s boot plus the 900ms hand-off
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pump(const Duration(milliseconds: 1000));
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

  testWidgets('TaktOpeningScreen shows a static lockup and still hands over when animations are disabled', (tester) async {
    bool completed = false;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: TaktOpeningScreen(autoNavigate: false, onComplete: () => completed = true),
          ),
        ),
      ),
    );
    await tester.pump();

    // Everything is already in place on the first frame
    expect(find.text('ZYKL'), findsOneWidget);
    expect(find.text('QUIET TIME. PHYSICAL INTENT.'), findsOneWidget);
    final brandLine = tester.widget<Opacity>(
      find.ancestor(of: find.text('QUIET TIME. PHYSICAL INTENT.'), matching: find.byType(Opacity)).first,
    );
    expect(brandLine.opacity, 1.0);

    // The preference load never resolves under fake async, so this also covers
    // the 3 s safety timeout that keeps a slow disk from holding the user here.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 2400));
    expect(completed, isTrue);
  });
}
