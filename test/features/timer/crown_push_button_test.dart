import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/features/timer/presentation/widgets/crown_push_button.dart';

void main() {
  testWidgets('CrownPushButton renders in normal flush position when isPulledOut is false', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CrownPushButton(
              isPressed: false,
              isPulledOut: false,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CrownPushButton), findsOneWidget);
    expect(find.byKey(const Key('crown_stem_collar')), findsOneWidget);
    expect(find.byKey(const Key('crown_stem_shaft')), findsOneWidget);
    expect(find.byKey(const Key('crown_cap')), findsOneWidget);

    // Box dimensions: width: 36, height: 28
    final size = tester.getSize(find.byType(CrownPushButton));
    expect(size, equals(const Size(36.0, 28.0)));

    // Normal resting top position at 12.0
    final capPositioned = tester.widget<Positioned>(
      find.ancestor(
        of: find.byKey(const Key('crown_cap')),
        matching: find.byType(Positioned),
      ),
    );
    expect(capPositioned.top, equals(12.0));
  });

  testWidgets('CrownPushButton renders depressed at top 16.0 when isPressed is true', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CrownPushButton(
              isPressed: true,
              isPulledOut: false,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final capPositioned = tester.widget<Positioned>(
      find.ancestor(
        of: find.byKey(const Key('crown_cap')),
        matching: find.byType(Positioned),
      ),
    );
    expect(capPositioned.top, equals(16.0));
  });

  testWidgets('CrownPushButton elevates upward to top 4.0 and reveals stem shaft when isPulledOut is true', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CrownPushButton(
              isPressed: false,
              isPulledOut: false,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final initialCapPos = tester.getTopLeft(find.byKey(const Key('crown_cap')));

    // Rebuild with isPulledOut = true
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CrownPushButton(
              isPressed: false,
              isPulledOut: true,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    // Advance animation
    await tester.pumpAndSettle();

    final elevatedCapPos = tester.getTopLeft(find.byKey(const Key('crown_cap')));
    // Cap should have elevated upward by 8px
    expect(elevatedCapPos.dy, equals(initialCapPos.dy - 8.0));

    final capPositioned = tester.widget<Positioned>(
      find.ancestor(
        of: find.byKey(const Key('crown_cap')),
        matching: find.byType(Positioned),
      ),
    );
    expect(capPositioned.top, equals(4.0));
  });

  testWidgets('CrownPushButton triggers onPullOut on upward vertical drag', (tester) async {
    bool pullTriggered = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CrownPushButton(
              isPressed: false,
              isPulledOut: false,
              onTap: () {},
              onPullOut: () => pullTriggered = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.drag(find.byType(CrownPushButton), const Offset(0, -30));
    await tester.pumpAndSettle();

    expect(pullTriggered, isTrue);
  });

  testWidgets('CrownPushButton triggers onPushIn on downward vertical drag when pulled out', (tester) async {
    bool pushTriggered = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CrownPushButton(
              isPressed: false,
              isPulledOut: true,
              onTap: () {},
              onPushIn: () => pushTriggered = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.drag(find.byType(CrownPushButton), const Offset(0, 30));
    await tester.pumpAndSettle();

    expect(pushTriggered, isTrue);
  });

  testWidgets('CrownPushButton invokes onTap when tapped', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CrownPushButton(
              isPressed: false,
              isPulledOut: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(CrownPushButton));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
