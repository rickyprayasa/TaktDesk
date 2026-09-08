import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/takt_colors.dart';
import '../../../../app/theme/takt_typography.dart';

/// An authentic physical rubber ink stamp with spring slam animation and organic slant.
class PhysicalInkStamp extends StatefulWidget {
  final bool isDone;
  final String taskId;

  const PhysicalInkStamp({
    super.key,
    required this.isDone,
    required this.taskId,
  });

  @override
  State<PhysicalInkStamp> createState() => _PhysicalInkStampState();
}

class _PhysicalInkStampState extends State<PhysicalInkStamp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _scaleAnimation = Tween<double>(begin: 2.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    if (widget.isDone) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant PhysicalInkStamp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDone != oldWidget.isDone) {
      if (widget.isDone) {
        _controller.forward(from: 0.0);
      } else {
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isDone) {
      return const SizedBox.shrink();
    }

    // Deterministic organic slant based on task id hash (-3.5° to +2.5°)
    final angle = ((widget.taskId.hashCode % 7) - 3.5) * (math.pi / 180.0);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = _scaleAnimation.value;
        return Transform(
          transform: Matrix4.identity()
            ..rotateZ(angle)
            ..multiply(Matrix4.diagonal3Values(scale, scale, 1.0)),
          alignment: Alignment.center,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: TaktColors.patinaOlive.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: TaktColors.patinaOlive, width: 1.8),
          boxShadow: [
            BoxShadow(
              color: TaktColors.patinaOlive.withValues(alpha: 0.25),
              blurRadius: 3,
              spreadRadius: 0.5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '[DONE]',
              style: TaktTypography.receiptHeader.copyWith(
                color: TaktColors.patinaOlive,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              'VERIFIED // TAKT',
              style: TextStyle(
                fontFamily: 'monospace',
                color: TaktColors.patinaOlive.withValues(alpha: 0.8),
                fontSize: 6.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
