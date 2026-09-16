import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takt_desk/features/tasks/domain/receipt_task.dart';
import 'package:takt_desk/features/tasks/presentation/receipt_runner_controller.dart';
import 'package:takt_desk/features/tasks/presentation/widgets/archive_drawer_widget.dart';

void main() {
  testWidgets('partitions archived tasks into 10-task modular drawers', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Simulate 23 completed tasks
    final fakeTasks = List.generate(
      23,
      (i) => ReceiptTask(
        id: 'task_$i',
        title: 'Task #$i',
        isCompleted: true,
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ArchiveDrawerWidget(),
            ),
          ),
        ),
      ),
    );

    // Initially 0 tasks -> 1 empty drawer
    expect(find.textContaining('ARCHIVE // DRAWER 01'), findsOneWidget);

    // Update state with 23 tasks
    container.read(receiptRunnerProvider.notifier).state =
        container.read(receiptRunnerProvider).copyWith(archivedTasks: fakeTasks);
    await tester.pumpAndSettle();

    // Now must display 3 drawers (Drawer 01: 10, Drawer 02: 10, Drawer 03: 3)
    expect(find.textContaining('ARCHIVE // DRAWER 01'), findsOneWidget);
    expect(find.textContaining('ARCHIVE // DRAWER 02'), findsOneWidget);
    expect(find.textContaining('ARCHIVE // DRAWER 03'), findsOneWidget);
    expect(find.textContaining('10 TASKS'), findsNWidgets(2));
    expect(find.textContaining('03 TASKS'), findsOneWidget);
  });

  testWidgets('toggles drawers independently and displays partition tasks', (tester) async {
    final controller = ReceiptRunnerController();
    final fakeTasks = List.generate(
      15,
      (i) => ReceiptTask(
        id: 'task_$i',
        title: 'Task #$i',
        isCompleted: true,
      ),
    );
    controller.state = controller.state.copyWith(archivedTasks: fakeTasks);

    final container = ProviderContainer(
      overrides: [
        receiptRunnerProvider.overrideWith((ref) => controller),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ArchiveDrawerWidget(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Should have 2 drawers: Drawer 01 (10 tasks), Drawer 02 (5 tasks)
    expect(find.byKey(const ValueKey('archive_drawer_handle_0')), findsOneWidget);
    expect(find.byKey(const ValueKey('archive_drawer_handle_1')), findsOneWidget);
    expect(find.text('Task #0'), findsNothing);
    expect(find.text('Task #14'), findsNothing);

    // Tap Drawer 01 handle to open
    await tester.tap(find.byKey(const ValueKey('archive_drawer_handle_0')));
    await tester.pumpAndSettle();

    // Drawer 01 tasks visible, Drawer 02 tasks still hidden
    expect(find.text('Task #0'), findsOneWidget);
    expect(find.text('Task #14'), findsNothing);

    // Tap Drawer 02 handle to open as well
    await tester.tap(find.byKey(const ValueKey('archive_drawer_handle_1')));
    await tester.pumpAndSettle();

    expect(find.text('Task #0'), findsOneWidget);
    expect(find.text('Task #14'), findsOneWidget);

    // Close Drawer 01
    await tester.tap(find.byKey(const ValueKey('archive_drawer_handle_0')));
    await tester.pumpAndSettle();

    expect(find.text('Task #0'), findsNothing);
    expect(find.text('Task #14'), findsOneWidget);
  });

  testWidgets('purges only the targeted partition batch when tapping PURGE THIS BATCH', (tester) async {
    final controller = ReceiptRunnerController();
    final fakeTasks = List.generate(
      15,
      (i) => ReceiptTask(
        id: 'task_$i',
        title: 'Task #$i',
        isCompleted: true,
      ),
    );
    controller.state = controller.state.copyWith(archivedTasks: fakeTasks);

    final container = ProviderContainer(
      overrides: [
        receiptRunnerProvider.overrideWith((ref) => controller),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ArchiveDrawerWidget(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open Drawer 01 (contains Task #0 through Task #9)
    await tester.tap(find.byKey(const ValueKey('archive_drawer_handle_0')));
    await tester.pumpAndSettle();

    expect(find.text('PURGE THIS BATCH'), findsOneWidget);

    // Tap PURGE THIS BATCH
    await tester.tap(find.text('PURGE THIS BATCH'));
    await tester.pumpAndSettle();

    // Remaining tasks should now be 5 tasks (Task #10 through Task #14)
    expect(controller.state.archivedTasks.length, 5);
    expect(controller.state.archivedTasks.first.title, 'Task #10');

    // Drawer count updates to 1 drawer of 05 tasks
    expect(find.textContaining('ARCHIVE // DRAWER 01 · 05 TASKS'), findsOneWidget);
    expect(find.byKey(const ValueKey('archive_drawer_handle_1')), findsNothing);
  });

  testWidgets('reprints task into active queue from open partition drawer', (tester) async {
    final controller = ReceiptRunnerController();
    final fakeTasks = [
      ReceiptTask(id: 't_alpha', title: 'Restorable Alpha Task', isCompleted: true),
    ];
    controller.state = controller.state.copyWith(archivedTasks: fakeTasks);

    final container = ProviderContainer(
      overrides: [
        receiptRunnerProvider.overrideWith((ref) => controller),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ArchiveDrawerWidget(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open Drawer 01
    await tester.tap(find.byKey(const ValueKey('archive_drawer_handle_0')));
    await tester.pumpAndSettle();

    expect(find.text('Restorable Alpha Task'), findsOneWidget);
    expect(find.text('REPRINT'), findsOneWidget);

    // Tap reprint
    await tester.tap(find.text('REPRINT'));
    await tester.pumpAndSettle();

    expect(controller.state.tasks.length, 1);
    expect(controller.state.tasks.first.title, 'Restorable Alpha Task');
  });
}
