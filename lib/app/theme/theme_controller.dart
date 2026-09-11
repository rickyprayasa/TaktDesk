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
      hasDarkChassis ? const Color(0xFFE8E5DE) : const Color(0xFF1B1E23);

  Color get needleColor => edition.needleColor;

  Color get filamentColor => edition.filamentColor;

  List<Color> get plateGradient =>
      isDarkMode ? edition.plateGradientDark : edition.plateGradientLight;

  Color get rivetColor =>
      isDarkMode ? edition.rivetDark : edition.rivetLight;

  Color get accentColor => edition.accentColor;

  bool get hasDarkChassis =>
      isDarkMode || canvasColor.computeLuminance() < 0.45;

  Color get chassisTextColor =>
      hasDarkChassis ? const Color(0xFFE8E5DE) : const Color(0xFF1B1E23);

  Color get chassisMutedTextColor =>
      hasDarkChassis ? const Color(0x99E8E5DE) : const Color(0x991B1E23);

  HardwareTextureType get textureType => edition.textureType;

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
    if (state.edition.type == type) return true;
    final nextEdition = HardwareEdition.fromType(type);
    if (nextEdition.isPremium && !state.isProUnlocked) {
      return false; // Locked
    }
    state = state.copyWith(edition: nextEdition);
    return true;
  }

  void setProUnlocked(bool unlocked) {
    final shouldRevert = !unlocked && state.edition.isPremium;
    state = state.copyWith(
      isProUnlocked: unlocked,
      edition: shouldRevert ? HardwareEdition.braunClassic : state.edition,
    );
  }
}

final chassisThemeProvider =
    StateNotifierProvider<ThemeController, ChassisThemeState>((ref) {
  return ThemeController();
});
