import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/takt_colors.dart';
import '../../../../app/theme/theme_controller.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/audio/sound_effect.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../domain/telemetry_log_formatter.dart';
import '../../../analytics/presentation/widgets/focus_analytics_dialog.dart';
export 'desk_telemetry_dialog.dart';

/// Stream provider for observing today's focus timer sessions.
final todayTimerSessionsStreamProvider = StreamProvider<List<TimerSession>>((ref) {
  return ref.watch(appDatabaseProvider).watchTodayTimerSessions();
});

/// Tactile thermal paper receipt slip widget displaying dot-matrix focus telemetry.
///
/// Features authentic procedural serrated sawtooth bottom edge,
/// scrollable dot-matrix session entries, and one-tap audit log export to the
/// system clipboard.
class DeskTelemetrySlipWidget extends ConsumerStatefulWidget {
  final VoidCallback? onClose;
  final VoidCallback? onRetract;
  final bool isExpanded;

  const DeskTelemetrySlipWidget({
    super.key,
    this.onClose,
    this.onRetract,
    this.isExpanded = true,
  });

  @override
  ConsumerState<DeskTelemetrySlipWidget> createState() => _DeskTelemetrySlipWidgetState();
}

class _DeskTelemetrySlipWidgetState extends ConsumerState<DeskTelemetrySlipWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _animation;
  bool _isCopied = false;
  Timer? _copyTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: widget.isExpanded ? 1.0 : 0.0,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant DeskTelemetrySlipWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpanded != widget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _copyTimer?.cancel();
    _animation.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onCopy(String log) {
    Clipboard.setData(ClipboardData(text: log));
    HapticService.selectionClick();
    ref.read(audioServiceProvider).play(SoundEffect.dialClick);

    _copyTimer?.cancel();
    setState(() {
      _isCopied = true;
    });
    _copyTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  void _onClose() {
    HapticService.selectionClick();
    ref.read(audioServiceProvider).play(SoundEffect.dialClick);
    if (widget.onClose != null) {
      widget.onClose!();
    } else if (widget.onRetract != null) {
      widget.onRetract!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(chassisThemeProvider);
    final isDark = themeState.isDarkMode;
    final sessionsAsync = ref.watch(todayTimerSessionsStreamProvider);
    final sessions = sessionsAsync.valueOrNull ?? const <TimerSession>[];

    // Authentic thermal receipt paper retains an off-white ivory/warm bone finish in both dark & light modes
    const paperColor = Color(0xFFF5F3EB);
    const borderColor = Color(0xFFD5D1C8);
    const inkColor = TaktColors.thermalCarbon;

    final fullLog = TelemetryLogFormatter.formatFullAuditLog(
      editionTitle: themeState.edition.title,
      yearLabel: themeState.edition.yearLabel,
      date: DateTime.now(),
      sessions: sessions,
    );

    final closeLabel = widget.onRetract != null && widget.onClose == null
        ? '[ RETRACT ▲ ]'
        : '[ CLOSE ✕ ]';

    return SizeTransition(
      sizeFactor: _animation,
      alignment: Alignment.topCenter,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top mechanical paper slot cue
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF16181B) : const Color(0xFFCBC8BE),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3.0)),
                  border: Border.all(
                    color: isDark ? const Color(0xFF383D45) : const Color(0xFFBDB8AD),
                    width: 1.0,
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: paperColor,
                  border: const Border(
                    left: BorderSide(color: borderColor, width: 1.0),
                    right: BorderSide(color: borderColor, width: 1.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.60 : 0.15),
                      blurRadius: 18.0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.55,
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            fullLog,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 8.5,
                              height: 1.38,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                              color: inkColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        key: const ValueKey('telemetry_open_analytics_button'),
                        onTap: () {
                          HapticService.selectionClick();
                          ref.read(audioServiceProvider).play(SoundEffect.dialClick);
                          FocusAnalyticsDialog.show(context);
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                          child: Center(
                            child: Text(
                              '[ 📊 VIEW FOCUS ANALYTICS & CHARTS ➔ ]',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 8.0,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: isDark ? themeState.filamentColor : const Color(0xFFD35400),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: InkWell(
                              key: const ValueKey('telemetry_copy_button'),
                              onTap: () => _onCopy(fullLog),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _isCopied ? '[ COPIED! ]' : '[ COPY TEXT LOG ]',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 8.0,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                      color: _isCopied
                                          ? (isDark ? themeState.filamentColor : const Color(0xFFD35400))
                                          : inkColor.withValues(alpha: 0.75),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: InkWell(
                              key: const ValueKey('telemetry_close_button'),
                              onTap: _onClose,
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    closeLabel,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 8.0,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                      color: inkColor.withValues(alpha: 0.75),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              CustomPaint(
                size: const Size(double.infinity, 6.0),
                painter: _PerforatedSawtoothPainter(
                  paperColor: paperColor,
                  borderColor: borderColor,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Procedural sawtooth bottom edge painter for thermal paper receipt roll.
class _PerforatedSawtoothPainter extends CustomPainter {
  final Color paperColor;
  final Color borderColor;
  final bool isDark;

  const _PerforatedSawtoothPainter({
    required this.paperColor,
    required this.borderColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final toothHeight = size.height;
    final rawTeeth = (size.width / 8.0).floor().clamp(4, 100);
    final teethCount = (rawTeeth ~/ 2) * 2;
    final effectiveToothWidth = size.width / teethCount;

    final fillPath = Path()..moveTo(0, 0);
    fillPath.lineTo(size.width, 0);

    final borderPath = Path()..moveTo(size.width, 0);

    for (int i = teethCount - 1; i >= 0; i--) {
      final x = i * effectiveToothWidth;
      final y = (i % 2 == 1) ? toothHeight : 0.0;
      fillPath.lineTo(x, y);
      borderPath.lineTo(x, y);
    }
    fillPath.close();

    // Subtle drop shadow for sawtooth teeth
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.35 : 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawPath(fillPath.shift(const Offset(0, 1.5)), shadowPaint);

    final fillPaint = Paint()
      ..color = paperColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _PerforatedSawtoothPainter oldDelegate) {
    return oldDelegate.paperColor != paperColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.isDark != isDark;
  }
}
