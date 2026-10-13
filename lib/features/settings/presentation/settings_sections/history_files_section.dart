part of '../takt_settings_sheet.dart';

// Focus history to and from files: CSV for spreadsheets, a JSON backup that restores (merges) on any phone.

class _HistoryFilesControls extends ConsumerStatefulWidget {
  final bool isDark;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color borderColor;

  const _HistoryFilesControls({
    required this.isDark,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.borderColor,
  });

  @override
  ConsumerState<_HistoryFilesControls> createState() => _HistoryFilesControlsState();
}

class _HistoryFilesControlsState extends ConsumerState<_HistoryFilesControls> {
  String? _status;
  bool _busy = false;

  Future<void> _run(Future<String?> Function(HistoryBackup backup) job) async {
    if (_busy) return;
    HapticService.selectionClick();
    setState(() => _busy = true);
    String? status;
    try {
      status = await job(ref.read(historyBackupProvider));
    } on BackupFormatException catch (e) {
      status = e.message;
    } catch (_) {
      status = 'Could not access the file. Try another location.';
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (status != null) _status = status;
    });
  }

  Widget _button(String label, Key key, VoidCallback onPressed) {
    return Expanded(
      child: OutlinedButton(
        key: key,
        style: OutlinedButton.styleFrom(
          foregroundColor: widget.primaryTextColor,
          side: BorderSide(color: widget.borderColor, width: 1.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        ),
        onPressed: _busy ? null : onPressed,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'HISTORY FILES',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: widget.primaryTextColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Export your sessions as CSV, or save a backup and restore it on any phone. A restore only adds what is missing.',
          style: TextStyle(fontFamily: 'monospace', fontSize: 9.0, color: widget.secondaryTextColor),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _button('EXPORT CSV', const ValueKey('history_export_csv'), () => _run((b) async {
                  final saved = await b.exportCsv();
                  return saved == true ? 'Sessions exported as CSV.' : null;
                })),
            const SizedBox(width: 6),
            _button('BACKUP', const ValueKey('history_backup'), () => _run((b) async {
                  final saved = await b.exportBackup();
                  return saved == true ? 'Backup saved.' : null;
                })),
            const SizedBox(width: 6),
            _button('RESTORE', const ValueKey('history_restore'), () => _run((b) async {
                  final r = await b.pickAndRestore();
                  if (r == null) return null;
                  // The dispenser keeps its slips in memory: show the restored ones (and let it count them, or a new
                  // slip would be refused by the database and lost).
                  if (r.tasksAdded > 0) await ref.read(receiptRunnerProvider.notifier).reloadFromDatabase();
                  final skipped = r.sessionsSkipped + r.tasksSkipped;
                  return 'Restored ${r.sessionsAdded} sessions and ${r.tasksAdded} slips'
                      '${skipped > 0 ? ' ($skipped already here or skipped)' : ''}.';
                })),
          ],
        ),
        if (_status != null) ...[
          const SizedBox(height: 6),
          Text(
            _status!,
            key: const ValueKey('history_files_status'),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9.5,
              color: TaktColors.amberText(widget.isDark),
            ),
          ),
        ],
      ],
    );
  }
}
