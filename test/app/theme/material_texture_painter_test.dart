import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/hardware_edition.dart';
import 'package:takt_desk/app/theme/widgets/material_texture_painter.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_painter.dart';

void main() {
  group('MaterialTexturePainter', () {
    test('renders all HardwareTextureType variants without throwing', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(280, 180);

      for (final texture in HardwareTextureType.values) {
        for (final isDark in [true, false]) {
          final painter = MaterialTexturePainter(
            textureType: texture,
            isDark: isDark,
            chassisColor: Colors.black,
          );

          expect(() => painter.paint(canvas, size), returnsNormally);
        }
      }

      final picture = recorder.endRecording();
      picture.dispose();
    });

    test('shouldRepaint returns true when textureType, isDark, or chassisColor changes', () {
      const painter1 = MaterialTexturePainter(
        textureType: HardwareTextureType.organicWalnut,
        isDark: true,
        chassisColor: Colors.black,
      );

      const painter2 = MaterialTexturePainter(
        textureType: HardwareTextureType.forgedCarbon,
        isDark: true,
        chassisColor: Colors.black,
      );

      const painter3 = MaterialTexturePainter(
        textureType: HardwareTextureType.organicWalnut,
        isDark: false,
        chassisColor: Colors.black,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
      expect(painter1.shouldRepaint(painter3), isTrue);
      expect(painter1.shouldRepaint(painter1), isFalse);
    });
  });

  group('ChronoDialPainter knurlAlpha', () {
    test('calculates correct knurlColor and renders for organicWalnut and forgedCarbon', () {
      final walnutDark = ChronoDialPainter(
        remainingSeconds: 1500,
        targetMinutes: 25,
        isRunning: false,
        textureType: HardwareTextureType.organicWalnut,
        isDark: true,
      );
      expect(walnutDark.knurlColor, equals(Colors.white.withValues(alpha: 0.10)));

      final walnutLight = ChronoDialPainter(
        remainingSeconds: 1500,
        targetMinutes: 25,
        isRunning: false,
        textureType: HardwareTextureType.organicWalnut,
        isDark: false,
      );
      expect(walnutLight.knurlColor, equals(Colors.black.withValues(alpha: 0.10 * 0.75)));

      final carbonDark = ChronoDialPainter(
        remainingSeconds: 1500,
        targetMinutes: 25,
        isRunning: false,
        textureType: HardwareTextureType.forgedCarbon,
        isDark: true,
      );
      expect(carbonDark.knurlColor, equals(Colors.white.withValues(alpha: 0.13)));

      final carbonLight = ChronoDialPainter(
        remainingSeconds: 1500,
        targetMinutes: 25,
        isRunning: false,
        textureType: HardwareTextureType.forgedCarbon,
        isDark: false,
      );
      expect(carbonLight.knurlColor, equals(Colors.black.withValues(alpha: 0.13 * 0.75)));

      // Verify painting executes cleanly for all textures
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(200, 200);
      expect(() => walnutDark.paint(canvas, size), returnsNormally);
      expect(() => carbonDark.paint(canvas, size), returnsNormally);
      recorder.endRecording().dispose();
    });
  });
}
