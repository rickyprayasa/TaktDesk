import 'package:flutter/material.dart';
import '../../../../app/theme/takt_colors.dart';

/// An interactive 3D mechanical push-button crown modeled after classic Braun stopwatches.
///
/// Features 3 distinct physical positions:
/// - Position 0 (Normal / Flush): Sits flush against dial socket at top 12.0, collar height 4px.
/// - Position 1 (Start / Pressed): Depressed 4px into collar at top 16.0 when timer is running.
/// - Position 2 (Pulled Out): Crown cap elevates upward by 8px to top 4.0 with [Curves.easeOutBack] (160ms),
///   revealing an 8px polished metallic stem shaft.
///
/// Supports vertical drag gesture detection:
/// - Dragging up (dy < -8) invokes [onPullOut].
/// - Dragging down (dy > 8) invokes [onPushIn].
/// - Tapping invokes [onTap].
class CrownPushButton extends StatefulWidget {
  final bool isPressed;
  final bool isPulledOut;
  final VoidCallback onTap;
  final VoidCallback? onPullOut;
  final VoidCallback? onPushIn;
  final List<Color>? gradientColors;
  final Color? borderColor;
  final Color? stemColor;

  const CrownPushButton({
    super.key,
    required this.isPressed,
    this.isPulledOut = false,
    required this.onTap,
    this.onPullOut,
    this.onPushIn,
    this.gradientColors,
    this.borderColor,
    this.stemColor,
  });

  @override
  State<CrownPushButton> createState() => _CrownPushButtonState();
}

class _CrownPushButtonState extends State<CrownPushButton>
    with TickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _pressAnimation;

  late final AnimationController _pullController;
  late final Animation<double> _pullAnimation;

  double _dragOffsetY = 0.0;
  bool _dragTriggered = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _pressAnimation = Tween<double>(begin: 0.0, end: 4.0).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    if (widget.isPressed) {
      _pressController.value = 1.0;
    }

    _pullController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _pullAnimation = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(
        parent: _pullController,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      ),
    );

    if (widget.isPulledOut) {
      _pullController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant CrownPushButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPressed != oldWidget.isPressed) {
      if (widget.isPressed) {
        _pressController.forward();
      } else {
        _pressController.reverse();
      }
    }
    if (widget.isPulledOut != oldWidget.isPulledOut) {
      if (widget.isPulledOut) {
        _pullController.forward();
      } else {
        _pullController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _pullController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _pressController.forward().then((_) {
      if (mounted && !widget.isPressed) {
        _pressController.reverse();
      }
    });
    widget.onTap();
  }

  void _handleDragStart(DragStartDetails details) {
    _dragOffsetY = 0.0;
    _dragTriggered = false;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _dragOffsetY += details.delta.dy;
    if (!_dragTriggered) {
      if (_dragOffsetY < -8.0) {
        _dragTriggered = true;
        widget.onPullOut?.call();
      } else if (_dragOffsetY > 8.0) {
        _dragTriggered = true;
        widget.onPushIn?.call();
      }
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_dragTriggered && details.primaryVelocity != null) {
      if (details.primaryVelocity! < -200) {
        _dragTriggered = true;
        widget.onPullOut?.call();
      } else if (details.primaryVelocity! > 200) {
        _dragTriggered = true;
        widget.onPushIn?.call();
      }
    }
  }

  void _handleDragCancel() {
    _dragOffsetY = 0.0;
    _dragTriggered = false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onVerticalDragStart: _handleDragStart,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      onVerticalDragCancel: _handleDragCancel,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 36,
        height: 28,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Stem Collar (stationary on bezel socket)
            Positioned(
              bottom: 0,
              child: Container(
                key: const Key('crown_stem_collar'),
                width: 14,
                height: 4,
                decoration: BoxDecoration(
                  color: widget.stemColor ?? const Color(0xFF181A1D),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(1)),
                ),
              ),
            ),
            // Polished Metallic Stem Shaft (revealed when pulled out)
            Positioned(
              bottom: 4,
              child: Container(
                key: const Key('crown_stem_shaft'),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF7A7E85),
                      Color(0xFFE5E8EC),
                      Color(0xFFA0A5AC),
                      Color(0xFF5A5E65),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(1)),
                  border: Border.all(
                    color: const Color(0xFF40454D),
                    width: 0.5,
                  ),
                ),
              ),
            ),
            // Crown Cap with ribbed knurling lines (elevates when pulled out, depresses when pressed)
            AnimatedBuilder(
              animation: Listenable.merge([_pressAnimation, _pullAnimation]),
              builder: (context, child) {
                return Positioned(
                  top: 12.0 + _pressAnimation.value + _pullAnimation.value,
                  child: child!,
                );
              },
              child: Container(
                key: const Key('crown_cap'),
                width: 32,
                height: 12,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: widget.gradientColors ?? const [
                      Color(0xFF424750),
                      Color(0xFF2A2D33),
                      Color(0xFF1E2125),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  border: Border.all(
                    color: widget.borderColor ?? TaktColors.slateBorder,
                    width: 1.0,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      offset: Offset(0, 3),
                      blurRadius: 4.0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    5,
                    (index) => Container(
                      width: 1.5,
                      height: 8,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
