import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/features/tasks/domain/receipt_task.dart';
import 'package:takt_desk/features/tasks/presentation/receipt_runner_controller.dart';
import 'package:takt_desk/features/tasks/presentation/widgets/animated_receipt_strip.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('focus time per slip', () {
    late AppDatabase db;
    late ChronoDialController timer;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      timer = ChronoDialController(null, db);
    });

    tearDown(() async {
      timer.dispose();
      await db.close();
    });

    Future<int> focusOf(int id) async =>
        (await (db.select(db.tasks)..where((t) => t.id.equals(id))).getSingle()).focusSeconds;

    Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

    test('a finished focus session counts for the top open slip', () async {
      final first = await db.addTask('Outline');
      final second = await db.addTask('Draft');
      expect(await db.currentFocusTaskId(), first);

      timer.start();
      await settle();
      timer.tick(25 * 60);
      await settle();
      expect(await focusOf(first), 1500);
      expect(await focusOf(second), 0);
    });

    test('stamped slips are passed over; a breaks never counts', () async {
      final first = await db.addTask('Outline');
      final second = await db.addTask('Draft');
      await db.toggleTaskCompleted(first, true);
      expect(await db.currentFocusTaskId(), second);

      timer.start();
      await settle();
      timer.tick(25 * 60); // focus done → short break (not running)
      timer.start();
      await settle();
      timer.tick(5 * 60); // break done
      await settle();
      expect(await focusOf(second), 1500);
      expect(await focusOf(first), 0);
    });

    test('the slip is the one on top when the session started, even if stamped during it', () async {
      final first = await db.addTask('Outline');
      await db.addTask('Draft');
      timer.start();
      await settle();
      await db.toggleTaskCompleted(first, true);
      timer.tick(25 * 60);
      await settle();
      expect(await focusOf(first), 1500);
    });

    test('an abandoned session counts the minutes really focused (1 min or more)', () async {
      final first = await db.addTask('Outline');
      timer.start();
      await settle();
      timer.tick(600);
      timer.reset();
      await settle();
      expect(await focusOf(first), 600);

      timer.start();
      await settle();
      timer.tick(30);
      timer.reset();
      await settle();
      expect(await focusOf(first), 600, reason: 'under a minute is not recorded');
    });

    test('a slip printed after others were torn off goes to the end, so NOW and the credited slip agree', () async {
      final a = await db.addTask('A');
      final b = await db.addTask('B');
      final c = await db.addTask('C');
      await db.archiveTask(a);
      await db.archiveTask(b);
      final d = await db.addTask('D');
      expect(await db.currentFocusTaskId(), c, reason: 'C is on top, D was printed after it');
      final order = (await db.watchActiveTasks().first).map((t) => t.id).toList();
      expect(order, [c, d]);
    });

    test('the dispenser follows the focus time from the database', () async {
      final id = await db.addTask('Outline');
      final runner = ReceiptRunnerController(null, db);
      addTearDown(runner.dispose);
      await db.addTaskFocus(id, 1490);
      await settle();
      expect(runner.state.focusMinutesOf('$id'), 25);
      expect(runner.state.currentTaskId, '$id');
    });
  });

  testWidgets('the slip header shows NOW and the minutes focused', (tester) async {
    Widget strip({required bool current, required int minutes}) => MaterialApp(
          home: Scaffold(
            body: AnimatedReceiptStrip(
              task: ReceiptTask(id: '1', title: 'Outline'),
              index: 0,
              isCurrent: current,
              focusMinutes: minutes,
              onTearUpdate: (_) {},
              onTorn: () {},
              onStampToggle: () {},
            ),
          ),
        );

    await tester.pumpWidget(strip(current: true, minutes: 50));
    expect(find.text('#01 // NOW · 50 MIN'), findsOneWidget);

    await tester.pumpWidget(strip(current: false, minutes: 0));
    await tester.pumpAndSettle();
    expect(find.text('#01 // ZYKL'), findsOneWidget);
  });
}
