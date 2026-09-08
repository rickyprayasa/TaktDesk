import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
