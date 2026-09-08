import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../app/theme/takt_colors.dart';

/// Single mechanical split-flap card tile with 3D perspective flip animation.
class SplitFlapTile extends StatefulWidget {
  final String char;
  final double width;
  final double height;

  const SplitFlapTile({
    super.key,
    required this.char,
    this.width = 16,
    this.height = 24,
  });

  @override
  State<SplitFlapTile> createState() => _SplitFlapTileState();
}

class _SplitFlapTileState extends State<SplitFlapTile> with SingleTickerProviderStateMixin {
  late final AnimationController _flipController;
  late String _prevChar;
  late String _currentChar;

  @override
  void initState() {
    super.initState();
    _prevChar = widget.char;
    _currentChar = widget.char;
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void didUpdateWidget(covariant SplitFlapTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.char != widget.char) {
      _prevChar = oldWidget.char;
      _currentChar = widget.char;
      _flipController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flipController,
      builder: (context, _) {
        final progress = _flipController.value;
        final displayChar = progress < 0.5 ? _prevChar : _currentChar;
        final angle = progress * math.pi;

        return Container(
          width: widget.width,
          height: widget.height,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: const Color(0xFF141619),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: const Color(0xFF282C33), width: 0.8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                offset: Offset(0, 1.5),
                blurRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Character Display
              Center(
                child: Text(
                  displayChar,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: widget.height * 0.55,
                    fontWeight: FontWeight.w800,
                    color: TaktColors.warmBone,
                    letterSpacing: 0,
                  ),
                ),
              ),
              // 3D Flip Fold Overlay (perspective rotation on center horizontal line)
              if (_flipController.isAnimating)
                Positioned.fill(
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0025)
                      ..rotateX(angle),
                    child: Container(
                      color: Colors.black.withValues(
                        alpha: (math.sin(angle) * 0.4).clamp(0.0, 0.4),
                      ),
                    ),
                  ),
                ),
              // Horizontal Split Center Seam
              Center(
                child: Container(
                  height: 1.0,
                  color: const Color(0xFF090A0C),
                ),
              ),
              // Left & Right Pivot Rivet Pins
              Positioned(
                left: 0,
                top: widget.height / 2 - 1.5,
                child: Container(
                  width: 2,
                  height: 3,
                  decoration: const BoxDecoration(
                    color: Color(0xFF424750),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(1),
                      bottomRight: Radius.circular(1),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: widget.height / 2 - 1.5,
                child: Container(
                  width: 2,
                  height: 3,
                  decoration: const BoxDecoration(
                    color: Color(0xFF424750),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(1),
                      bottomLeft: Radius.circular(1),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
