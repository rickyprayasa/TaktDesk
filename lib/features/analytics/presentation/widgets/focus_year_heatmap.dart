import 'package:flutter/material.dart';

import '../../../../app/theme/takt_colors.dart';

const List<String> _monthNames = [
  'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
  'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
];

/// A year at a glance (Studio PRO): one row per month, one cell per day, lit amber by the minutes focused that day.
/// Tapping a cell reads out its date and focus time under the grid.
class FocusYearHeatmap extends StatefulWidget {
  final int year;

  /// Focus minutes per day, index 0 = 1 January.
  final List<int> minutes;

  /// Today's index in [minutes], -1 when another year is shown.
  final int todayIndex;
  final bool isDark;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  /// false for the locked teaser: no taps, no read-out.
  final bool interactive;

  const FocusYearHeatmap({
    super.key,
    required this.year,
    required this.minutes,
    required this.todayIndex,
    required this.isDark,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    this.interactive = true,
  });

  /// 0 = nothing, then under one cycle, one cycle, two cycles, four cycles and more (25-minute cycles).
  static int levelOf(int minutes) => minutes <= 0
      ? 0
      : minutes < 25
          ? 1
          : minutes < 50
              ? 2
              : minutes < 100
                  ? 3
                  : 4;

  static Color levelColor(int level, bool isDark) => level == 0
      ? (isDark ? const Color(0xFF23272C) : const Color(0xFFD3CFC5))
      : TaktColors.filamentAmber.withValues(alpha: const [0.0, 0.3, 0.52, 0.76, 1.0][level]);

  @override
  State<FocusYearHeatmap> createState() => _FocusYearHeatmapState();
}

class _FocusYearHeatmapState extends State<FocusYearHeatmap> {
  static const double _labelWidth = 22;
  static const double _gap = 1.5;

  int? _selected;

  @override
  void didUpdateWidget(FocusYearHeatmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.year != widget.year) _selected = null;
  }

  static int _daysIn(int year, int month) => DateTime(year, month + 1, 0).day;

  /// Day index of (month 1..12, day) in the year.
  int _indexOf(int month, int day) =>
      DateTime.utc(widget.year, month, day).difference(DateTime.utc(widget.year, 1, 1)).inDays;

  DateTime _dateOf(int index) => DateTime(widget.year, 1, 1 + index);

  static String _duration(int minutes) {
    if (minutes <= 0) return 'NO FOCUS';
    final h = minutes ~/ 60, m = minutes % 60;
    if (h == 0) return '${m}m';
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  void _tap(Offset local, double cell) {
    final pitch = cell + _gap;
    final col = (local.dx / pitch).floor();
    final row = (local.dy / pitch).floor();
    if (row < 0 || row > 11 || col < 0 || col > 30) return;
    final day = col + 1;
    if (day > _daysIn(widget.year, row + 1)) return;
    final index = _indexOf(row + 1, day);
    if (index >= widget.minutes.length) return;
    setState(() => _selected = _selected == index ? null : index);
  }

  @override
  Widget build(BuildContext context) {
    final focusDays = widget.minutes.where((m) => m > 0).length;
    final labelStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 7.0,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: widget.secondaryTextColor,
    );
    final trackBorder = widget.isDark ? TaktColors.slateBorder : TaktColors.lightChassisBorder;

    return Container(
      key: const ValueKey('analytics_year_heatmap'),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF14171A) : const Color(0xFFE4E0D6),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: trackBorder, width: 0.8),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final gridWidth = constraints.maxWidth - _labelWidth;
        final cell = ((gridWidth - _gap * 30) / 31).clamp(3.0, 14.0);
        final pitch = cell + _gap;
        final gridHeight = pitch * 12 - _gap;
        final selected = _selected;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              label: '${widget.year} year heatmap: $focusDays days with focus',
              child: ExcludeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: _labelWidth,
                      height: gridHeight,
                      child: Stack(children: [
                        for (var m = 0; m < 12; m++)
                          Positioned(
                            top: m * pitch,
                            height: cell,
                            left: 0,
                            right: 0,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(_monthNames[m], style: labelStyle),
                            ),
                          ),
                      ]),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: widget.interactive ? (d) => _tap(d.localPosition, cell) : null,
                        child: CustomPaint(
                          size: Size(double.infinity, gridHeight),
                          painter: _HeatmapPainter(
                            year: widget.year,
                            minutes: widget.minutes,
                            todayIndex: widget.todayIndex,
                            selectedIndex: selected,
                            cell: cell,
                            gap: _gap,
                            isDark: widget.isDark,
                            selectedColor: widget.primaryTextColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      selected == null || selected >= widget.minutes.length
                          ? (widget.interactive ? 'TAP A DAY' : '')
                          : '${_dateOf(selected).day} ${_monthNames[_dateOf(selected).month - 1]} · '
                              '${_duration(widget.minutes[selected])}',
                      key: const ValueKey('analytics_heatmap_readout'),
                      style: labelStyle.copyWith(
                        fontSize: 8.0,
                        color: selected == null ? widget.secondaryTextColor : TaktColors.amberText(widget.isDark),
                        fontWeight: selected == null ? FontWeight.w600 : FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                ExcludeSemantics(
                  child: Row(children: [
                    Text('LESS ', style: labelStyle),
                    for (var l = 0; l <= 4; l++)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 2),
                        decoration: BoxDecoration(
                          color: FocusYearHeatmap.levelColor(l, widget.isDark),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    Text(' MORE', style: labelStyle),
                  ]),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  final int year;
  final List<int> minutes;
  final int todayIndex;
  final int? selectedIndex;
  final double cell;
  final double gap;
  final bool isDark;
  final Color selectedColor;

  _HeatmapPainter({
    required this.year,
    required this.minutes,
    required this.todayIndex,
    required this.selectedIndex,
    required this.cell,
    required this.gap,
    required this.isDark,
    required this.selectedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint();
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final radius = Radius.circular(cell * 0.2);
    final pitch = cell + gap;
    final empty = FocusYearHeatmap.levelColor(0, isDark);
    var index = 0;
    for (var m = 0; m < 12; m++) {
      final days = DateTime(year, m + 2, 0).day;
      for (var d = 0; d < days; d++, index++) {
        final rect = RRect.fromRectAndRadius(Rect.fromLTWH(d * pitch, m * pitch, cell, cell), radius);
        final mins = index < minutes.length ? minutes[index] : 0;
        final future = todayIndex >= 0 && index > todayIndex;
        fill.color = future
            ? empty.withValues(alpha: 0.45)
            : FocusYearHeatmap.levelColor(FocusYearHeatmap.levelOf(mins), isDark);
        canvas.drawRRect(rect, fill);
        if (index == todayIndex) {
          canvas.drawRRect(rect.deflate(0.5), ring..color = TaktColors.filamentAmber);
        }
        if (index == selectedIndex) {
          canvas.drawRRect(rect.deflate(0.5), ring..color = selectedColor);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_HeatmapPainter old) =>
      old.year != year ||
      !identical(old.minutes, minutes) ||
      old.todayIndex != todayIndex ||
      old.selectedIndex != selectedIndex ||
      old.cell != cell ||
      old.isDark != isDark ||
      old.selectedColor != selectedColor;
}
