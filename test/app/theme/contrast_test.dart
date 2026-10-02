import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/hardware_edition.dart';
import 'package:takt_desk/app/theme/takt_colors.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';

double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// WCAG 2.x AA for small text. The chassis labels are 7-9 px monospace.
const _aa = 4.5;

void main() {
  test('chassis text and muted text meet WCAG AA on every edition surface', () {
    for (final type in HardwareEditionType.values) {
      final edition = HardwareEdition.fromType(type);
      for (final dark in [false, true]) {
        final s = ChassisThemeState(isDarkMode: dark, edition: edition);
        final surfaces = [s.canvasColor, s.moduleChassisColor, ...s.plateGradient];
        for (final bg in surfaces) {
          final muted = Color.alphaBlend(s.chassisMutedTextColor, bg);
          expect(_ratio(s.chassisTextColor, bg), greaterThanOrEqualTo(_aa),
              reason: '${type.name} dark=$dark text on $bg');
          expect(_ratio(muted, bg), greaterThanOrEqualTo(_aa),
              reason: '${type.name} dark=$dark muted text on $bg');
        }
      }
    }
  });

  test('amber text colour meets WCAG AA on the light and dark panels', () {
    const lightPanels = [Color(0xFFEDEAE2), Color(0xFFE3E0D8), TaktColors.lightChassisCanvas];
    for (final bg in lightPanels) {
      expect(_ratio(TaktColors.amberText(false), bg), greaterThanOrEqualTo(_aa), reason: '$bg');
    }
    const darkPanels = [TaktColors.basaltSlate, TaktColors.chassisObsidian];
    for (final bg in darkPanels) {
      expect(_ratio(TaktColors.amberText(true), bg), greaterThanOrEqualTo(_aa), reason: '$bg');
    }
  });
}
