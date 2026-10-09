import 'package:flutter/material.dart';
import '../../domain/receipt_task.dart';
import '../receipt_runner_painter.dart';
import 'physical_ink_stamp.dart';
import '../../../../app/theme/takt_colors.dart';
import '../../../../app/theme/takt_typography.dart';

/// A physical thermal paper receipt strip with 3D extrusion, tear peel tilt, and ink stamp.
class AnimatedReceiptStrip extends StatefulWidget {
  final ReceiptTask task;
  final int index;
  final ValueChanged<double> onTearUpdate;
  final VoidCallback onTorn;
  final VoidCallback onStampToggle;

  /// The top open slip: the next focus session counts for it ("NOW").
  final bool isCurrent;

  /// Minutes focused on this slip so far.
  final int focusMinutes;

  const AnimatedReceiptStrip({
    super.key,
    required this.task,
    required this.index,
    this.isCurrent = false,
    this.focusMinutes = 0,
    required this.onTearUpdate,
    required this.onTorn,
    required this.onStampToggle,
  });

  @override
  State<AnimatedReceiptStrip> createState() => _AnimatedReceiptStripState();
}

class _AnimatedReceiptStripState extends State<AnimatedReceiptStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _extrusionController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  double _localTearProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _extrusionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.28),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _extrusionController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _extrusionController,
        curve: Curves.easeIn,
      ),
    );

  }

  bool _extrusionStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_extrusionStarted) return;
    _extrusionStarted = true;
    // Reduce motion: the slip is simply there, no slide-out from the printer.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _extrusionController.value = 1.0;
    } else {
      _extrusionController.forward();
    }
  }

  @override
  void dispose() {
    _extrusionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Listener(
          onPointerUp: (_) {
            if (_localTearProgress > 0) {
              setState(() {
                _localTearProgress = 0.0;
              });
              widget.onTearUpdate(0.0);
            }
          },
          onPointerCancel: (_) {
            if (_localTearProgress > 0) {
              setState(() {
                _localTearProgress = 0.0;
              });
              widget.onTearUpdate(0.0);
            }
          },
          child: Dismissible(
            key: Key(widget.task.id),
            direction: DismissDirection.horizontal,
            dismissThresholds: const {
              DismissDirection.startToEnd: 0.60,
              DismissDirection.endToStart: 0.60,
            },
            onUpdate: (details) {
              setState(() {
                _localTearProgress = details.progress;
              });
              widget.onTearUpdate(details.progress);
            },
            onDismissed: (_) {
              widget.onTorn();
            },
            child: Semantics(
              hint: 'Double tap to stamp as done. Swipe to tear off.',
              onTap: widget.onStampToggle,
              child: GestureDetector(
              onDoubleTap: widget.onStampToggle,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x38000000),
                      offset: Offset(0, 3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: CustomPaint(
                  // Only this strip's own drag: a shared progress made every slip show the tear line.
                  painter: ReceiptRunnerPainter(tearProgress: _localTearProgress),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Receipt Micro Header with Quick Tear Action
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '#${(widget.index + 1).toString().padLeft(2, '0')} // '
                              '${widget.isCurrent ? 'NOW' : 'ZYKL'}'
                              '${widget.focusMinutes > 0 ? ' · ${widget.focusMinutes} MIN' : ''}',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 8.5,
                                fontWeight: FontWeight.w600,
                                color: TaktColors.thermalCarbon.withValues(alpha: 0.55),
                                letterSpacing: 0.5,
                              ),
                            ),
                            InkWell(
                              onTap: widget.onTorn,
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                                child: Text(
                                  'TEAR ✕',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 8.0,
                                    fontWeight: FontWeight.w700,
                                    color: TaktColors.thermalCarbon.withValues(alpha: 0.45),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                          const SizedBox(height: 4),
                          // Task Content & Rubber Stamp Mark
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.task.title,
                                  style: TaktTypography.receiptBody.copyWith(
                                    color: widget.task.isDone
                                        ? TaktColors.thermalCarbon.withValues(alpha: 0.60)
                                        : TaktColors.thermalCarbon,
                                    decoration: widget.task.isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: TaktColors.thermalCarbon,
                                    decorationThickness: 1.6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              PhysicalInkStamp(
                                isDone: widget.task.isDone,
                                taskId: widget.task.id,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ),
          ),
        ),
      );
    }
}
