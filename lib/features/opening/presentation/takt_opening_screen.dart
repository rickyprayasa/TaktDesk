import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/takt_colors.dart';
import '../../../../app/theme/theme_controller.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/audio/sound_effect.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../desk/presentation/desk_canvas_screen.dart';
import '../../settings/presentation/settings_controller.dart';

/// 4.2 s cinematic boot of the instrument (owner asked for a calmer opening
/// than the original 1.8 s). Tap anywhere to skip.
///
///      0 –  700 ms  power LED warms up in the edition's filament colour
///    250 – 1500 ms  light sweeps across the bezel
///    400 – 1700 ms  face fades in, ticks draw in clockwise
///   1100 – 2900 ms  needle winds one full turn and seats on 25 with a spring overshoot;
///                   escapement ticks at 3/6/9/12, a "clack" when it seats
///   2500 – 3300 ms  "ZYKL" tightens (letter-spacing 10 -> 6), then
///   2900 – 3700 ms  "POMODORO FOCUS TIMER" and
///   3300 – 4000 ms  "QUIET TIME. PHYSICAL INTENT."
///   4000 – 4200 ms  hold, then a 900 ms pull-back into the desk
///
/// Doubles as the warm-up for saved preferences: it only hands over to the desk
/// once they are applied, so the finish, haptics and sound are already the
/// user's own. With system "remove animations" on it shows a static lockup.
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

/// Native splash colour (android/app/src/main/res/.../launch_background.xml),
/// so the hand-off from the system splash to Flutter is seamless.
const _splashColor = Color(0xFF121316);

const _totalMs = 4200.0;

/// Moment the needle seats on 25 (end of the wind-up).
const _seatMs = 2900.0;
Interval _at(double fromMs, double toMs, [Curve curve = Curves.linear]) =>
    Interval(fromMs / _totalMs, toMs / _totalMs, curve: curve);

/// Needle travel: one full turn plus 25 minutes (150°), overshooting by 9°.
const _seatTurns = 1 + 25 / 60;
const _overshootTurns = 9 / 360;

class _TaktOpeningScreenState extends ConsumerState<TaktOpeningScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _led;
  late final Animation<double> _bezelSweep;
  late final Animation<double> _face;
  late final Animation<double> _tickReveal;
  late final Animation<double> _needleTurns;
  late final Animation<double> _wordmark;
  late final Animation<double> _descriptor;
  late final Animation<double> _brandLine;
  late final Animation<double> _canvasTint;

  bool _hasNavigated = false;
  bool _prefsReady = false;
  bool _animationDone = false;
  bool _seated = false;
  int _lastQuarter = 0;
  Timer? _prefsTimeout;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 4200));

    _led = CurvedAnimation(parent: _controller, curve: _at(0, 700, Curves.easeInOut));
    _bezelSweep = CurvedAnimation(parent: _controller, curve: _at(250, 1500, Curves.easeInOutCubic));
    _face = CurvedAnimation(parent: _controller, curve: _at(400, 1700, Curves.easeOutCubic));
    _tickReveal = CurvedAnimation(parent: _controller, curve: _at(500, 1800, Curves.easeOutCubic));
    _needleTurns = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: _seatTurns + _overshootTurns).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 1450,
      ),
      TweenSequenceItem(
        tween: Tween(begin: _seatTurns + _overshootTurns, end: _seatTurns).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 350,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: _at(1100, _seatMs)));
    _wordmark = CurvedAnimation(parent: _controller, curve: _at(2500, 3300, Curves.easeOutCubic));
    _descriptor = CurvedAnimation(parent: _controller, curve: _at(2900, 3700, Curves.easeOut));
    _brandLine = CurvedAnimation(parent: _controller, curve: _at(3300, 4000, Curves.easeOut));
    _canvasTint = CurvedAnimation(parent: _controller, curve: _at(0, 900, Curves.easeOut));

    _controller.addListener(_handleMechanics);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationDone = true;
        _maybeFinish();
      }
    });

    // Load saved preferences in parallel with the animation
    ref.read(deskPreferencesControllerProvider.notifier).ready.catchError((_) {}).whenComplete(() {
      if (!mounted) return;
      _prefsReady = true;
      _maybeFinish();
    });
    // Never hold the user on the opening because storage is slow
    _prefsTimeout = Timer(const Duration(milliseconds: 3000), () {
      _prefsReady = true;
      _maybeFinish();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      // Reduced motion: static lockup, short pause, no haptics
      _seated = true;
      _controller.value = 1.0;
      Future.delayed(const Duration(milliseconds: 600), () {
        _animationDone = true;
        _maybeFinish();
      });
    } else {
      _controller.forward();
    }
  }

  /// Escapement ticks as the needle passes 3/6/9/12 on its first turn, then a
  /// clack when it seats. Only once preferences are known, so a user who turned
  /// haptics or foley off never gets them here either.
  void _handleMechanics() {
    final turns = _needleTurns.value;
    final quarter = (turns * 4).floor().clamp(0, 4);
    if (quarter > _lastQuarter) {
      _lastQuarter = quarter;
      if (_prefsReady) HapticService.selectionClick();
    }
    if (!_seated && _controller.value >= _seatMs / _totalMs) {
      _seated = true;
      if (_prefsReady) {
        HapticService.mechanicalPress();
        ref.read(audioServiceProvider).playFoley(SoundEffect.dialClick);
      }
    }
  }

  void _maybeFinish() {
    if (_animationDone && _prefsReady) _finishAndNavigate();
  }

  void _finishAndNavigate() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    _prefsTimeout?.cancel();

    widget.onComplete?.call();

    if (widget.autoNavigate && mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 900),
          pageBuilder: (context, animation, secondaryAnimation) => const DeskCanvasScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
            // The desk settles in as if the camera pulls back from the dial
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween(begin: 1.06, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
        ),
      );
    }
  }

  void _handleTapToSkip() {
    if (_prefsReady) HapticService.selectionClick();
    _controller.stop();
    _prefsReady = true; // skipping means "take me in now"
    _finishAndNavigate();
  }

  @override
  void dispose() {
    _prefsTimeout?.cancel();
    _controller.removeListener(_handleMechanics);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(chassisThemeProvider);
    final isDark = themeState.isDarkMode;
    final filament = themeState.filamentColor;
    final targetBg = isDark ? _splashColor : const Color(0xFFE5E2DA);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final bg = Color.lerp(_splashColor, targetBg, _canvasTint.value)!;
        return Scaffold(
          backgroundColor: bg,
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _handleTapToSkip,
            child: SafeArea(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          radius: 0.9,
                          colors: isDark
                              ? [
                                  Color.lerp(const Color(0xFF181A1E), filament, 0.04 * _led.value)!,
                                  _splashColor,
                                ]
                              : const [Color(0xFFEDE9E0), Color(0xFFDDD9CF)],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTopMicroLed(isDark, filament),
                        const SizedBox(height: 18),
                        Transform.scale(
                          scale: 0.92 + 0.08 * _face.value,
                          child: Opacity(
                            opacity: _face.value,
                            child: SizedBox(
                              key: const ValueKey('opening_dial_canvas'),
                              width: 260,
                              height: 278, // extra 18px for crown socket
                              child: CustomPaint(
                                painter: _OpeningDialPainter(
                                  needleRotation: _needleTurns.value * 2 * math.pi,
                                  tickReveal: _tickReveal.value,
                                  bezelSweep: _bezelSweep.value,
                                  isIlluminated: _needleTurns.value > 0,
                                  filamentColor: filament,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildBrandLockup(isDark, filament),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    child: Opacity(
                      opacity: _face.value,
                      child: Text(
                        '[ TAP ANYWHERE TO SKIP ]',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9.0,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          // >= 4.5:1 against the canvas in both finishes
                          color: isDark ? TaktColors.warmBone.withValues(alpha: 0.62) : const Color(0xFF5E636C),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopMicroLed(bool isDark, Color filament) {
    final glow = _led.value;
    return Container(
      key: const ValueKey('opening_micro_led'),
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.lerp(isDark ? const Color(0xFF2B2E34) : const Color(0xFFBBB6AC), filament, glow),
        boxShadow: glow > 0.1
            ? [
                BoxShadow(
                  color: filament.withValues(alpha: 0.75 * glow),
                  blurRadius: 10.0 * glow,
                  spreadRadius: 1.8 * glow,
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildBrandLockup(bool isDark, Color filament) {
    final w = _wordmark.value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: w,
          child: Transform.translate(
            offset: Offset(0, 6 * (1 - w)),
            child: Text(
              'ZYKL',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 22.0,
                fontWeight: FontWeight.w900,
                letterSpacing: 10.0 - 4.0 * w,
                color: isDark ? TaktColors.warmBone : const Color(0xFF1E2126),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Opacity(
          opacity: _descriptor.value,
          child: Text(
            'POMODORO FOCUS TIMER',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.2,
              color: filament,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Opacity(
          opacity: _brandLine.value,
          child: Text(
            'QUIET TIME. PHYSICAL INTENT.',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 7.8,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: isDark ? TaktColors.warmBone.withValues(alpha: 0.55) : const Color(0xFF5E636C),
            ),
          ),
        ),
      ],
    );
  }
}

/// The boot dial: bezel with a travelling light band, ticks drawn in clockwise,
/// and the filament needle.
class _OpeningDialPainter extends CustomPainter {
  final double needleRotation;
  final double tickReveal;
  final double bezelSweep;
  final bool isIlluminated;
  final Color filamentColor;
  final bool isDark;

  _OpeningDialPainter({
    required this.needleRotation,
    required this.tickReveal,
    required this.bezelSweep,
    required this.isIlluminated,
    required this.filamentColor,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 8);
    final outerRadius = size.width / 2 - 10;
    final dialRadius = outerRadius - 12;

    // 1. Crown seated in the 12 o'clock socket
    final crownRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy - outerRadius - 5),
      width: 24,
      height: 12,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(crownRect, const Radius.circular(2.5)),
      Paint()
        ..shader = LinearGradient(
          colors: isDark
              ? const [Color(0xFF5A5E66), Color(0xFF2A2C32), Color(0xFF1E2024)]
              : const [Color(0xFFDED9CF), Color(0xFFBCB6A9), Color(0xFFA69F91)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(crownRect),
    );
    final crownKnurl = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.20) : Colors.black.withValues(alpha: 0.12)
      ..strokeWidth = 1.0;
    for (int i = 0; i < 7; i++) {
      final x = crownRect.left + 3 + i * 3.0;
      canvas.drawLine(Offset(x, crownRect.top + 2), Offset(x, crownRect.bottom - 2), crownKnurl);
    }

    // 2. Drop shadow
    canvas.drawCircle(
      center + const Offset(0, 6),
      outerRadius,
      Paint()
        ..color = isDark ? const Color(0x66000000) : const Color(0x1F000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0),
    );

    // 3. Turned-metal bezel: a sweep gradient reads as machined, not a flat ring
    final bezelRect = Rect.fromCircle(center: center, radius: outerRadius);
    canvas.drawCircle(
      center,
      outerRadius,
      Paint()
        ..shader = SweepGradient(
          colors: isDark
              ? const [Color(0xFF3A3E46), Color(0xFF5A5F68), Color(0xFF26292E), Color(0xFF4A4E56), Color(0xFF3A3E46)]
              : const [Color(0xFFD7D3C8), Color(0xFFF6F3EC), Color(0xFFBDB8AC), Color(0xFFE8E4DB), Color(0xFFD7D3C8)],
          stops: const [0.0, 0.2, 0.5, 0.75, 1.0],
        ).createShader(bezelRect),
    );

    // 3a. Light band travelling once around the bezel as the instrument powers up
    if (bezelSweep > 0 && bezelSweep < 1) {
      final start = -math.pi / 2 + bezelSweep * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius - 4),
        start - 0.5,
        0.5,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            startAngle: start - 0.5,
            endAngle: start,
            colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: isDark ? 0.55 : 0.9)],
          ).createShader(bezelRect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
      );
    }

    // 4. Knurled grip ring
    final knurl = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.10)
      ..strokeWidth = 1.0;
    for (int i = 0; i < 90; i++) {
      final a = (i * 4) * math.pi / 180.0;
      canvas.drawLine(
        center + Offset(math.cos(a), math.sin(a)) * (outerRadius - 3),
        center + Offset(math.cos(a), math.sin(a)) * outerRadius,
        knurl,
      );
    }

    // 5. Stepped inner bezel + face
    canvas.drawCircle(
      center,
      dialRadius + 2,
      Paint()
        ..color = isDark ? const Color(0xFF141517) : const Color(0xFFBCB7AC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    canvas.drawCircle(
      center,
      dialRadius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.3),
          colors: isDark ? const [Color(0xFF1F2227), Color(0xFF16181C)] : const [Color(0xFFFBF9F3), Color(0xFFEFECE3)],
        ).createShader(Rect.fromCircle(center: center, radius: dialRadius)),
    );
    final groove = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.035);
    for (double r = 18; r < dialRadius - 10; r += 7) {
      canvas.drawCircle(center, r, groove);
    }

    // 6. Filament halo once the needle is live
    if (isIlluminated) {
      canvas.drawCircle(
        center,
        dialRadius - 6,
        Paint()
          ..color = filamentColor.withValues(alpha: isDark ? 0.22 : 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0),
      );
    }

    // 7. Ticks draw in clockwise from 12
    final major = Paint()
      ..color = isDark ? TaktColors.warmBone.withValues(alpha: 0.90) : const Color(0xFF22262C).withValues(alpha: 0.85)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final minor = Paint()
      ..color = isDark ? TaktColors.warmBone.withValues(alpha: 0.35) : const Color(0xFF22262C).withValues(alpha: 0.30)
      ..strokeWidth = 1.0;
    final visibleTicks = (tickReveal * 60).ceil();
    for (int i = 0; i < visibleTicks; i++) {
      final a = (i * 6) * math.pi / 180.0 - math.pi / 2;
      final isMajor = i % 5 == 0;
      final len = isMajor ? 7.0 : 3.5;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(center + dir * (dialRadius - 6 - len), center + dir * (dialRadius - 6), isMajor ? major : minor);
    }

    // 7a. 5-minute numerals, 25 picked out in filament
    const numerals = ['60', '05', '10', '15', '20', '25', '30', '35', '40', '45', '50', '55'];
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < 12; i++) {
      if (i * 5 >= visibleTicks) break;
      final a = (i * 30) * math.pi / 180.0 - math.pi / 2;
      final pos = center + Offset(math.cos(a), math.sin(a)) * (dialRadius - 20);
      final is25 = i == 5;
      tp.text = TextSpan(
        text: numerals[i],
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 8.5,
          fontWeight: is25 ? FontWeight.w800 : FontWeight.w600,
          color: is25
              ? filamentColor
              : (isDark ? TaktColors.warmBone.withValues(alpha: 0.75) : const Color(0xFF22262C).withValues(alpha: 0.70)),
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }

    // 8. Needle + shadow
    final a = needleRotation - math.pi / 2;
    final dir = Offset(math.cos(a), math.sin(a));
    final needleLength = dialRadius - 10;
    canvas.drawLine(
      center + const Offset(2, 3),
      center + const Offset(2, 3) + dir * needleLength,
      Paint()
        ..color = isDark ? const Color(0x66000000) : const Color(0x28000000)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    final needle = Paint()
      ..color = filamentColor
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, center + dir * needleLength, needle);
    canvas.drawLine(center, center - dir * 12, needle);

    // 9. Hub with a specular dot
    canvas.drawCircle(
      center,
      6.0,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: isDark ? const [Color(0xFF3A3E46), Color(0xFF16181B)] : const [Color(0xFFEDE9E0), Color(0xFFB9B4A8)],
        ).createShader(Rect.fromCircle(center: center, radius: 6)),
    );
    canvas.drawCircle(center, 2.0, Paint()..color = filamentColor);
    canvas.drawCircle(center + const Offset(-1.8, -1.8), 0.9, Paint()..color = Colors.white.withValues(alpha: 0.6));
  }

  @override
  bool shouldRepaint(covariant _OpeningDialPainter oldDelegate) {
    return oldDelegate.needleRotation != needleRotation ||
        oldDelegate.tickReveal != tickReveal ||
        oldDelegate.bezelSweep != bezelSweep ||
        oldDelegate.isIlluminated != isIlluminated ||
        oldDelegate.filamentColor != filamentColor ||
        oldDelegate.isDark != isDark;
  }
}
