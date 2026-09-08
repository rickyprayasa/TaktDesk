import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/features/tasks/domain/receipt_task.dart';
import 'package:takt_desk/features/tasks/presentation/receipt_runner_controller.dart';
import 'package:takt_desk/features/tasks/presentation/widgets/archive_drawer_widget.dart';

void main() {
  testWidgets('ArchiveDrawerWidget toggles open and closed on handle tap', (tester) async {
    final testDb = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(testDb.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                child: ArchiveDrawerWidget(),
              ),
            ),
          ),
        ),
      ),
    );

    // Initial closed state displays handle label
    expect(find.text('ARCHIVE // 0'), findsOneWidget);
    expect(find.text('DRAWER EMPTY'), findsNothing);

    // Tap handle to open drawer
    await tester.tap(find.text('ARCHIVE // 0'));
    await tester.pumpAndSettle();

    // Drawer is now open and shows empty state
    expect(find.text('DRAWER EMPTY'), findsOneWidget);

    // Tap handle again to close drawer
    await tester.tap(find.text('ARCHIVE // 0'));
    await tester.pumpAndSettle();

    expect(find.text('DRAWER EMPTY'), findsNothing);
  });

  testWidgets('ArchiveDrawerWidget displays archived tasks with reprint and purge', (tester) async {
    final testDb = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(testDb.close);

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(testDb),
      ],
    );
    addTearDown(container.dispose);

    // Pre-populate with one active task and tear it into archive
    final controller = container.read(receiptRunnerProvider.notifier);
    await controller.addTask('Deep Architecture Plan');
    expect(container.read(receiptRunnerProvider).tasks.length, 1);

    final taskId = container.read(receiptRunnerProvider).tasks.first.id;
    controller.tearTask(taskId);

    expect(container.read(receiptRunnerProvider).tasks.isEmpty, isTrue);
    expect(container.read(receiptRunnerProvider).archivedTasks.length, 1);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                child: ArchiveDrawerWidget(),
              ),
            ),
          ),
        ),
      ),
    );

    // Handle should show count 1
    expect(find.text('ARCHIVE // 1'), findsOneWidget);

    // Open drawer
    await tester.tap(find.text('ARCHIVE // 1'));
    await tester.pumpAndSettle();

    // Verify task title and reprint button appear
    expect(find.text('Deep Architecture Plan'), findsOneWidget);
    expect(find.text('REPRINT'), findsOneWidget);
    expect(find.text('PURGE ARCHIVE'), findsOneWidget);

    // Tap REPRINT button
    await tester.tap(find.text('REPRINT'));
    await tester.pumpAndSettle();

    // Task is restored to active queue
    expect(container.read(receiptRunnerProvider).tasks.length, 1);
    expect(container.read(receiptRunnerProvider).tasks.first.title, 'Deep Architecture Plan');

    // Tap PURGE ARCHIVE
    await tester.tap(find.text('PURGE ARCHIVE'));
    await tester.pumpAndSettle();

    // Archive is now empty
    expect(container.read(receiptRunnerProvider).archivedTasks.isEmpty, isTrue);
    expect(find.text('DRAWER EMPTY'), findsOneWidget);
  });
}
