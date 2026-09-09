import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/hardware_edition.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/database/app_database.dart';
import '../../../core/haptics/haptic_service.dart';

class TodayFocusStats {
  final int completedCount;
  final int totalMinutes;

  const TodayFocusStats({
    this.completedCount = 0,
    this.totalMinutes = 0,
  });

  int get quadrantProgress => completedCount % 4;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodayFocusStats &&
          runtimeType == other.runtimeType &&
          completedCount == other.completedCount &&
          totalMinutes == other.totalMinutes;

  @override
  int get hashCode => completedCount.hashCode ^ totalMinutes.hashCode;
}

class LifetimeFocusStats {
  final int totalSessions;
  final double totalHours;

  const LifetimeFocusStats({
    this.totalSessions = 0,
    this.totalHours = 0.0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LifetimeFocusStats &&
          runtimeType == other.runtimeType &&
          totalSessions == other.totalSessions &&
          totalHours == other.totalHours;

  @override
  int get hashCode => totalSessions.hashCode ^ totalHours.hashCode;
}

class DeskPreferencesState {
  final double soundVolume;
  final bool foleyEnabled;
  final bool hapticsEnabled;
  final bool parallaxEnabled;
  final String selectedEdition;
  final bool isProSimulated;

  const DeskPreferencesState({
    this.soundVolume = 0.8,
    this.foleyEnabled = true,
    this.hapticsEnabled = true,
    this.parallaxEnabled = true,
    this.selectedEdition = 'braunClassic',
    this.isProSimulated = true,
  });

  DeskPreferencesState copyWith({
    double? soundVolume,
    bool? foleyEnabled,
    bool? hapticsEnabled,
    bool? parallaxEnabled,
    String? selectedEdition,
    bool? isProSimulated,
  }) {
    return DeskPreferencesState(
      soundVolume: soundVolume ?? this.soundVolume,
      foleyEnabled: foleyEnabled ?? this.foleyEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      parallaxEnabled: parallaxEnabled ?? this.parallaxEnabled,
      selectedEdition: selectedEdition ?? this.selectedEdition,
      isProSimulated: isProSimulated ?? this.isProSimulated,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeskPreferencesState &&
          runtimeType == other.runtimeType &&
          soundVolume == other.soundVolume &&
          foleyEnabled == other.foleyEnabled &&
          hapticsEnabled == other.hapticsEnabled &&
          parallaxEnabled == other.parallaxEnabled &&
          selectedEdition == other.selectedEdition &&
          isProSimulated == other.isProSimulated;

  @override
  int get hashCode =>
      soundVolume.hashCode ^
      foleyEnabled.hashCode ^
      hapticsEnabled.hashCode ^
      parallaxEnabled.hashCode ^
      selectedEdition.hashCode ^
      isProSimulated.hashCode;
}

class DeskPreferencesController extends StateNotifier<DeskPreferencesState> {
  final AppDatabase? _database;
  final AudioService? _audioService;
  final ThemeController? _themeController;

  DeskPreferencesController([
    this._database,
    this._audioService,
    this._themeController,
  ]) : super(const DeskPreferencesState()) {
    init();
  }

  Future<void> init() async {
    final db = _database;
    if (db == null) return;
    final pref = await (db.select(db.deskPreferences)..limit(1)).getSingleOrNull();
    if (!mounted) return;
    if (pref != null) {
      state = state.copyWith(
        soundVolume: pref.soundVolume,
        parallaxEnabled: pref.parallaxEnabled,
        foleyEnabled: pref.foleyEnabled,
        hapticsEnabled: pref.hapticsEnabled,
        selectedEdition: pref.selectedEdition,
        isProSimulated: pref.isProSimulated,
      );
      _audioService?.setVolume(pref.soundVolume);
      _audioService?.setFoleyEnabled(pref.foleyEnabled);
      HapticService.enabled = pref.hapticsEnabled;
      _themeController?.setProUnlocked(pref.isProSimulated);
      _themeController?.setHardwareEdition(HardwareEdition.fromString(pref.selectedEdition).type);
    } else {
      _audioService?.setVolume(state.soundVolume);
      _audioService?.setFoleyEnabled(state.foleyEnabled);
      HapticService.enabled = state.hapticsEnabled;
    }
  }

  Future<void> setVolume(double val) async {
    final clamped = val.clamp(0.0, 1.0);
    state = state.copyWith(soundVolume: clamped);
    _audioService?.setVolume(clamped);
    await _database?.updatePreferences(soundVolume: clamped);
  }

  Future<void> setFoleyEnabled(bool val) async {
    state = state.copyWith(foleyEnabled: val);
    _audioService?.setFoleyEnabled(val);
    await _database?.updatePreferences(foleyEnabled: val);
  }

  Future<void> setHapticsEnabled(bool val) async {
    state = state.copyWith(hapticsEnabled: val);
    HapticService.enabled = val;
    await _database?.updatePreferences(hapticsEnabled: val);
  }

  Future<void> setParallaxEnabled(bool val) async {
    state = state.copyWith(parallaxEnabled: val);
    await _database?.updatePreferences(parallaxEnabled: val);
  }

  Future<void> setHardwareEdition(HardwareEditionType type) async {
    state = state.copyWith(selectedEdition: type.name);
    _themeController?.setHardwareEdition(type);
    await _database?.updatePreferences(selectedEdition: type.name);
  }

  Future<void> setProSimulated(bool value) async {
    state = state.copyWith(isProSimulated: value);
    _themeController?.setProUnlocked(value);
    await _database?.updatePreferences(isProSimulated: value);
  }

  Future<void> clearAllSessions() async {
    await _database?.clearTimerSessions();
  }
}

final deskPreferencesControllerProvider =
    StateNotifierProvider<DeskPreferencesController, DeskPreferencesState>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final audioService = ref.watch(audioServiceProvider);
  final themeController = ref.read(chassisThemeProvider.notifier);
  return DeskPreferencesController(db, audioService, themeController);
});

final todayFocusStatsProvider = StreamProvider<TodayFocusStats>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchTodayTimerSessions().map((sessions) {
    final completed = sessions.where((s) => s.isFinished).length;
    final totalSeconds = sessions.fold<int>(0, (sum, s) => sum + s.elapsedSeconds);
    final totalMinutes = (totalSeconds / 60).round();
    return TodayFocusStats(
      completedCount: completed,
      totalMinutes: totalMinutes,
    );
  });
});

final lifetimeFocusStatsProvider = StreamProvider<LifetimeFocusStats>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAllTimerSessions().map((sessions) {
    final totalSessions = sessions.where((s) => s.isFinished).length;
    final totalSeconds = sessions.fold<int>(0, (sum, s) => sum + s.elapsedSeconds);
    final totalHours = totalSeconds / 3600.0;
    return LifetimeFocusStats(
      totalSessions: totalSessions,
      totalHours: totalHours,
    );
  });
});
