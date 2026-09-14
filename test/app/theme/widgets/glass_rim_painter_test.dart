import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/widgets/glass_rim_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('GlassRimPainter shouldRepaint returns true when light vector or intensity changes', () {
    const painter1 = GlassRimPainter(
      lightX: -0.4,
      lightY: -0.6,
      intensity: 0.5,
      isDark: true,
    );
    const painter2 = GlassRimPainter(
      lightX: 0.2,
      lightY: -0.6,
      intensity: 0.5,
      isDark: true,
    );
    const painter3 = GlassRimPainter(
      lightX: -0.4,
      lightY: -0.6,
      intensity: 0.8,
      isDark: true,
    );

    expect(painter1.shouldRepaint(painter2), isTrue);
    expect(painter1.shouldRepaint(painter3), isTrue);
    expect(painter1.shouldRepaint(painter1), isFalse);
  });

  testWidgets('GlassRimPainter paints without throwing error on Canvas', (tester) async {
    await tester.pumpWidget(
      const CustomPaint(
        size: Size(280, 420),
        painter: GlassRimPainter(
          lightX: -0.5,
          lightY: -0.5,
          intensity: 0.7,
          isDark: true,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('GlassRimPainter handles zero size gracefully', (tester) async {
    await tester.pumpWidget(
      const CustomPaint(
        size: Size.zero,
        painter: GlassRimPainter(
          lightX: 0.0,
          lightY: 0.0,
          intensity: 0.5,
          isDark: false,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
