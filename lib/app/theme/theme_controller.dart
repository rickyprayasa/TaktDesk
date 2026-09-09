import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'hardware_edition.dart';

class ChassisThemeState {
  final bool isDarkMode;
  final HardwareEdition edition;
  final bool isProUnlocked;

  const ChassisThemeState({
    this.isDarkMode = true,
    this.edition = HardwareEdition.braunClassic,
    this.isProUnlocked = true,
  });

  Color get canvasColor =>
      isDarkMode ? edition.darkCanvas : edition.lightCanvas;

  Color get moduleChassisColor =>
      isDarkMode ? edition.darkModuleBg : edition.lightModuleBg;

  Color get borderColor =>
      isDarkMode ? edition.darkBorder : edition.lightBorder;

  Color get textColor =>
      isDarkMode ? edition.lightCanvas : edition.darkCanvas;

  Color get needleColor => edition.needleColor;

  Color get filamentColor => edition.filamentColor;

  ChassisThemeState copyWith({
    bool? isDarkMode,
    HardwareEdition? edition,
    bool? isProUnlocked,
  }) {
    return ChassisThemeState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      edition: edition ?? this.edition,
      isProUnlocked: isProUnlocked ?? this.isProUnlocked,
    );
  }
}

class ThemeController extends StateNotifier<ChassisThemeState> {
  ThemeController({ChassisThemeState? initial})
      : super(initial ?? const ChassisThemeState());

  void toggleTheme() {
    state = state.copyWith(isDarkMode: !state.isDarkMode);
  }

  void setDarkMode(bool value) {
    state = state.copyWith(isDarkMode: value);
  }

  bool setHardwareEdition(HardwareEditionType type) {
    final nextEdition = HardwareEdition.fromType(type);
    if (nextEdition.isPremium && !state.isProUnlocked) {
      return false; // Locked
    }
    state = state.copyWith(edition: nextEdition);
    return true;
  }

  void setProUnlocked(bool unlocked) {
    state = state.copyWith(isProUnlocked: unlocked);
    // If locked and current edition is premium, revert to braunClassic
    if (!unlocked && state.edition.isPremium) {
      state = state.copyWith(edition: HardwareEdition.braunClassic);
    }
  }
}

final chassisThemeProvider =
    StateNotifierProvider<ThemeController, ChassisThemeState>((ref) {
  return ThemeController();
});
