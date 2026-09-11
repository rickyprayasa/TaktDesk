import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/takt_colors.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/audio/sound_effect.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../desk/presentation/desk_canvas_screen.dart';

/// Authentic 2.4-second procedural vector horological opening boot sequence.
///
/// Features:
/// 1. Power Ignition: Warm amber micro-LED powers on with filament glow bloom.
/// 2. Bezel & Dial Calibration: Concentric grooves, ticks, and RSQUARE emblem reveal.
/// 3. Chrono Needle Sweep: Signature amber needle performs a full 360° chronometer calibration.
/// 4. Typographic Lockup: TAKT DESK and calibrated readiness status.
/// 5. Frictionless: Instant tap-to-skip allows immediate bypass to DeskCanvasScreen.
class TaktOpeningScreen extends ConsumerStatefulWidget {
  final bool autoNavigate;
  final VoidCallback? onComplete;

  const TaktOpeningScreen({
    super.key,
    this.autoNavigate = true,
    this.onComplete,
  });

  @override
  ConsumerState<TaktOpeningScreen> createState() => _TaktOpeningScreenState();
}

class _TaktOpeningScreenState extends ConsumerState<TaktOpeningScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _ledGlowAnimation;
  late final Animation<double> _dialScaleAnimation;
  late final Animation<double> _dialAlphaAnimation;
  late final Animation<double> _needleSweepAnimation;
  late final Animation<double> _brandAlphaAnimation;

  bool _hasNavigated = false;
  int _lastTickQuarter = -1;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // 1. Power Ignition (0 - 400ms = 0.0 - 0.17)
    _ledGlowAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.17, curve: Curves.easeIn),
    );

    // 2. Dial & Bezel expansion (400 - 1000ms = 0.17 - 0.42)
    _dialScaleAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.17, 0.42, curve: Curves.easeOutBack),
      ),
    );
    _dialAlphaAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.17, 0.38, curve: Curves.easeIn),
    );

    // 3. Chrono Needle Sweep 360° (1000 - 1800ms = 0.42 - 0.75)
    _needleSweepAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.42, 0.75, curve: Curves.easeInOutCubic),
    );

    // 4. RSQUARE Brand Lockup & Readiness (1700 - 2300ms = 0.70 - 0.96)
    _brandAlphaAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.70, 0.96, curve: Curves.easeOut),
    );

    _controller.addListener(_handleAnimationProgress);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finishAndNavigate();
      }
    });

    _controller.forward();
  }

  void _handleAnimationProgress() {
    // Haptic & sound calibration ticks at quarter marks of needle sweep
    if (_needleSweepAnimation.value > 0) {
      final quarter = (_needleSweepAnimation.value * 4).floor();
      if (quarter != _lastTickQuarter && quarter > 0 && quarter <= 4) {
        _lastTickQuarter = quarter;
        HapticService.selectionClick();
        ref.read(audioServiceProvider).playFoley(SoundEffect.dialClick);
      }
    }
  }

  void _finishAndNavigate() {
    if (_hasNavigated) return;
    _hasNavigated = true;

    widget.onComplete?.call();

    if (widget.autoNavigate && mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const DeskCanvasScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    }
  }

  void _handleTapToSkip() {
    HapticService.selectionClick();
    _controller.stop();
    _finishAndNavigate();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleAnimationProgress);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121316),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTapToSkip,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Ambient Background Vignette
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.9,
                          colors: [
                            Color(0xFF181A1E),
                            Color(0xFF121316),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 2. Central Assembly (Micro-LED, Dial, Needle, Branding)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Micro-LED indicator at top
                        _buildTopMicroLed(),
                        const SizedBox(height: 18),

                        // Horological Dial Canvas Assembly
                        Transform.scale(
                          scale: _dialScaleAnimation.value,
                          child: Opacity(
                            opacity: _dialAlphaAnimation.value,
                            child: SizedBox(
                              key: const ValueKey('opening_dial_canvas'),
                              width: 220,
                              height: 236, // extra 16px for crown socket
                              child: CustomPaint(
                                painter: _OpeningDialPainter(
                                  needleRotation:
                                      _needleSweepAnimation.value * 2 * math.pi,
                                  isIlluminated: _needleSweepAnimation.value > 0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Typographic Lockup & RSQUARE Logo Reveal
                        Opacity(
                          opacity: _brandAlphaAnimation.value,
                          child: _buildBrandLockup(),
                        ),
                      ],
                    ),
                  ),

                  // 3. Subtle Tap-to-Skip footer cue
                  Positioned(
                    bottom: 24,
                    child: Opacity(
                      opacity: 0.45,
                      child: Text(
                        '[ TAP ANYWHERE TO SKIP ]',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9.0,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          color: TaktColors.warmBone.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopMicroLed() {
    final glow = _ledGlowAnimation.value;
    return Container(
      key: const ValueKey('opening_micro_led'),
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.lerp(
          const Color(0xFF2B2E34),
          TaktColors.filamentAmber,
          glow,
        ),
        boxShadow: glow > 0.1
            ? [
                BoxShadow(
                  color: TaktColors.filamentAmber.withValues(alpha: 0.75 * glow),
                  blurRadius: 8.0 * glow,
                  spreadRadius: 1.5 * glow,
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildBrandLockup() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // RSQUARE emblem box
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: TaktColors.filamentAmber.withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: Image.asset(
            'assets/images/rsquare_logo.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'ENGINEERED BY RSQUARE',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: TaktColors.filamentAmber,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'TAKT DESK',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14.0,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.5,
            color: TaktColors.warmBone.withValues(alpha: 0.90),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'STATUS: CALIBRATED // READY',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 7.8,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: TaktColors.warmBone.withValues(alpha: 0.50),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for the circular Braun horological boot dial.
class _OpeningDialPainter extends CustomPainter {
  final double needleRotation;
  final bool isIlluminated;

  _OpeningDialPainter({
    required this.needleRotation,
    required this.isIlluminated,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 8);
    final outerRadius = size.width / 2 - 10;
    final dialRadius = outerRadius - 12;

    // 1. Top Crown Push-Button seated into 12 o'clock bezel socket
    const crownWidth = 24.0;
    const crownHeight = 12.0;
    final crownRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy - outerRadius - 5),
      width: crownWidth,
      height: crownHeight,
    );
    final crownRRect = RRect.fromRectAndRadius(crownRect, const Radius.circular(2.5));
    final crownPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF5A5E66), Color(0xFF2A2C32), Color(0xFF1E2024)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(crownRect);
    canvas.drawRRect(crownRRect, crownPaint);

    final crownKnurlPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..strokeWidth = 1.0;
    for (int i = 0; i < 7; i++) {
      final x = crownRect.left + 3 + i * 3.0;
      canvas.drawLine(Offset(x, crownRect.top + 2), Offset(x, crownRect.bottom - 2), crownKnurlPaint);
    }

    // 2. Bezel Shadow
    final shadowPaint = Paint()
      ..color = const Color(0x66000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
    canvas.drawCircle(center + const Offset(0, 6), outerRadius, shadowPaint);

    // 3. Metallic Outer Bezel Ring (Radial Gradient)
    final bezelPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF4A4E56),
          Color(0xFF2E3137),
          Color(0xFF1E2024),
        ],
        stops: [0.85, 0.94, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius));
    canvas.drawCircle(center, outerRadius, bezelPaint);

    // 4. Knurled Grip Ring (90 precision micro-lines)
    final knurlPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.0;
    for (int i = 0; i < 90; i++) {
      final angle = (i * 4) * math.pi / 180.0;
      final p1 = Offset(
        center.dx + (outerRadius - 3) * math.cos(angle),
        center.dy + (outerRadius - 3) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );
      canvas.drawLine(p1, p2, knurlPaint);
    }

    // 5. Stepped Inner Bezel Stroke
    final innerBezelStroke = Paint()
      ..color = const Color(0xFF141517)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, dialRadius + 2, innerBezelStroke);

    // 6. Deep Matte Dial Face
    final dialFacePaint = Paint()..color = const Color(0xFF1A1C20);
    canvas.drawCircle(center, dialRadius, dialFacePaint);

    // 6a. Concentric Micro-Grooves (Vinyl texture)
    final groovePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = Colors.white.withValues(alpha: 0.04);
    for (double r = 18; r < dialRadius - 10; r += 7) {
      canvas.drawCircle(center, r, groovePaint);
    }

    // 7. Amber Halo Glow (illuminated during calibration)
    if (isIlluminated) {
      final haloPaint = Paint()
        ..color = TaktColors.filamentAmber.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      canvas.drawCircle(center, dialRadius - 6, haloPaint);
    }

    // 8. 60 Precision Dial Marks & Interval Numerals
    final majorTickPaint = Paint()
      ..color = TaktColors.warmBone.withValues(alpha: 0.90)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final minorTickPaint = Paint()
      ..color = TaktColors.warmBone.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    for (int i = 0; i < 60; i++) {
      final angle = (i * 6) * math.pi / 180.0 - math.pi / 2;
      final isMajor = i % 5 == 0;
      final tickLength = isMajor ? 7.0 : 3.5;

      final start = Offset(
        center.dx + (dialRadius - 6 - tickLength) * math.cos(angle),
        center.dy + (dialRadius - 6 - tickLength) * math.sin(angle),
      );
      final end = Offset(
        center.dx + (dialRadius - 6) * math.cos(angle),
        center.dy + (dialRadius - 6) * math.sin(angle),
      );
      canvas.drawLine(start, end, isMajor ? majorTickPaint : minorTickPaint);
    }

    // 9. Signature Amber Needle & Cast Shadow
    final angle = needleRotation - math.pi / 2;
    final needleLength = dialRadius - 10;

    // 9a. Shadow
    final shadowPaintNeedle = Paint()
      ..color = const Color(0x66000000)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    final shadowEnd = Offset(
      center.dx + 2 + needleLength * math.cos(angle),
      center.dy + 3 + needleLength * math.sin(angle),
    );
    canvas.drawLine(center + const Offset(2, 3), shadowEnd, shadowPaintNeedle);

    // 9b. Amber Needle Body
    final needlePaint = Paint()
      ..color = TaktColors.filamentAmber
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final needleEnd = Offset(
      center.dx + needleLength * math.cos(angle),
      center.dy + needleLength * math.sin(angle),
    );
    canvas.drawLine(center, needleEnd, needlePaint);

    // 9c. Counterbalance Tail
    final tailEnd = Offset(
      center.dx - 12 * math.cos(angle),
      center.dy - 12 * math.sin(angle),
    );
    canvas.drawLine(center, tailEnd, needlePaint);

    // 10. Center Hub Cap & Metallic Rivet
    final hubPaint = Paint()..color = const Color(0xFF181A1D);
    canvas.drawCircle(center, 6.0, hubPaint);
    final hubBorder = Paint()
      ..color = const Color(0xFF4A4E56)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, 6.0, hubBorder);
    final rivetPaint = Paint()..color = TaktColors.filamentAmber;
    canvas.drawCircle(center, 2.0, rivetPaint);
  }

  @override
  bool shouldRepaint(covariant _OpeningDialPainter oldDelegate) {
    return oldDelegate.needleRotation != needleRotation ||
        oldDelegate.isIlluminated != isIlluminated;
  }
}
