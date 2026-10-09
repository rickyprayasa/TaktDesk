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
    expect(pref.foleyEnabled, isTrue);
    expect(pref.hapticsEnabled, isTrue);
  });

  test('watchTodayTimerSessions filters sessions for the current day only', () async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final yesterday = startOfDay.subtract(const Duration(hours: 2));
    final todaySession1 = startOfDay.add(const Duration(minutes: 10));
    final todaySession2 = startOfDay.add(const Duration(minutes: 40));

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
      startedAt: todaySession1,
    );

    // Today session 2 (unfinished)
    await db.recordTimerSession(
      targetMinutes: 5,
      elapsedSeconds: 60,
      isFinished: false,
      startedAt: todaySession2,
    );

    final todaySessions = await db.watchTodayTimerSessions().first;
    expect(todaySessions.length, equals(2));
    expect(todaySessions.first.isFinished, isTrue);
  });

  test('watchAllTimerSessions returns multiple sessions in descending timestamp order', () async {
    final t1 = DateTime(2026, 1, 1, 10, 0);
    final t2 = DateTime(2026, 1, 1, 11, 0);
    final t3 = DateTime(2026, 1, 1, 12, 0);

    await db.recordTimerSession(
      targetMinutes: 25,
      elapsedSeconds: 1500,
      isFinished: true,
      startedAt: t1,
    );
    await db.recordTimerSession(
      targetMinutes: 15,
      elapsedSeconds: 900,
      isFinished: true,
      startedAt: t3,
    );
    await db.recordTimerSession(
      targetMinutes: 30,
      elapsedSeconds: 1800,
      isFinished: false,
      startedAt: t2,
    );

    final all = await db.watchAllTimerSessions().first;
    expect(all.length, 3);
    expect(all[0].startedAt, equals(t3));
    expect(all[1].startedAt, equals(t2));
    expect(all[2].startedAt, equals(t1));
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

  test('deskClockMode defaults to off and persists (schema v9)', () async {
    await db.updatePreferences(soundVolume: 0.7);
    var pref = await db.watchPreferences().first;
    expect(pref!.deskClockMode, isFalse);

    await db.updatePreferences(deskClockMode: true);
    pref = await db.watchPreferences().first;
    expect(pref!.deskClockMode, isTrue);
    expect(pref.soundVolume, 0.7);
  });

  test('autoStartNextPhase defaults to off and persists (schema v10)', () async {
    await db.updatePreferences(soundVolume: 0.6);
    expect((await db.watchPreferences().first)!.autoStartNextPhase, isFalse);
    await db.updatePreferences(autoStartNextPhase: true);
    expect((await db.watchPreferences().first)!.autoStartNextPhase, isTrue);
  });

  test('can persist and update selectedEdition and isProSimulated in preferences', () async {
    await db.into(db.deskPreferences).insert(
      const DeskPreferencesCompanion(),
    );
    final initialPref = await db.watchPreferences().first;
    expect(initialPref!.selectedEdition, equals('braunClassic'));
    expect(initialPref.isProSimulated, isTrue);

    await db.updatePreferences(
      selectedEdition: 'titaniumStealth',
      isProSimulated: false,
    );

    final updatedPref = await db.watchPreferences().first;
    expect(updatedPref!.selectedEdition, equals('titaniumStealth'));
    expect(updatedPref.isProSimulated, isFalse);
  });
}
