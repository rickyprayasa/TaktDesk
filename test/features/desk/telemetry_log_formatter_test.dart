import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/database/app_database.dart';
import 'package:takt_desk/features/desk/domain/telemetry_log_formatter.dart';

void main() {
  group('TelemetryLogFormatter', () {
    test('formats completed and interrupted sessions correctly', () {
      final startTime = DateTime(2026, 9, 10, 14, 0);
      final finishTime1 = DateTime(2026, 9, 10, 14, 25);
      final finishTime2 = DateTime(2026, 9, 10, 15, 15);

      final session1 = TimerSession(
        isLockdownOnly: false,
        id: 1,
        targetMinutes: 25,
        elapsedSeconds: 1500,
        isFinished: true,
        startedAt: startTime,
        finishedAt: finishTime1,
      );

      final session2 = TimerSession(
        isLockdownOnly: false,
        id: 2,
        targetMinutes: 25,
        elapsedSeconds: 900,
        isFinished: false,
        startedAt: startTime,
        finishedAt: finishTime2,
      );

      final entry1 = TelemetryLogFormatter.formatSessionEntry(1, session1);
      expect(entry1, contains('#01'));
      expect(entry1, contains('14:00 - 14:25'));
      expect(entry1, contains('[25 MIN]'));
      expect(entry1, contains('STATUS: COMPLETED'));

      final entry2 = TelemetryLogFormatter.formatSessionEntry(2, session2);
      expect(entry2, contains('#02'));
      expect(entry2, contains('[15/25 MIN]'));
      expect(entry2, contains('STATUS: INTERRUPTED'));
    });

    test('formats session with null finishedAt by deriving finish time from elapsedSeconds', () {
      final startTime = DateTime(2026, 9, 10, 14, 0);
      final session = TimerSession(
        isLockdownOnly: false,
        id: 3,
        targetMinutes: 25,
        elapsedSeconds: 600,
        isFinished: false,
        startedAt: startTime,
        finishedAt: null,
      );

      final entry = TelemetryLogFormatter.formatSessionEntry(3, session);
      expect(entry, contains('#03'));
      expect(entry, contains('14:00 - 14:10'));
      expect(entry, contains('[10/25 MIN]'));
      expect(entry, contains('STATUS: INTERRUPTED'));
    });

    test('formats summary calculations accurately', () {
      final startTime = DateTime(2026, 9, 10, 14, 0);
      final sessions = [
        TimerSession(
          isLockdownOnly: false,
          id: 1,
          targetMinutes: 25,
          elapsedSeconds: 1500,
          isFinished: true,
          startedAt: startTime,
          finishedAt: startTime,
        ),
        TimerSession(
          isLockdownOnly: false,
          id: 2,
          targetMinutes: 25,
          elapsedSeconds: 1500,
          isFinished: false,
          startedAt: startTime,
          finishedAt: startTime,
        ),
      ];

      final summary = TelemetryLogFormatter.formatSummary(sessions);
      expect(summary, contains('SUMMARY : 1 CYCLES · 50 MIN'));
      expect(summary, contains('RATE    : 50% FOCUS EFFICIENCY'));
    });

    test('formats empty summary with zero rate and zero minutes safely', () {
      final summary = TelemetryLogFormatter.formatSummary([]);
      expect(summary, contains('SUMMARY : 0 CYCLES · 0 MIN'));
      expect(summary, contains('RATE    : 0% FOCUS EFFICIENCY'));
    });

    test('formats empty sessions list with graceful standby notice', () {
      final log = TelemetryLogFormatter.formatFullAuditLog(
        editionTitle: 'MODERNIST CLASSIC',
        yearLabel: 'MOD. 01 · 1960',
        date: DateTime(2026, 9, 10),
        sessions: [],
      );

      expect(log, contains('ZYKL // SESSION TELEMETRY'));
      expect(log, contains('MODERNIST CLASSIC · 1960'));
      expect(log, contains('DATE    : 2026-09-10'));
      expect(log, contains('NO SESSIONS RECORDED TODAY'));
      expect(log, contains('STANDBY // COMMENCE CHRONO DIAL'));
    });

    test('formats full audit log with multiple sessions and divider lines', () {
      final startTime1 = DateTime(2026, 9, 10, 9, 15);
      final finishTime1 = DateTime(2026, 9, 10, 9, 40);
      final startTime2 = DateTime(2026, 9, 10, 10, 0);
      final finishTime2 = DateTime(2026, 9, 10, 10, 25);

      final sessions = [
        TimerSession(
          isLockdownOnly: false,
          id: 1,
          targetMinutes: 25,
          elapsedSeconds: 1500,
          isFinished: true,
          startedAt: startTime1,
          finishedAt: finishTime1,
        ),
        TimerSession(
          isLockdownOnly: false,
          id: 2,
          targetMinutes: 25,
          elapsedSeconds: 1500,
          isFinished: true,
          startedAt: startTime2,
          finishedAt: finishTime2,
        ),
      ];

      final log = TelemetryLogFormatter.formatFullAuditLog(
        editionTitle: 'MODERNIST CLASSIC',
        yearLabel: 'MOD. 01 · 1960',
        date: DateTime(2026, 9, 10),
        sessions: sessions,
      );

      expect(log, contains('================================'));
      expect(log, contains('ZYKL // SESSION TELEMETRY'));
      expect(log, contains('EDITION : MODERNIST CLASSIC · 1960'));
      expect(log, contains('SUMMARY : 2 CYCLES · 50 MIN'));
      expect(log, contains('RATE    : 100% FOCUS EFFICIENCY'));
      expect(log, contains('#01  09:15 - 09:40  [25 MIN]'));
      expect(log, contains('STATUS: COMPLETED ●'));
      expect(log, contains('--------------------------------'));
      expect(log, contains('#02  10:00 - 10:25  [25 MIN]'));
    });
  });
}
