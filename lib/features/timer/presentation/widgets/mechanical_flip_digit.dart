import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/takt_colors.dart';

/// A mechanical 3D rolling drum digit transition inspired by precision horological odometers.
class MechanicalFlipDigit extends StatelessWidget {
  final String digit;
  final TextStyle style;
  final double slotWidth;
  final double slotHeight;

  const MechanicalFlipDigit({
    super.key,
    required this.digit,
    required this.style,
    this.slotWidth = 11.0,
    this.slotHeight = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: slotWidth,
      height: slotHeight,
      child: ClipRect(
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 230),
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              transitionBuilder: (Widget child, Animation<double> animation) {
                final isIncoming = child.key == ValueKey<String>(digit);

                // Physical odometer drum cylinder roll:
                // Incoming enters from top (-slotHeight) to 0 with rotational perspective
                // Outgoing exits to bottom (+slotHeight) from 0
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: isIncoming ? Curves.easeOutCubic : Curves.easeInCubic,
                );

                return AnimatedBuilder(
                  animation: curved,
                  child: child,
                  builder: (context, child) {
                    final progress = curved.value;
                    final double translationY;
                    final double angle;

                    if (isIncoming) {
                      translationY = (1.0 - progress) * -slotHeight;
                      angle = (1.0 - progress) * -math.pi / 2.6;
                    } else {
                      translationY = (1.0 - progress) * slotHeight;
                      angle = (1.0 - progress) * math.pi / 2.6;
                    }

                    final opacity = math.cos(angle).clamp(0.0, 1.0);

                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.004) // 3D perspective
                        ..translateByDouble(0.0, translationY, 0.0, 1.0)
                        ..rotateX(angle),
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: opacity,
                        child: child,
                      ),
                    );
                  },
                );
              },
              child: Container(
                key: ValueKey<String>(digit),
                alignment: Alignment.center,
                child: Text(digit, style: style),
              ),
            ),
            // Top and bottom cylinder ambient shadow overlay for authentic recessed drum depth
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.65),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                      ],
                      stops: const [0.0, 0.22, 0.78, 1.0],
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

/// Recessed dual-digit counter with debossed mechanical housing.
class MechanicalCounterDisplay extends StatelessWidget {
  final int minutes;
  final int seconds;
  final bool isDialInset;

  const MechanicalCounterDisplay({
    super.key,
    required this.minutes,
    required this.seconds,
    this.isDialInset = false,
  });

  @override
  Widget build(BuildContext context) {
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');

    final digitStyle = TextStyle(
      fontFamily: 'monospace',
      fontWeight: FontWeight.w700,
      fontSize: isDialInset ? 13.0 : 14.0,
      letterSpacing: 0.5,
      color: TaktColors.warmBone,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDialInset ? 8 : 6,
        vertical: isDialInset ? 3 : 2,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0E10),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(
          color: isDialInset
              ? const Color(0xFF383C44)
              : const Color(0xFF2E3238),
          width: 1.2,
        ),
        boxShadow: [
          const BoxShadow(
            color: Color(0xDD000000),
            offset: Offset(0, 2),
            blurRadius: 4.0,
            spreadRadius: -1.0,
          ),
          BoxShadow(
            color: isDialInset
                ? const Color(0x44FFFFFF)
                : const Color(0x33FFFFFF),
            offset: const Offset(0, -0.8),
            blurRadius: 0.5,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MechanicalFlipDigit(
            digit: mStr[0],
            style: digitStyle,
            slotWidth: isDialInset ? 10.0 : 11.5,
            slotHeight: isDialInset ? 17.0 : 19.0,
          ),
          MechanicalFlipDigit(
            digit: mStr[1],
            style: digitStyle,
            slotWidth: isDialInset ? 10.0 : 11.5,
            slotHeight: isDialInset ? 17.0 : 19.0,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Text(
              ':',
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                fontSize: isDialInset ? 12.0 : 13.0,
                color: TaktColors.filamentAmber,
              ),
            ),
          ),
          MechanicalFlipDigit(
            digit: sStr[0],
            style: digitStyle,
            slotWidth: isDialInset ? 10.0 : 11.5,
            slotHeight: isDialInset ? 17.0 : 19.0,
          ),
          MechanicalFlipDigit(
            digit: sStr[1],
            style: digitStyle,
            slotWidth: isDialInset ? 10.0 : 11.5,
            slotHeight: isDialInset ? 17.0 : 19.0,
          ),
        ],
      ),
    );
  }
}
