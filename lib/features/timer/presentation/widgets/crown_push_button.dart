import 'package:flutter/material.dart';
import '../../../../app/theme/takt_colors.dart';

/// An interactive 3D mechanical push-button crown modeled after classic Braun stopwatches.
class CrownPushButton extends StatefulWidget {
  final bool isPressed;
  final VoidCallback onTap;
  final List<Color>? gradientColors;
  final Color? borderColor;
  final Color? stemColor;

  const CrownPushButton({
    super.key,
    required this.isPressed,
    required this.onTap,
    this.gradientColors,
    this.borderColor,
    this.stemColor,
  });

  @override
  State<CrownPushButton> createState() => _CrownPushButtonState();
}

class _CrownPushButtonState extends State<CrownPushButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _pressAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _pressAnimation = Tween<double>(begin: 0.0, end: 4.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    if (widget.isPressed) {
      _animController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant CrownPushButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPressed != oldWidget.isPressed) {
      if (widget.isPressed) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _animController.forward().then((_) {
      if (mounted && !widget.isPressed) {
        _animController.reverse();
      }
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _pressAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _pressAnimation.value),
            child: child,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Crown Cap with ribbed knurling lines
            Container(
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
            // Stem Collar
            Container(
              width: 14,
              height: 4,
              color: widget.stemColor ?? const Color(0xFF181A1D),
            ),
          ],
        ),
      ),
    );
  }
}
