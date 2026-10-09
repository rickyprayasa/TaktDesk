import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/backup/history_backup.dart';
import 'package:takt_desk/core/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase source;
  late AppDatabase target;

  final start = DateTime(2026, 10, 8, 9, 30);

  Future<void> seed(AppDatabase db) async {
    await db.into(db.timerSessions).insert(TimerSessionsCompanion.insert(
          targetMinutes: 25,
          elapsedSeconds: 1500,
          isFinished: const Value(true),
          startedAt: Value(start),
          finishedAt: Value(start.add(const Duration(minutes: 25))),
        ));
    await db.into(db.timerSessions).insert(TimerSessionsCompanion.insert(
          targetMinutes: 50,
          elapsedSeconds: 900,
          startedAt: Value(start.add(const Duration(hours: 2))),
        ));
    await db.into(db.timerSessions).insert(TimerSessionsCompanion.insert(
          targetMinutes: 30,
          elapsedSeconds: 1800,
          isLockdownOnly: const Value(true),
          startedAt: Value(start.add(const Duration(hours: 4))),
        ));
    await db.into(db.tasks).insert(TasksCompanion.insert(
          title: 'Draft, chapter 3',
          isCompleted: const Value(true),
          isArchived: const Value(true),
          createdAt: Value(start),
          completedAt: Value(start.add(const Duration(minutes: 40))),
        ));
    await db.into(db.tasks).insert(TasksCompanion.insert(title: 'Reply to "Ana"', createdAt: Value(start)));
  }

  setUp(() {
    source = AppDatabase.forTesting(NativeDatabase.memory());
    target = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await source.close();
    await target.close();
  });

  test('a backup restores every session and slip on another phone', () async {
    await seed(source);
    final json = await HistoryBackup(source).buildJson(now: DateTime.utc(2026, 10, 9));
    final decoded = jsonDecode(json) as Map;
    expect(decoded['app'], 'ZYKL');
    expect(decoded['format'], HistoryBackup.formatVersion);

    final result = await HistoryBackup(target).restoreJson(json);
    expect(result.sessionsAdded, 3);
    expect(result.tasksAdded, 2);
    expect(result.sessionsSkipped + result.tasksSkipped, 0);

    final sessions = await target.select(target.timerSessions).get();
    sessions.sort((a, b) => a.startedAt.compareTo(b.startedAt));
    expect(sessions.map((s) => s.targetMinutes), [25, 50, 30]);
    expect(sessions.first.startedAt, start);
    expect(sessions.first.isFinished, isTrue);
    expect(sessions.first.finishedAt, start.add(const Duration(minutes: 25)));
    expect(sessions.last.isLockdownOnly, isTrue);

    final tasks = await target.select(target.tasks).get();
    expect(tasks.map((t) => t.title), containsAll(['Draft, chapter 3', 'Reply to "Ana"']));
    expect(tasks.firstWhere((t) => t.isArchived).completedAt, start.add(const Duration(minutes: 40)));
  });

  test('restoring the same backup twice adds nothing the second time', () async {
    await seed(source);
    final json = await HistoryBackup(source).buildJson();
    await HistoryBackup(target).restoreJson(json);
    final again = await HistoryBackup(target).restoreJson(json);
    expect(again.sessionsAdded, 0);
    expect(again.tasksAdded, 0);
    expect(again.sessionsSkipped, 3);
    expect(again.tasksSkipped, 2);
    expect(await target.select(target.timerSessions).get(), hasLength(3));
  });

  test('a restore never pushes the dispenser past five active slips', () async {
    for (var i = 0; i < 4; i++) {
      await target.addTask('Here $i');
    }
    final json = jsonEncode({
      'app': 'ZYKL',
      'format': 1,
      'sessions': [],
      'tasks': [
        for (var i = 0; i < 3; i++) {'title': 'Backup $i', 'createdAt': start.toUtc().toIso8601String()},
        {'title': 'Old', 'isArchived': true, 'createdAt': start.toUtc().toIso8601String()},
      ],
    });
    final result = await HistoryBackup(target).restoreJson(json);
    expect(result.tasksAdded, 2, reason: 'one active slip (to reach 5) + the archived one');
    expect(result.tasksSkipped, 2);
    expect((await target.watchActiveTasks().first), hasLength(5));
  });

  test('malformed entries are skipped, foreign or newer files are refused', () async {
    final history = HistoryBackup(target);
    await expectLater(history.restoreJson('not json'), throwsA(isA<BackupFormatException>()));
    await expectLater(history.restoreJson('{"app":"Other","format":1}'), throwsA(isA<BackupFormatException>()));
    await expectLater(history.restoreJson('{"app":"ZYKL","format":99}'), throwsA(isA<BackupFormatException>()));

    final result = await history.restoreJson(jsonEncode({
      'app': 'ZYKL',
      'format': 1,
      'sessions': [
        {'targetMinutes': 25, 'elapsedSeconds': 1500, 'startedAt': start.toUtc().toIso8601String()},
        {'targetMinutes': '25', 'elapsedSeconds': 1500, 'startedAt': start.toUtc().toIso8601String()},
        {'targetMinutes': 25, 'elapsedSeconds': -4, 'startedAt': start.toUtc().toIso8601String()},
        {'targetMinutes': 25, 'elapsedSeconds': 60},
        'junk',
      ],
      'tasks': [
        {'title': '', 'createdAt': start.toUtc().toIso8601String()},
        {'title': 'x' * 141, 'createdAt': start.toUtc().toIso8601String()},
      ],
    }));
    expect(result.sessionsAdded, 1);
    expect(result.sessionsSkipped, 4);
    expect(result.tasksAdded, 0);
    expect(result.tasksSkipped, 2);
  });

  test('CSV has one row per session, oldest first', () async {
    await seed(source);
    final lines = const LineSplitter().convert(await HistoryBackup(source).buildCsv());
    expect(lines.first, 'started_at,finished_at,target_minutes,elapsed_seconds,focused_minutes,finished,lockdown_only');
    expect(lines, hasLength(4));
    expect(lines[1], '${start.toUtc().toIso8601String()},${start.add(const Duration(minutes: 25)).toUtc().toIso8601String()},25,1500,25.0,true,false');
    expect(lines[2].endsWith(',50,900,15.0,false,false'), isTrue);
    expect(lines[3].endsWith(',30,1800,30.0,false,true'), isTrue);
  });

  group('file picker channel', () {
    final calls = <MethodCall>[];
    Object? reply;

    setUp(() {
      calls.clear();
      reply = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(HistoryBackup.channel, (call) async {
        calls.add(call);
        return reply;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(HistoryBackup.channel, null);
    });

    test('exports name the file by date and type', () async {
      await seed(source);
      final now = DateTime(2026, 10, 9);
      expect(await HistoryBackup(source).exportCsv(now: now), isTrue);
      expect(calls.last.arguments['fileName'], 'zykl-sessions-2026-10-09.csv');
      expect(calls.last.arguments['mimeType'], 'text/csv');

      await HistoryBackup(source).exportBackup(now: now);
      expect(calls.last.method, 'saveFile');
      expect(calls.last.arguments['fileName'], 'zykl-backup-2026-10-09.json');
      expect(jsonDecode(calls.last.arguments['content'] as String)['sessions'], hasLength(3));

      reply = null; // picker cancelled
      expect(await HistoryBackup(source).exportCsv(now: now), isNull);
    });

    test('pickAndRestore merges the picked file, null when cancelled', () async {
      await seed(source);
      reply = await HistoryBackup(source).buildJson();
      final result = await HistoryBackup(target).pickAndRestore();
      expect(calls.last.method, 'openFile');
      expect(result!.sessionsAdded, 3);

      reply = null;
      expect(await HistoryBackup(target).pickAndRestore(), isNull);
    });
  });
}
