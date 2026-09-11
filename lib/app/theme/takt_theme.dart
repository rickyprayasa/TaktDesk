import 'package:flutter/material.dart';
import 'takt_colors.dart';

class TaktTheme {
  const TaktTheme._();

  static final ThemeData lightThemeData = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: TaktColors.lightChassisCanvas,
    colorScheme: const ColorScheme.light(
      primary: TaktColors.mutedOchre,
      secondary: TaktColors.filamentAmber,
      surface: TaktColors.lightChassisFaceplate,
    ),
  );

  static final ThemeData darkThemeData = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: TaktColors.chassisObsidian,
    colorScheme: const ColorScheme.dark(
      primary: TaktColors.mutedOchre,
      secondary: TaktColors.filamentAmber,
      surface: TaktColors.basaltSlate,
    ),
  );
}
