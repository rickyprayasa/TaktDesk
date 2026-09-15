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
    expect(find.byKey(const Key('crown_stem_shaft')), findsOneWidget);
  });

  testWidgets('CrownPushButton elevates upward and reveals stem shaft when isPulledOut is true', (tester) async {
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

    // Advance animation by 160ms
    await tester.pumpAndSettle();

    final elevatedCapPos = tester.getTopLeft(find.byKey(const Key('crown_cap')));
    // Cap should have elevated upward by 6px
    expect(elevatedCapPos.dy, equals(initialCapPos.dy - 6.0));
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
