import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/hardware_edition.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';
import 'package:takt_desk/core/focus/focus_lock_controller.dart';
import 'package:takt_desk/core/focus/focus_lock_service.dart';
import 'package:takt_desk/features/desk/presentation/widgets/monastic_switch_widget.dart';

class MockFocusLockService extends FocusLockService {
  @override
  Future<bool> enableFocusLock() async => true;
  @override
  Future<bool> disableFocusLock() async => true;
}

void main() {
  testWidgets('MonasticSwitchWidget renders and toggles focus lock', (tester) async {
    final container = ProviderContainer(
      overrides: [
        focusLockServiceProvider.overrideWithValue(MockFocusLockService()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: MonasticSwitchWidget(),
          ),
        ),
      ),
    );

    expect(find.text('MONASTIC'), findsOneWidget);
    expect(find.text('LOCKDOWN'), findsOneWidget);

    // Tap switch to engage
    await tester.tap(find.byType(MonasticSwitchWidget));
    await tester.pump();

    expect(container.read(focusLockProvider).isLocked, isTrue);
  });

  testWidgets('MonasticSwitchWidget renders locked state and handles tap when locked', (tester) async {
    final container = ProviderContainer(
      overrides: [
        focusLockServiceProvider.overrideWithValue(MockFocusLockService()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: MonasticSwitchWidget(),
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Monastic Focus Inactive',
      ),
      findsOneWidget,
    );

    // Engage lock
    await container.read(focusLockProvider.notifier).engageLock();
    await tester.pumpAndSettle();

    expect(find.text('MONASTIC'), findsOneWidget);
    expect(find.text('ENGAGED'), findsOneWidget);
    expect(find.text('LOCKDOWN'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Monastic Focus Engaged',
      ),
      findsOneWidget,
    );

    // Tap while locked should not error or change state
    await tester.tap(find.byType(MonasticSwitchWidget));
    await tester.pumpAndSettle();
    expect(container.read(focusLockProvider).isLocked, isTrue);
  });

  testWidgets('MonasticSwitchWidget renders LED and text in themeState.filamentColor when locked', (tester) async {
    final container = ProviderContainer(
      overrides: [
        focusLockServiceProvider.overrideWithValue(MockFocusLockService()),
      ],
    );
    addTearDown(container.dispose);

    container.read(chassisThemeProvider.notifier).setHardwareEdition(HardwareEditionType.titaniumStealth);
    await container.read(focusLockProvider.notifier).engageLock();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: MonasticSwitchWidget(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify outer container border and shadow use titaniumStealth.filamentColor
    final gestureFinder = find.byType(GestureDetector);
    final outerContainer = tester.widget<Container>(
      find.descendant(of: gestureFinder, matching: find.byType(Container)).first,
    );
    final outerDecoration = outerContainer.decoration as BoxDecoration;
    final border = outerDecoration.border as Border;
    expect(border.top.color, equals(const Color(0xFFFF9E00).withValues(alpha: 0.8)));
    expect(outerDecoration.boxShadow?.first.color, equals(const Color(0xFFFF9E00).withValues(alpha: 0.3)));

    // Verify LED indicator uses titaniumStealth.filamentColor
    final ledFinder = find.descendant(
      of: find.byType(MonasticSwitchWidget),
      matching: find.byType(AnimatedContainer),
    );
    expect(ledFinder, findsOneWidget);
    final animatedContainer = tester.widget<AnimatedContainer>(ledFinder);
    final ledBox = animatedContainer.decoration as BoxDecoration;
    expect(ledBox.color, equals(const Color(0xFFFF9E00)));
    expect(ledBox.boxShadow?.first.color, equals(const Color(0xFFFF9E00).withValues(alpha: 0.8)));

    // Verify ENGAGED text uses titaniumStealth.filamentColor
    final engagedText = tester.widget<Text>(find.text('ENGAGED'));
    expect(engagedText.style?.color, equals(const Color(0xFFFF9E00)));
  });
}
