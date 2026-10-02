import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../hardware_edition.dart';

/// Small deterministic xorshift generator: the same chassis size always gets the
/// same grain, so the texture is stable across rebuilds and raster-cacheable.
class _Rng {
  int _s;
  _Rng(int seed) : _s = (seed * 2654435761) & 0x7fffffff | 1;

  double next() {
    var x = _s;
    x ^= (x << 13) & 0x7fffffff;
    x ^= x >> 17;
    x ^= (x << 5) & 0x7fffffff;
    _s = (x & 0x7fffffff) == 0 ? 1 : x & 0x7fffffff;
    return _s / 0x7fffffff;
  }

  double range(double a, double b) => a + (b - a) * next();
}

/// Static, procedural surface texture for a hardware chassis. Painted once and
/// cached behind a RepaintBoundary; the light-dependent highlight lives in
/// [MaterialSheenPainter] so sensor updates never repaint this layer.
///
/// - matteAbsGrain      molded thermoplastic: random fine speckle + soft mold sheen
/// - brushedTitanium    randomised hairlines of varying length and strength
/// - tubularChrome      polished chrome: crisp horizon reflections
/// - burnishedBrass     warm hairlines, patina blooms, darkened edges
/// - organicWalnut      flowing grain with per-line drift, cathedral figure, pores
/// - forgedCarbon       rotated chopped-fibre flakes (marbled composite)
/// - glossCeramic       near-black clearcoat with depth gradient
/// - galvanizedSpangle  crystalline zinc spangles with dendrite lines
/// - lacquer            deep piano lacquer with depth gradient
class MaterialTexturePainter extends CustomPainter {
  final HardwareTextureType textureType;
  final bool isDark;
  final Color chassisColor;

  const MaterialTexturePainter({
    required this.textureType,
    required this.isDark,
    required this.chassisColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final rng = _Rng(textureType.index * 7919 + size.width.round() * 31 + size.height.round());

    switch (textureType) {
      case HardwareTextureType.brushedTitanium:
        _paintBrushed(canvas, size, rng, warm: false);
        break;
      case HardwareTextureType.burnishedBrass:
        _paintBrushed(canvas, size, rng, warm: true);
        _paintPatina(canvas, size, rng);
        break;
      case HardwareTextureType.tubularChrome:
        _paintChrome(canvas, size);
        break;
      case HardwareTextureType.matteAbsGrain:
        _paintGrain(canvas, size, rng, density: 1 / 9.0, strength: 1.0);
        _paintMoldSheen(canvas, size);
        break;
      case HardwareTextureType.organicWalnut:
        _paintWalnut(canvas, size, rng);
        break;
      case HardwareTextureType.forgedCarbon:
        _paintForgedCarbon(canvas, size, rng);
        break;
      case HardwareTextureType.glossCeramic:
        _paintDepth(canvas, size, strength: 1.0);
        _paintGrain(canvas, size, rng, density: 1 / 40.0, strength: 0.4);
        break;
      case HardwareTextureType.galvanizedSpangle:
        _paintSpangle(canvas, size, rng);
        break;
      case HardwareTextureType.lacquer:
        _paintDepth(canvas, size, strength: 0.8);
        break;
    }
  }

  // ---------------------------------------------------------------- helpers

  void _points(Canvas canvas, List<double> xy, Color color, double width) {
    if (xy.isEmpty) return;
    canvas.drawRawPoints(
      ui.PointMode.points,
      Float32List.fromList(xy),
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintGrain(Canvas canvas, Size size, _Rng rng, {required double density, required double strength}) {
    final count = (size.width * size.height * density).round().clamp(0, 60000);
    final light = <double>[];
    final dark = <double>[];
    for (int i = 0; i < count; i++) {
      final x = rng.next() * size.width;
      final y = rng.next() * size.height;
      (rng.next() < 0.5 ? light : dark)
        ..add(x)
        ..add(y);
    }
    _points(canvas, light, Colors.white.withValues(alpha: (isDark ? 0.045 : 0.09) * strength), 0.9);
    _points(canvas, dark, Colors.black.withValues(alpha: (isDark ? 0.10 : 0.05) * strength), 0.9);
  }

  void _paintMoldSheen(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: isDark ? 0.035 : 0.10),
            Colors.transparent,
            Colors.black.withValues(alpha: isDark ? 0.10 : 0.04),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(rect),
    );
  }

  void _paintBrushed(Canvas canvas, Size size, _Rng rng, {required bool warm}) {
    // Hairlines of random length, offset and strength: real brushing is never a grid
    final lines = (size.height * 1.8).round();
    final lightTint = warm ? const Color(0xFFF2CF80) : Colors.white;
    for (int i = 0; i < lines; i++) {
      final y = rng.next() * size.height;
      final len = size.width * rng.range(0.25, 1.1);
      final x0 = rng.range(-0.2, 1.0) * size.width;
      final bright = rng.next() < 0.5;
      final a = rng.range(0.015, bright ? 0.075 : 0.09);
      canvas.drawLine(
        Offset(x0, y),
        Offset(x0 + len, y + rng.range(-0.25, 0.25)),
        Paint()
          ..color = (bright ? lightTint : Colors.black).withValues(alpha: a * (isDark ? 0.8 : 1.0))
          ..strokeWidth = rng.range(0.35, 0.9),
      );
    }
  }

  void _paintPatina(Canvas canvas, Size size, _Rng rng) {
    // Oxidised blooms collect unevenly, more towards the edges
    final blooms = (size.width * size.height / 9000).round().clamp(3, 40);
    for (int i = 0; i < blooms; i++) {
      final edge = rng.next() < 0.65;
      final x = edge ? (rng.next() < 0.5 ? rng.range(0, 0.18) : rng.range(0.82, 1)) * size.width : rng.next() * size.width;
      final y = rng.next() * size.height;
      final r = rng.range(14, 46);
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [const Color(0xFF2F4A3C).withValues(alpha: isDark ? 0.16 : 0.05), Colors.transparent],
          ).createShader(Rect.fromCircle(center: Offset(x, y), radius: r)),
      );
    }
    _paintVignette(canvas, size, isDark ? 0.32 : 0.18, const Color(0xFF151815));
  }

  void _paintVignette(Canvas canvas, Size size, double alpha, [Color color = Colors.black]) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 0.9,
          colors: [Colors.transparent, color.withValues(alpha: 0.0), color.withValues(alpha: alpha)],
          stops: const [0.0, 0.62, 1.0],
        ).createShader(rect),
    );
  }

  void _paintChrome(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Polished tube: a dark horizon line under a bright sky band, mirrored lower
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: isDark ? 0.10 : 0.30),
            Colors.white.withValues(alpha: isDark ? 0.02 : 0.08),
            Colors.black.withValues(alpha: isDark ? 0.18 : 0.10),
            Colors.white.withValues(alpha: isDark ? 0.06 : 0.16),
            Colors.transparent,
            Colors.black.withValues(alpha: isDark ? 0.14 : 0.06),
          ],
          stops: const [0.0, 0.30, 0.34, 0.40, 0.75, 1.0],
        ).createShader(rect),
    );
  }

  void _paintWalnut(Canvas canvas, Size size, _Rng rng) {
    // Grain lines with individual drift; spacing varies like real growth rings
    final heart = Paint()
      ..color = const Color(0xFF1C140E).withValues(alpha: isDark ? 0.20 : 0.085)
      ..style = PaintingStyle.stroke;
    final sap = Paint()
      ..color = const Color(0xFFB07A3E).withValues(alpha: isDark ? 0.07 : 0.06)
      ..style = PaintingStyle.stroke;
    final phaseA = rng.range(0, math.pi * 2);
    double y = -10;
    int line = 0;
    while (y < size.height + 10) {
      final path = Path();
      final amp = rng.range(1.2, 3.4);
      final f1 = rng.range(0.010, 0.022);
      final f2 = rng.range(0.035, 0.06);
      final ph = rng.range(0, math.pi * 2);
      for (double x = 0; x <= size.width + 4; x += 4) {
        // Shared low-frequency sway keeps neighbouring lines flowing together
        final sway = math.sin(x * 0.006 + phaseA) * 6.0;
        final yy = y + sway + math.sin(x * f1 + ph) * amp + math.sin(x * f2 + ph * 1.7) * amp * 0.35;
        x == 0 ? path.moveTo(x, yy) : path.lineTo(x, yy);
      }
      final p = (line % 3 == 0 ? heart : sap)..strokeWidth = rng.range(0.5, isDark ? 1.4 : 1.0);
      canvas.drawPath(path, p);
      y += rng.range(2.2, 5.5);
      line++;
    }

    // Cathedral figure: a couple of nested arches where the board crossed the rings
    final arches = (size.width / 220).ceil().clamp(1, 4);
    for (int a = 0; a < arches; a++) {
      final cx = rng.range(0.15, 0.85) * size.width;
      final cy = rng.range(0.25, 0.85) * size.height;
      for (int k = 0; k < 7; k++) {
        final w = 18.0 + k * 9;
        final h = 26.0 + k * 11;
        final path = Path()
          ..moveTo(cx - w, cy + h * 0.6)
          ..quadraticBezierTo(cx, cy - h, cx + w, cy + h * 0.6);
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFF1C140E).withValues(alpha: (isDark ? 0.12 : 0.06) * (1 - k / 9))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.9,
        );
      }
    }

    // Open pores: short dashes along the grain
    final pores = (size.width * size.height / 260).round().clamp(0, 6000);
    final pore = Paint()
      ..color = (isDark ? Colors.black : const Color(0xFF3E2714)).withValues(alpha: isDark ? 0.18 : 0.07)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < pores; i++) {
      final x = rng.next() * size.width;
      final yy = rng.next() * size.height;
      canvas.drawLine(Offset(x, yy), Offset(x + rng.range(1.5, 4.5), yy), pore);
    }
    _paintVignette(canvas, size, isDark ? 0.28 : 0.14);
  }

  void _paintForgedCarbon(Canvas canvas, Size size, _Rng rng) {
    // Chopped fibre bundles pressed at random angles: irregular flakes, three tones
    final flakes = (size.width * size.height / (isDark ? 70 : 45)).round().clamp(0, 12000);
    final tones = [
      const Color(0xFFE0E5EC).withValues(alpha: isDark ? 0.10 : 0.10),
      Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
      const Color(0xFF8C939E).withValues(alpha: isDark ? 0.08 : 0.07),
    ];
    final paths = [Path(), Path(), Path()];
    for (int i = 0; i < flakes; i++) {
      final cx = rng.next() * size.width;
      final cy = rng.next() * size.height;
      final len = rng.range(5, 16);
      final wid = rng.range(1.5, 5);
      final ang = rng.range(0, math.pi);
      final c = math.cos(ang), s = math.sin(ang);
      Offset p(double u, double v) => Offset(cx + u * c - v * s, cy + u * s + v * c);
      final path = paths[(rng.next() * 3).floor().clamp(0, 2)];
      final a = p(-len / 2, -wid / 2), b = p(len / 2, -wid / 2 * rng.range(0.4, 1)), d = p(-len / 2 * rng.range(0.6, 1), wid / 2);
      path
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(p(len / 2, wid / 2).dx, p(len / 2, wid / 2).dy)
        ..lineTo(d.dx, d.dy)
        ..close();
    }
    for (int i = 0; i < 3; i++) {
      canvas.drawPath(paths[i], Paint()..color = tones[i]);
    }
  }

  void _paintDepth(Canvas canvas, Size size, {required double strength}) {
    // Clearcoat depth: the surface reads as a deep pool rather than a flat fill
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: (isDark ? 0.05 : 0.14) * strength),
            Colors.transparent,
            Colors.black.withValues(alpha: (isDark ? 0.22 : 0.08) * strength),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect),
    );
  }

  void _paintSpangle(Canvas canvas, Size size, _Rng rng) {
    // Hot-dip zinc crystals: irregular facets, each a slightly different grey,
    // with fern-like dendrites radiating from the nucleus
    const cell = 26.0;
    for (double gy = -cell; gy < size.height + cell; gy += cell) {
      for (double gx = -cell; gx < size.width + cell; gx += cell) {
        final cx = gx + rng.range(0, cell);
        final cy = gy + rng.range(0, cell);
        final r = rng.range(cell * 0.7, cell * 1.25);
        final sides = 5 + (rng.next() * 3).floor();
        final rot = rng.range(0, math.pi * 2);
        final path = Path();
        for (int k = 0; k < sides; k++) {
          final a = rot + k * 2 * math.pi / sides + rng.range(-0.25, 0.25);
          final rr = r * rng.range(0.75, 1.0);
          final pt = Offset(cx + rr * math.cos(a), cy + rr * math.sin(a));
          k == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
        }
        path.close();
        final bright = rng.next() < 0.5;
        canvas.drawPath(
          path,
          Paint()..color = (bright ? Colors.white : Colors.black).withValues(alpha: rng.range(0.01, isDark ? 0.045 : 0.06)),
        );
        final dendrite = Paint()
          ..color = Colors.white.withValues(alpha: isDark ? 0.03 : 0.08)
          ..strokeWidth = 0.5;
        for (int k = 0; k < 6; k++) {
          final a = rot + k * math.pi / 3;
          canvas.drawLine(Offset(cx, cy), Offset(cx + r * 0.6 * math.cos(a), cy + r * 0.6 * math.sin(a)), dendrite);
        }
      }
    }
    _paintVignette(canvas, size, isDark ? 0.20 : 0.10);
  }

  @override
  bool shouldRepaint(covariant MaterialTexturePainter oldDelegate) {
    // chassisColor is checked so that when the base chassis tone changes,
    // the procedural texture is re-evaluated and repainted.
    return textureType != oldDelegate.textureType ||
        isDark != oldDelegate.isDark ||
        chassisColor != oldDelegate.chassisColor;
  }
}

/// Cheap, light-dependent highlight drawn over the cached texture. It follows
/// the parallax light (tilting the phone moves it), which is the cue that makes
/// a surface read as metal, ceramic or lacquer instead of a printed pattern.
class MaterialSheenPainter extends CustomPainter {
  final HardwareTextureType textureType;
  final bool isDark;

  /// Light position, -1..1 on each axis (ParallaxState.lightX / lightY).
  final double lightX;
  final double lightY;

  /// Chassis corner radius; the sheen clips itself so it needs no extra clip layer.
  final BorderRadius borderRadius;

  const MaterialSheenPainter({
    required this.textureType,
    required this.isDark,
    this.lightX = -0.4,
    this.lightY = -0.6,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final rect = Offset.zero & size;
    canvas.clipRRect(borderRadius.toRRect(rect));
    final k = isDark ? 1.0 : 1.4;
    switch (textureType) {
      case HardwareTextureType.brushedTitanium:
      case HardwareTextureType.burnishedBrass:
        // Horizontal brushing stretches the highlight into a horizontal band
        final cy = (0.5 + lightY * 0.45).clamp(0.05, 0.95);
        final tint = textureType == HardwareTextureType.burnishedBrass ? const Color(0xFFFFE2A0) : Colors.white;
        canvas.drawRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, tint.withValues(alpha: 0.07 * k), Colors.transparent],
              stops: [(cy - 0.22).clamp(0.0, 1.0), cy, (cy + 0.22).clamp(0.0, 1.0)],
            ).createShader(rect),
        );
        break;
      case HardwareTextureType.tubularChrome:
      case HardwareTextureType.glossCeramic:
      case HardwareTextureType.lacquer:
        // Sharp window reflection sliding diagonally with the light
        final t = (0.5 + lightX * 0.35).clamp(0.1, 0.9);
        final sharp = textureType == HardwareTextureType.lacquer ? 0.06 : 0.035;
        canvas.drawRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              begin: const Alignment(-1, -1),
              end: const Alignment(1, 1),
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.10 * k),
                Colors.white.withValues(alpha: 0.03 * k),
                Colors.transparent,
              ],
              stops: [(t - sharp * 2).clamp(0.0, 1.0), t - sharp * 0.3, t + sharp, (t + sharp * 3).clamp(0.0, 1.0)],
            ).createShader(rect),
        );
        break;
      case HardwareTextureType.galvanizedSpangle:
      case HardwareTextureType.forgedCarbon:
      case HardwareTextureType.organicWalnut:
      case HardwareTextureType.matteAbsGrain:
        // Soft broad highlight near the light source
        final c = Alignment((lightX * 0.8).clamp(-1.0, 1.0), (lightY * 0.8).clamp(-1.0, 1.0));
        final strength = textureType == HardwareTextureType.matteAbsGrain ? 0.035 : 0.06;
        canvas.drawRect(
          rect,
          Paint()
            ..shader = RadialGradient(
              center: c,
              radius: 1.1,
              colors: [Colors.white.withValues(alpha: strength * k), Colors.transparent],
            ).createShader(rect),
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant MaterialSheenPainter oldDelegate) =>
      textureType != oldDelegate.textureType ||
      isDark != oldDelegate.isDark ||
      borderRadius != oldDelegate.borderRadius ||
      (lightX - oldDelegate.lightX).abs() > 0.01 ||
      (lightY - oldDelegate.lightY).abs() > 0.01;
}
