import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/takt_colors.dart';
import '../../../../app/theme/theme_controller.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../desk/presentation/desk_canvas_screen.dart';

/// Authentic 4.2-second procedural vector horological opening boot sequence.
///
/// Features:
/// 1. Power Ignition: Warm amber micro-LED gently powers on with filament glow bloom.
/// 2. Horological Dial Calibration: Concentric grooves, 5-minute numerals, and precision ticks reveal.
/// 3. Chrono Needle Sweep: Signature amber needle performs a smooth chronometer calibration settling at 25m Pomodoro.
/// 4. Prominent ZYKL Lockup: Bold horological typographic identity and analog Pomodoro readiness.
/// 5. Relaxed & Frictionless: Serene unhurried pacing with instant tap-to-skip.
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

    // Relaxed, serene 4.2s unhurried calibration sequence
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );

    // 1. Power Ignition (0 - 750ms = 0.0 - 0.18)
    _ledGlowAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.18, curve: Curves.easeInOut),
    );

    // 2. Horological Dial & Bezel reveal (500 - 1700ms = 0.12 - 0.40)
    _dialScaleAnimation = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.12, 0.40, curve: Curves.easeOutCubic),
      ),
    );
    _dialAlphaAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.12, 0.38, curve: Curves.easeIn),
    );

    // 3. Chrono Needle Calibration Sweep (1470 - 3440ms = 0.35 - 0.82)
    _needleSweepAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.82, curve: Curves.easeInOutCubic),
    );

    // 4. Bold ZYKL Brand Lockup (2730 - 3990ms = 0.65 - 0.95)
    _brandAlphaAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 0.95, curve: Curves.easeOut),
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
    // Subtle tactile haptic calibration ticks at quarter marks of needle sweep (unobtrusive & silent)
    if (_needleSweepAnimation.value > 0) {
      final quarter = (_needleSweepAnimation.value * 4).floor();
      if (quarter != _lastTickQuarter && quarter > 0 && quarter <= 4) {
        _lastTickQuarter = quarter;
        HapticService.selectionClick();
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
          transitionDuration: const Duration(milliseconds: 600),
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
    final themeState = ref.watch(chassisThemeProvider);
    final isDark = themeState.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121316) : const Color(0xFFE5E2DA),
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
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.9,
                          colors: isDark
                              ? const [
                                  Color(0xFF181A1E),
                                  Color(0xFF121316),
                                ]
                              : const [
                                  Color(0xFFEDE9E0),
                                  Color(0xFFDDD9CF),
                                ],
                        ),
                      ),
                    ),
                  ),

                  // 2. Central Assembly (Micro-LED, Pomodoro Clock Dial, ZYKL Branding)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Micro-LED indicator at top
                        _buildTopMicroLed(isDark),
                        const SizedBox(height: 18),

                        // Horological Pomodoro Clock Dial Assembly
                        Transform.scale(
                          scale: _dialScaleAnimation.value,
                          child: Opacity(
                            opacity: _dialAlphaAnimation.value,
                            child: SizedBox(
                              key: const ValueKey('opening_dial_canvas'),
                              width: 260,
                              height: 278, // extra 18px for crown socket
                              child: CustomPaint(
                                painter: _OpeningDialPainter(
                                  needleRotation: _needleSweepAnimation.value *
                                      (2 * math.pi + (25 / 60) * 2 * math.pi),
                                  isIlluminated: _needleSweepAnimation.value > 0,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Typographic Lockup & ZYKL Reveal (Developer logo removed)
                        Opacity(
                          opacity: _brandAlphaAnimation.value,
                          child: _buildBrandLockup(isDark),
                        ),
                      ],
                    ),
                  ),

                  // 3. Subtle Tap-to-Skip footer cue
                  Positioned(
                    bottom: 24,
                    child: Opacity(
                      opacity: 0.55,
                      child: Text(
                        '[ TAP ANYWHERE TO SKIP ]',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9.0,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          color: isDark
                              ? TaktColors.warmBone.withValues(alpha: 0.6)
                              : const Color(0xFF7A808B),
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

  Widget _buildTopMicroLed(bool isDark) {
    final glow = _ledGlowAnimation.value;
    return Container(
      key: const ValueKey('opening_micro_led'),
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.lerp(
          isDark ? const Color(0xFF2B2E34) : const Color(0xFFBBB6AC),
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

  Widget _buildBrandLockup(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'ZYKL',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 22.0,
            fontWeight: FontWeight.w900,
            letterSpacing: 6.0,
            color: isDark
                ? TaktColors.warmBone
                : const Color(0xFF1E2126),
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'ANALOG POMODORO SYSTEM',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 9.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.2,
            color: TaktColors.filamentAmber,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'PRECISION TIME HARVESTER // READY',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 7.8,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: isDark
                ? TaktColors.warmBone.withValues(alpha: 0.50)
                : const Color(0xFF6B7280),
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
  final bool isDark;

  _OpeningDialPainter({
    required this.needleRotation,
    required this.isIlluminated,
    this.isDark = false,
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
      ..shader = LinearGradient(
        colors: isDark
            ? const [Color(0xFF5A5E66), Color(0xFF2A2C32), Color(0xFF1E2024)]
            : const [Color(0xFFDED9CF), Color(0xFFBCB6A9), Color(0xFFA69F91)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(crownRect);
    canvas.drawRRect(crownRRect, crownPaint);

    final crownKnurlPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.20) : Colors.black.withValues(alpha: 0.12)
      ..strokeWidth = 1.0;
    for (int i = 0; i < 7; i++) {
      final x = crownRect.left + 3 + i * 3.0;
      canvas.drawLine(Offset(x, crownRect.top + 2), Offset(x, crownRect.bottom - 2), crownKnurlPaint);
    }

    // 2. Bezel Shadow
    final shadowPaint = Paint()
      ..color = isDark ? const Color(0x66000000) : const Color(0x1F000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
    canvas.drawCircle(center + const Offset(0, 6), outerRadius, shadowPaint);

    // 3. Metallic Outer Bezel Ring (Radial Gradient)
    final bezelPaint = Paint()
      ..shader = RadialGradient(
        colors: isDark
            ? [
                const Color(0xFF4A4E56),
                const Color(0xFF2E3137),
                const Color(0xFF1E2024),
              ]
            : [
                const Color(0xFFF4F1EA),
                const Color(0xFFD7D3C8),
                const Color(0xFFB5B0A4),
              ],
        stops: const [0.85, 0.94, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius));
    canvas.drawCircle(center, outerRadius, bezelPaint);

    // 4. Knurled Grip Ring (90 precision micro-lines)
    final knurlPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.10)
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
      ..color = isDark ? const Color(0xFF141517) : const Color(0xFFBCB7AC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, dialRadius + 2, innerBezelStroke);

    // 6. Matte Dial Face (Deep Charcoal in Dark mode, Braun Atelier off-white in Light mode)
    final dialFacePaint = Paint()
      ..color = isDark ? const Color(0xFF1A1C20) : const Color(0xFFF7F5EE);
    canvas.drawCircle(center, dialRadius, dialFacePaint);

    // 6a. Concentric Micro-Grooves (Vinyl texture)
    final groovePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.035);
    for (double r = 18; r < dialRadius - 10; r += 7) {
      canvas.drawCircle(center, r, groovePaint);
    }

    // 7. Amber Halo Glow (illuminated during calibration)
    if (isIlluminated) {
      final haloPaint = Paint()
        ..color = TaktColors.filamentAmber.withValues(alpha: isDark ? 0.22 : 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      canvas.drawCircle(center, dialRadius - 6, haloPaint);
    }

    // 8. 60 Precision Dial Marks & Interval Numerals
    final majorTickPaint = Paint()
      ..color = isDark
          ? TaktColors.warmBone.withValues(alpha: 0.90)
          : const Color(0xFF22262C).withValues(alpha: 0.85)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final minorTickPaint = Paint()
      ..color = isDark
          ? TaktColors.warmBone.withValues(alpha: 0.35)
          : const Color(0xFF22262C).withValues(alpha: 0.30)
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

    // 8a. 5-Minute Horological Numerals (05, 10, 15 ... 25 ... 60)
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    const numerals = [
      '60',
      '05',
      '10',
      '15',
      '20',
      '25',
      '30',
      '35',
      '40',
      '45',
      '50',
      '55',
    ];
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180.0 - math.pi / 2;
      final numRadius = dialRadius - 20;
      final pos = Offset(
        center.dx + numRadius * math.cos(angle),
        center.dy + numRadius * math.sin(angle),
      );

      final isPomodoro25 = (i == 5);
      textPainter.text = TextSpan(
        text: numerals[i],
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 8.5,
          fontWeight: isPomodoro25 ? FontWeight.w800 : FontWeight.w600,
          color: isPomodoro25
              ? TaktColors.filamentAmber
              : (isDark
                  ? TaktColors.warmBone.withValues(alpha: 0.75)
                  : const Color(0xFF22262C).withValues(alpha: 0.70)),
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
      );
    }

    // 9. Signature Amber Needle & Cast Shadow
    final angle = needleRotation - math.pi / 2;
    final needleLength = dialRadius - 10;

    // 9a. Shadow
    final shadowPaintNeedle = Paint()
      ..color = isDark ? const Color(0x66000000) : const Color(0x28000000)
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
    final hubPaint = Paint()..color = isDark ? const Color(0xFF181A1D) : const Color(0xFFD3CEC3);
    canvas.drawCircle(center, 6.0, hubPaint);
    final hubBorder = Paint()
      ..color = isDark ? const Color(0xFF4A4E56) : const Color(0xFFAAA599)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, 6.0, hubBorder);
    final rivetPaint = Paint()..color = TaktColors.filamentAmber;
    canvas.drawCircle(center, 2.0, rivetPaint);
  }

  @override
  bool shouldRepaint(covariant _OpeningDialPainter oldDelegate) {
    return oldDelegate.needleRotation != needleRotation ||
        oldDelegate.isIlluminated != isIlluminated ||
        oldDelegate.isDark != isDark;
  }
}
