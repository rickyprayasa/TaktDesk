// test/app/theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/takt_colors.dart';
import 'package:takt_desk/app/theme/takt_decorations.dart';
import 'package:takt_desk/app/theme/takt_theme.dart';
import 'package:takt_desk/app/theme/takt_typography.dart';

void main() {
  test('TaktColors contains exact PRD Dieter Rams palette', () {
    expect(TaktColors.chassisObsidian, const Color(0xFF141517));
    expect(TaktColors.basaltSlate, const Color(0xFF24272C));
    expect(TaktColors.warmBone, const Color(0xFFEFECE6));
    expect(TaktColors.thermalCarbon, const Color(0xFF1F2226));
    expect(TaktColors.mutedOchre, const Color(0xFFC85A32));
    expect(TaktColors.filamentAmber, const Color(0xFFD99B59));
    expect(TaktColors.patinaOlive, const Color(0xFF4D5D4B));
  });

  test('TaktTheme produces consistent dark theme', () {
    final theme = TaktTheme.darkThemeData;
    expect(theme.scaffoldBackgroundColor, TaktColors.chassisObsidian);
  });

  test('TaktTheme produces consistent light theme', () {
    final theme = TaktTheme.lightThemeData;
    expect(theme.scaffoldBackgroundColor, TaktColors.lightChassisCanvas);
    expect(theme.brightness, Brightness.light);
  });

  test('TaktTypography defines expected text styles', () {
    expect(TaktTypography.controlLabel.fontFamily, 'sans-serif');
    expect(TaktTypography.receiptHeader.fontFamily, 'monospace');
    expect(TaktTypography.receiptBody.fontFamily, 'monospace');
    expect(TaktTypography.timerCounter.fontFamily, 'monospace');
  });

  test('TaktDecorations defines chassis and receipt decorations', () {
    expect(TaktDecorations.instrumentChassis.color, TaktColors.basaltSlate);
    expect(TaktDecorations.paperReceipt.color, TaktColors.warmBone);
  });
}
