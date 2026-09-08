import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/focus/focus_lock_controller.dart';
import 'package:takt_desk/core/focus/focus_lock_service.dart';
import 'package:takt_desk/features/desk/presentation/widgets/emergency_unlatch_widget.dart';

class MockFocusLockService extends FocusLockService {
  @override
  Future<bool> enableFocusLock() async => true;
  @override
  Future<bool> disableFocusLock() async => true;
}

void main() {
  testWidgets('EmergencyUnlatchWidget is hidden when unlocked, renders when locked', (tester) async {
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
            body: EmergencyUnlatchWidget(),
          ),
        ),
      ),
    );

    expect(find.text('HOLD 5s TO UNLATCH'), findsNothing);

    // Lock focus
    await container.read(focusLockProvider.notifier).engageLock();
    await tester.pump();

    expect(find.text('HOLD 5s TO UNLATCH'), findsOneWidget);
  });

  testWidgets('Holding for 5 seconds unlocks focus', (tester) async {
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
            body: EmergencyUnlatchWidget(),
          ),
        ),
      ),
    );

    await container.read(focusLockProvider.notifier).engageLock();
    await tester.pump();
    expect(container.read(focusLockProvider).isLocked, isTrue);

    final gesture = await tester.startGesture(tester.getCenter(find.byType(EmergencyUnlatchWidget)));
    await tester.pump();

    // Advance 5 seconds + 1 frame
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(container.read(focusLockProvider).isLocked, isFalse);
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('Releasing pointer before 5 seconds cancels hold and remains locked', (tester) async {
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
            body: EmergencyUnlatchWidget(),
          ),
        ),
      ),
    );

    await container.read(focusLockProvider.notifier).engageLock();
    await tester.pump();

    final gesture = await tester.startGesture(tester.getCenter(find.byType(EmergencyUnlatchWidget)));
    await tester.pump(const Duration(seconds: 2));
    expect(container.read(focusLockProvider).isHolding, isTrue);

    // Release early
    await gesture.up();
    await tester.pump();

    expect(container.read(focusLockProvider).isHolding, isFalse);
    expect(container.read(focusLockProvider).isLocked, isTrue);
    expect(find.text('HOLD 5s TO UNLATCH'), findsOneWidget);
  });
}
