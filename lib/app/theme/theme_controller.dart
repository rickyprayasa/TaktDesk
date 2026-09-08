import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'takt_colors.dart';

class ChassisThemeState {
  final bool isDarkMode;

  const ChassisThemeState({this.isDarkMode = true});

  Color get canvasColor =>
      isDarkMode ? TaktColors.chassisObsidian : TaktColors.lightChassisCanvas;

  Color get moduleChassisColor =>
      isDarkMode ? TaktColors.basaltSlate : TaktColors.lightChassisBasalt;

  Color get borderColor =>
      isDarkMode ? TaktColors.slateBorder : TaktColors.lightChassisBorder;

  Color get textColor =>
      isDarkMode ? TaktColors.warmBone : const Color(0xFF141618);
}

class ThemeController extends StateNotifier<ChassisThemeState> {
  ThemeController() : super(const ChassisThemeState());

  void toggleTheme() {
    state = ChassisThemeState(isDarkMode: !state.isDarkMode);
  }

  void setDarkMode(bool value) {
    state = ChassisThemeState(isDarkMode: value);
  }
}

final chassisThemeProvider =
    StateNotifierProvider<ThemeController, ChassisThemeState>((ref) {
  return ThemeController();
});
