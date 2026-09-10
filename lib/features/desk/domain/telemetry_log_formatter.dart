import '../../../core/database/app_database.dart';

class TelemetryLogFormatter {
  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String formatSessionEntry(int index, TimerSession session) {
    final numStr = index.toString().padLeft(2, '0');
    final startStr = _formatTime(session.startedAt);
    final finishTime = session.finishedAt ??
        session.startedAt.add(Duration(seconds: session.elapsedSeconds));
    final finishStr = _formatTime(finishTime);
    final elapsedMin = (session.elapsedSeconds / 60).round();

    final durationStr = session.isFinished
        ? '[$elapsedMin MIN]'
        : '[$elapsedMin/${session.targetMinutes} MIN]';
    final statusStr = session.isFinished
        ? 'STATUS: COMPLETED ●'
        : 'STATUS: INTERRUPTED ○';

    return '#$numStr  $startStr - $finishStr  $durationStr\n     $statusStr';
  }

  static String formatSummary(List<TimerSession> sessions) {
    final completedCount = sessions.where((s) => s.isFinished).length;
    final totalSeconds = sessions.fold<int>(0, (sum, s) => sum + s.elapsedSeconds);
    final totalMinutes = (totalSeconds / 60).round();
    final rate = sessions.isEmpty
        ? 0
        : ((completedCount / sessions.length) * 100).round();

    return 'SUMMARY : $completedCount CYCLES · $totalMinutes MIN\nRATE    : $rate% FOCUS EFFICIENCY';
  }

  static String formatFullAuditLog({
    required String editionTitle,
    required String yearLabel,
    required DateTime date,
    required List<TimerSession> sessions,
  }) {
    final dateStr = _formatDate(date);
    final cleanYear = yearLabel.split('·').last.replaceAll('MOD.', '').trim();

    final buffer = StringBuffer();
    buffer.writeln('================================');
    buffer.writeln('TAKT DESK // SESSION TELEMETRY');
    buffer.writeln('EDITION : $editionTitle · $cleanYear');
    buffer.writeln('DATE    : $dateStr');
    buffer.writeln('================================');
    buffer.writeln(formatSummary(sessions));
    buffer.writeln('--------------------------------');
    buffer.writeln('LOG ENTRIES:');

    if (sessions.isEmpty) {
      buffer.writeln('[ NO SESSIONS RECORDED TODAY ]');
      buffer.writeln('STANDBY // COMMENCE CHRONO DIAL');
    } else {
      for (int i = 0; i < sessions.length; i++) {
        buffer.writeln(formatSessionEntry(i + 1, sessions[i]));
        if (i < sessions.length - 1) {
          buffer.writeln('--------------------------------');
        }
      }
    }
    buffer.writeln('================================');
    return buffer.toString();
  }
}
