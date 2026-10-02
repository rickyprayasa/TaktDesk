// Visual review harness for the hardware editions (not a regular test).
// Renders every edition's chassis panel + dial face, dark and light, to PNGs:
//
//   GALLERY_OUT=/tmp/zykl-gallery flutter test test/tool/edition_gallery_test.dart
//
// Without GALLERY_OUT the test is skipped, so it never slows the normal suite.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/hardware_edition.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';
import 'package:takt_desk/app/theme/widgets/material_chassis_box.dart';
import 'package:takt_desk/features/timer/presentation/chrono_dial_painter.dart';

void main() {
  final out = Platform.environment['GALLERY_OUT'];

  testWidgets('render edition gallery', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 260));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Directory(out!).createSync(recursive: true);

    for (final type in HardwareEditionType.values) {
      for (final dark in [true, false]) {
        final edition = HardwareEdition.fromType(type);
        final themeState = ChassisThemeState(isDarkMode: dark, edition: edition, isProUnlocked: true);
        final key = GlobalKey();
        await tester.pumpWidget(
          ProviderScope(
            // New scope per edition: a reused scope keeps its first override
            key: ValueKey('${type.name}_$dark'),
            overrides: [
              chassisThemeProvider.overrideWith((ref) => ThemeController(initial: themeState)),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                backgroundColor: themeState.canvasColor,
                body: Center(
                  child: RepaintBoundary(
                    key: key,
                    child: Container(
                      color: themeState.canvasColor,
                      padding: const EdgeInsets.all(14),
                      child: MaterialChassisBox(
                        width: 392,
                        height: 232,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 200,
                              height: 200,
                              child: CustomPaint(
                                painter: ChronoDialPainter(
                                  remainingSeconds: 25 * 60,
                                  targetMinutes: 25,
                                  isRunning: false,
                                  needleColor: themeState.needleColor,
                                  filamentColor: themeState.filamentColor,
                                  outerBezelGradient: themeState.plateGradient,
                                  innerBezelColor: themeState.borderColor,
                                  textureType: themeState.textureType,
                                  isDark: dark,
                                  dialFaceColor: themeState.moduleChassisColor,
                                  darkDialFaceColor: edition.darkDialFace,
                                ),
                                foregroundPainter: ChronoDialHandPainter(
                                  remainingSeconds: 25 * 60,
                                  needleColor: themeState.needleColor,
                                  hubCapColor: dark ? const Color(0xFF22252A) : const Color(0xFF2B2E34),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.runAsync(() async {
          final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$out/${type.name}_${dark ? 'dark' : 'light'}.png').writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }
    }
  }, skip: out == null);
}
