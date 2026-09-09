import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('can insert, retrieve, complete, and enforce max 5 tasks', () async {
    for (int i = 1; i <= 5; i++) {
      await db.addTask('Task $i');
    }
    final active = await db.watchActiveTasks().first;
    expect(active.length, 5);

    // Complete task 1
    await db.toggleTaskCompleted(active.first.id, true);
    final updated = await db.watchActiveTasks().first;
    expect(updated.first.isCompleted, isTrue);

    // Enforce max 5 tasks
    expect(() => db.addTask('Task 6'), throwsA(isA<Exception>()));

    // Archive task 1
    await db.archiveTask(active.first.id);
    final afterArchive = await db.watchActiveTasks().first;
    expect(afterArchive.length, 4);

    // Can add a new task after archiving
    await db.addTask('Task 6');
    final afterAdding = await db.watchActiveTasks().first;
    expect(afterAdding.length, 5);
  });

  test('can record timer session', () async {
    final now = DateTime.now();
    final id = await db.recordTimerSession(
      targetMinutes: 25,
      elapsedSeconds: 1500,
      isFinished: true,
      startedAt: now,
    );
    expect(id, greaterThan(0));

    final sessions = await db.select(db.timerSessions).get();
    expect(sessions.length, 1);
    expect(sessions.first.targetMinutes, 25);
    expect(sessions.first.elapsedSeconds, 1500);
    expect(sessions.first.isFinished, isTrue);
  });

  test('can watch and insert desk preferences', () async {
    final initial = await db.watchPreferences().first;
    expect(initial, isNull);

    await db.into(db.deskPreferences).insert(
      const DeskPreferencesCompanion(),
    );
    final pref = await db.watchPreferences().first;
    expect(pref, isNotNull);
    expect(pref!.soundVolume, 0.8);
    expect(pref.parallaxEnabled, isTrue);
    expect(pref.activeAmbientTrackIndex, 0);
  });

  test('watchTodayTimerSessions filters sessions for the current day only', () async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    // Past session
    await db.recordTimerSession(
      targetMinutes: 25,
      elapsedSeconds: 1500,
      isFinished: true,
      startedAt: yesterday,
    );

    // Today session 1
    await db.recordTimerSession(
      targetMinutes: 25,
      elapsedSeconds: 1500,
      isFinished: true,
      startedAt: now.subtract(const Duration(hours: 1)),
    );

    // Today session 2 (unfinished)
    await db.recordTimerSession(
      targetMinutes: 5,
      elapsedSeconds: 60,
      isFinished: false,
      startedAt: now,
    );

    final todaySessions = await db.watchTodayTimerSessions().first;
    expect(todaySessions.length, equals(2));
    expect(todaySessions.first.isFinished, isTrue);
  });

  test('clearTimerSessions removes all session records', () async {
    await db.recordTimerSession(
      targetMinutes: 25,
      elapsedSeconds: 1500,
      isFinished: true,
      startedAt: DateTime.now(),
    );

    await db.clearTimerSessions();
    final allSessions = await db.watchAllTimerSessions().first;
    expect(allSessions, isEmpty);
  });

  test('can update preferences including foley and haptics', () async {
    await db.updatePreferences(
      soundVolume: 0.5,
      foleyEnabled: false,
      hapticsEnabled: false,
    );
    var pref = await db.watchPreferences().first;
    expect(pref, isNotNull);
    expect(pref!.soundVolume, 0.5);
    expect(pref.foleyEnabled, isFalse);
    expect(pref.hapticsEnabled, isFalse);

    await db.updatePreferences(
      foleyEnabled: true,
    );
    pref = await db.watchPreferences().first;
    expect(pref!.foleyEnabled, isTrue);
    expect(pref.hapticsEnabled, isFalse);
  });
}
