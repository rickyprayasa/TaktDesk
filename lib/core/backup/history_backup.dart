import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';

final historyBackupProvider = Provider<HistoryBackup>((ref) {
  return HistoryBackup(ref.watch(appDatabaseProvider));
});

/// What a restore added and what it left out (already there, malformed, or over the 5 active slips).
class RestoreResult {
  final int sessionsAdded;
  final int sessionsSkipped;
  final int tasksAdded;
  final int tasksSkipped;

  const RestoreResult({
    required this.sessionsAdded,
    required this.sessionsSkipped,
    required this.tasksAdded,
    required this.tasksSkipped,
  });
}

class BackupFormatException implements Exception {
  final String message;
  const BackupFormatException(this.message);

  @override
  String toString() => message;
}

/// Focus history out of and back into the app: a CSV of the sessions for spreadsheets and a JSON backup (sessions +
/// task slips) that restores on any phone. Files go through the system file picker (com.zykl.app/backup), so the
/// user chooses where they live and no storage permission is needed. A restore merges: nothing is deleted, entries
/// already present are skipped.
class HistoryBackup {
  static const MethodChannel channel = MethodChannel('com.zykl.app/backup');
  static const int formatVersion = 1;
  static const int maxActiveTasks = 5;

  final AppDatabase _db;

  const HistoryBackup(this._db);

  static String _iso(DateTime? d) => d?.toUtc().toIso8601String() ?? '';

  static String _date(DateTime now) =>
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  Future<List<TimerSession>> _sessions() =>
      (_db.select(_db.timerSessions)..orderBy([(t) => OrderingTerm(expression: t.startedAt)])).get();

  Future<List<Task>> _tasks() =>
      (_db.select(_db.tasks)..orderBy([(t) => OrderingTerm(expression: t.createdAt)])).get();

  /// The slip a session was focused on, by id (sessions only keep the id; ids differ between phones).
  static Map<int, Task> _byId(List<Task> tasks) => {for (final t in tasks) t.id: t};

  Future<String> buildJson({DateTime? now}) async {
    final sessions = await _sessions();
    final tasks = await _tasks();
    final taskById = _byId(tasks);
    return const JsonEncoder.withIndent('  ').convert({
      'app': 'ZYKL',
      'format': formatVersion,
      'exportedAt': _iso(now ?? DateTime.now()),
      'sessions': [
        for (final s in sessions)
          {
            'targetMinutes': s.targetMinutes,
            'elapsedSeconds': s.elapsedSeconds,
            'isFinished': s.isFinished,
            'isLockdownOnly': s.isLockdownOnly,
            'startedAt': _iso(s.startedAt),
            'finishedAt': s.finishedAt == null ? null : _iso(s.finishedAt),
            // A slip is identified across phones by its title and creation time, like the restore's duplicate check.
            if (taskById[s.taskId] case final t?) 'task': {'title': t.title, 'createdAt': _iso(t.createdAt)},
          },
      ],
      'tasks': [
        for (final t in tasks)
          {
            'title': t.title,
            'isCompleted': t.isCompleted,
            'isArchived': t.isArchived,
            'sortOrder': t.sortOrder,
            'createdAt': _iso(t.createdAt),
            'completedAt': t.completedAt == null ? null : _iso(t.completedAt),
            'focusSeconds': t.focusSeconds,
          },
      ],
    });
  }

  /// RFC 4180 quoting for a free-text field (slip titles may hold commas or quotes).
  static String _csvField(String v) =>
      v.contains(RegExp(r'[",\r\n]')) ? '"${v.replaceAll('"', '""')}"' : v;

  /// One row per session, times in UTC (ISO 8601), for spreadsheets. `task` is the slip the session was focused on.
  Future<String> buildCsv() async {
    final taskById = _byId(await _tasks());
    final rows = <String>[
      'started_at,finished_at,target_minutes,elapsed_seconds,focused_minutes,finished,lockdown_only,task',
    ];
    for (final s in await _sessions()) {
      rows.add([
        _iso(s.startedAt),
        _iso(s.finishedAt),
        s.targetMinutes,
        s.elapsedSeconds,
        (s.elapsedSeconds / 60).toStringAsFixed(1),
        s.isFinished,
        s.isLockdownOnly,
        _csvField(taskById[s.taskId]?.title ?? ''),
      ].join(','));
    }
    return '${rows.join('\n')}\n';
  }

  static DateTime? _parseDate(Object? v) => v is String && v.isNotEmpty ? DateTime.tryParse(v)?.toLocal() : null;

  static int _seconds(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

  /// The local id of a session's slip reference ({title, createdAt}); null when absent or that slip isn't here.
  static int? _taskRef(Object? ref, Map<String, int> taskIdByKey) {
    if (ref is! Map || ref['title'] is! String) return null;
    final createdAt = _parseDate(ref['createdAt']);
    if (createdAt == null) return null;
    return taskIdByKey['${(ref['title'] as String).trim()}|${_seconds(createdAt)}'];
  }

  Future<RestoreResult> restoreJson(String text) async {
    final Object? root;
    try {
      root = jsonDecode(text);
    } on FormatException {
      throw const BackupFormatException('This file is not a ZYKL backup.');
    }
    if (root is! Map || root['app'] != 'ZYKL' || root['format'] is! int) {
      throw const BackupFormatException('This file is not a ZYKL backup.');
    }
    if ((root['format'] as int) > formatVersion) {
      throw const BackupFormatException('This backup comes from a newer ZYKL. Update the app first.');
    }
    final sessionsIn = root['sessions'] is List ? root['sessions'] as List : const [];
    final tasksIn = root['tasks'] is List ? root['tasks'] as List : const [];

    return _db.transaction(() async {
      var sessionsAdded = 0, sessionsSkipped = 0, tasksAdded = 0, tasksSkipped = 0;

      // Slips first, so a session can point at the slip it was focused on (ids are new on this phone).
      final existingTasks = await _tasks();
      final taskIdByKey = {for (final t in existingTasks) '${t.title}|${_seconds(t.createdAt)}': t.id};
      var activeCount = existingTasks.where((t) => !t.isArchived).length;
      for (final raw in tasksIn) {
        final title = raw is Map && raw['title'] is String ? (raw['title'] as String).trim() : '';
        final createdAt = raw is Map ? _parseDate(raw['createdAt']) : null;
        if (raw is! Map || title.isEmpty || title.length > 140 || createdAt == null) {
          tasksSkipped++;
          continue;
        }
        final archived = raw['isArchived'] == true;
        // The dispenser holds five active slips; a restore never pushes past that.
        final key = '$title|${_seconds(createdAt)}';
        if (taskIdByKey.containsKey(key) || (!archived && activeCount >= maxActiveTasks)) {
          tasksSkipped++;
          continue;
        }
        taskIdByKey[key] = await _db.into(_db.tasks).insert(TasksCompanion.insert(
              title: title,
              isCompleted: Value(raw['isCompleted'] == true),
              isArchived: Value(archived),
              // Active slips go after the ones already in the dispenser (backup order kept among themselves).
              sortOrder: Value(archived
                  ? (raw['sortOrder'] is int ? raw['sortOrder'] as int : 0)
                  : await _db.nextTaskSortOrder()),
              createdAt: Value(createdAt),
              completedAt: Value(_parseDate(raw['completedAt'])),
              focusSeconds: Value(raw['focusSeconds'] is int && (raw['focusSeconds'] as int) > 0
                  ? raw['focusSeconds'] as int
                  : 0),
            ));
        if (!archived) activeCount++;
        tasksAdded++;
      }

      final sessionKeys = {
        for (final s in await _sessions())
          '${_seconds(s.startedAt)}|${s.targetMinutes}|${s.elapsedSeconds}|${s.isLockdownOnly}',
      };
      for (final raw in sessionsIn) {
        final startedAt = raw is Map ? _parseDate(raw['startedAt']) : null;
        final target = raw is Map ? raw['targetMinutes'] : null;
        final elapsed = raw is Map ? raw['elapsedSeconds'] : null;
        if (raw is! Map || startedAt == null || target is! int || elapsed is! int ||
            target < 1 || target > 600 || elapsed < 0 || elapsed > 24 * 3600) {
          sessionsSkipped++;
          continue;
        }
        final lockdownOnly = raw['isLockdownOnly'] == true;
        final key = '${_seconds(startedAt)}|$target|$elapsed|$lockdownOnly';
        if (!sessionKeys.add(key)) {
          sessionsSkipped++;
          continue;
        }
        await _db.into(_db.timerSessions).insert(TimerSessionsCompanion.insert(
              targetMinutes: target,
              elapsedSeconds: elapsed,
              isFinished: Value(raw['isFinished'] == true),
              isLockdownOnly: Value(lockdownOnly),
              startedAt: Value(startedAt),
              finishedAt: Value(_parseDate(raw['finishedAt'])),
              taskId: Value(_taskRef(raw['task'], taskIdByKey)),
            ));
        sessionsAdded++;
      }

      return RestoreResult(
        sessionsAdded: sessionsAdded,
        sessionsSkipped: sessionsSkipped,
        tasksAdded: tasksAdded,
        tasksSkipped: tasksSkipped,
      );
    });
  }

  /// Saves through the system picker. true = saved, null = the user cancelled.
  Future<bool?> _save(String fileName, String mimeType, String content) async {
    final res = await channel.invokeMethod<bool>('saveFile', {
      'fileName': fileName,
      'mimeType': mimeType,
      'content': content,
    });
    return res;
  }

  Future<bool?> exportCsv({DateTime? now}) async =>
      _save('zykl-sessions-${_date(now ?? DateTime.now())}.csv', 'text/csv', await buildCsv());

  Future<bool?> exportBackup({DateTime? now}) async => _save(
        'zykl-backup-${_date(now ?? DateTime.now())}.json',
        'application/json',
        await buildJson(now: now),
      );

  /// Lets the user pick a backup and merges it. null = cancelled.
  Future<RestoreResult?> pickAndRestore() async {
    final text = await channel.invokeMethod<String>('openFile');
    if (text == null) return null;
    return restoreJson(text);
  }
}
