import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/hardware_edition.dart';
import 'package:takt_desk/features/settings/presentation/widgets/studio_pro_dialog.dart';

void main() {
  testWidgets('showStudioProDialog renders material showcase plaque for hardware edition', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () => showStudioProDialog(
                    context,
                    ref,
                    edition: HardwareEdition.midCenturyWalnut,
                  ),
                  child: const Text('OPEN PRO DIALOG'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN PRO DIALOG'));
    await tester.pumpAndSettle();

    expect(find.text('TAKT DESK STUDIO PRO'), findsOneWidget);
    expect(find.text('RSQUARE'), findsOneWidget);
    final logoFinder = find.byWidgetPredicate(
      (w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == 'assets/images/rsquare_logo.png',
    );
    expect(logoFinder, findsOneWidget);
    expect(find.textContaining('MID-CENTURY WALNUT'), findsOneWidget);
    expect(find.byKey(const ValueKey('material_showcase_plaque')), findsOneWidget);
    expect(find.byKey(const ValueKey('pro_dialog_unlock_button')), findsOneWidget);
  });

  testWidgets('showStudioProDialog does not render material showcase plaque when edition is null', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () => showStudioProDialog(
                    context,
                    ref,
                  ),
                  child: const Text('OPEN PRO DIALOG'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN PRO DIALOG'));
    await tester.pumpAndSettle();

    expect(find.text('TAKT DESK STUDIO PRO'), findsOneWidget);
    expect(find.byKey(const ValueKey('material_showcase_plaque')), findsNothing);
  });

  testWidgets('showStudioProDialog renders plaque details in light mode', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () => showStudioProDialog(
                    context,
                    ref,
                    edition: HardwareEdition.forgedCarbon,
                    isDark: false,
                  ),
                  child: const Text('OPEN PRO DIALOG'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN PRO DIALOG'));
    await tester.pumpAndSettle();

    expect(find.text('TAKT DESK STUDIO PRO'), findsOneWidget);
    expect(find.textContaining('FORGED CARBON'), findsOneWidget);
    expect(find.text('STUDIO PRO FINISH'), findsOneWidget);
    expect(find.textContaining('MOD. 07 · 2024'), findsOneWidget);
    expect(find.byKey(const ValueKey('material_showcase_plaque')), findsOneWidget);
  });
}
