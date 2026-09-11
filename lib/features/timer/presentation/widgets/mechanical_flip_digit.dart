import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/takt_colors.dart';

/// A clean, mechanical 3D flip/roll digit transition inspired by classic odometers.
class MechanicalFlipDigit extends StatelessWidget {
  final String digit;
  final TextStyle style;

  const MechanicalFlipDigit({
    super.key,
    required this.digit,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final rotate = Tween<double>(begin: math.pi / 2, end: 0.0).animate(animation);
        return AnimatedBuilder(
          animation: rotate,
          child: child,
          builder: (context, child) {
            final isIncoming = child?.key == ValueKey<String>(digit);
            final angle = isIncoming ? rotate.value : -rotate.value;
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.004) // perspective
                ..rotateX(angle),
              alignment: Alignment.center,
              child: child,
            );
          },
        );
      },
      child: Container(
        key: ValueKey<String>(digit),
        alignment: Alignment.center,
        child: Text(digit, style: style),
      ),
    );
  }
}

/// Recessed dual-digit counter with debossed mechanical housing.
class MechanicalCounterDisplay extends StatelessWidget {
  final int minutes;
  final int seconds;

  const MechanicalCounterDisplay({
    super.key,
    required this.minutes,
    required this.seconds,
  });

  @override
  Widget build(BuildContext context) {
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');

    const digitStyle = TextStyle(
      fontFamily: 'monospace',
      fontWeight: FontWeight.w700,
      fontSize: 14.0,
      letterSpacing: 0.5,
      color: TaktColors.warmBone,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF101214),
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: const Color(0xFF2E3238), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0xCC000000),
            offset: Offset(0, 2),
            blurRadius: 4.0,
            spreadRadius: -1.0,
          ),
          BoxShadow(
            color: Color(0x33FFFFFF),
            offset: Offset(0, -0.8),
            blurRadius: 0.5,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MechanicalFlipDigit(digit: mStr[0], style: digitStyle),
          MechanicalFlipDigit(digit: mStr[1], style: digitStyle),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 1.5),
            child: Text(
              ':',
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                fontSize: 13.0,
                color: TaktColors.mutedOchre,
              ),
            ),
          ),
          MechanicalFlipDigit(digit: sStr[0], style: digitStyle),
          MechanicalFlipDigit(digit: sStr[1], style: digitStyle),
        ],
      ),
    );
  }
}
