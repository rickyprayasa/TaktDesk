import 'package:flutter/material.dart';
import 'takt_colors.dart';

class TaktTheme {
  const TaktTheme._();

  static ThemeData get darkThemeData {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: TaktColors.chassisObsidian,
      colorScheme: const ColorScheme.dark(
        primary: TaktColors.mutedOchre,
        secondary: TaktColors.filamentAmber,
        surface: TaktColors.basaltSlate,
      ),
    );
  }
}
