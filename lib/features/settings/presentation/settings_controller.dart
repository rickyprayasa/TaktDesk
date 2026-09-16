import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/hardware_edition.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/database/app_database.dart';
import '../../../core/haptics/haptic_service.dart';
import '../../vinyl/presentation/vinyl_controller.dart';

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
  final String alarmChimeId;
  final bool autoUnlockMonastic;

  const DeskPreferencesState({
    this.soundVolume = 0.8,
    this.foleyEnabled = true,
    this.hapticsEnabled = true,
    this.parallaxEnabled = true,
    this.selectedEdition = 'braunClassic',
    this.isProSimulated = true,
    this.alarmChimeId = 'braunBell',
    this.autoUnlockMonastic = false,
  });

  DeskPreferencesState copyWith({
    double? soundVolume,
    bool? foleyEnabled,
    bool? hapticsEnabled,
    bool? parallaxEnabled,
    String? selectedEdition,
    bool? isProSimulated,
    String? alarmChimeId,
    bool? autoUnlockMonastic,
  }) {
    return DeskPreferencesState(
      soundVolume: soundVolume ?? this.soundVolume,
      foleyEnabled: foleyEnabled ?? this.foleyEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      parallaxEnabled: parallaxEnabled ?? this.parallaxEnabled,
      selectedEdition: selectedEdition ?? this.selectedEdition,
      isProSimulated: isProSimulated ?? this.isProSimulated,
      alarmChimeId: alarmChimeId ?? this.alarmChimeId,
      autoUnlockMonastic: autoUnlockMonastic ?? this.autoUnlockMonastic,
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
          isProSimulated == other.isProSimulated &&
          alarmChimeId == other.alarmChimeId &&
          autoUnlockMonastic == other.autoUnlockMonastic;

  @override
  int get hashCode =>
      soundVolume.hashCode ^
      foleyEnabled.hashCode ^
      hapticsEnabled.hashCode ^
      parallaxEnabled.hashCode ^
      selectedEdition.hashCode ^
      isProSimulated.hashCode ^
      alarmChimeId.hashCode ^
      autoUnlockMonastic.hashCode;
}

class DeskPreferencesController extends StateNotifier<DeskPreferencesState> {
  final AppDatabase? _database;
  final AudioService? _audioService;
  final ThemeController? _themeController;
  final VinylController? _vinylController;

  DeskPreferencesController([
    this._database,
    this._audioService,
    this._themeController,
    this._vinylController,
  ]) : super(const DeskPreferencesState()) {
    init();
  }

  Future<void> init() async {
    final db = _database;
    if (db == null) return;
    final pref = await (db.select(db.deskPreferences)..limit(1)).getSingleOrNull();
    if (!mounted) return;
    if (pref != null) {
      _themeController?.setProUnlocked(pref.isProSimulated);
      if (!pref.isProSimulated) {
        _vinylController?.revertIfProRevoked();
      }
      final applied = _themeController?.setHardwareEdition(
        HardwareEdition.fromString(pref.selectedEdition).type,
      ) ?? true;
      final effectiveEdition = applied
          ? pref.selectedEdition
          : (_themeController?.state.edition.type.name ?? HardwareEditionType.braunClassic.name);

      state = state.copyWith(
        soundVolume: pref.soundVolume,
        parallaxEnabled: pref.parallaxEnabled,
        foleyEnabled: pref.foleyEnabled,
        hapticsEnabled: pref.hapticsEnabled,
        selectedEdition: effectiveEdition,
        isProSimulated: pref.isProSimulated,
        alarmChimeId: pref.alarmChimeId,
        autoUnlockMonastic: pref.autoUnlockMonastic,
      );
      _audioService?.setVolume(pref.soundVolume);
      _audioService?.setFoleyEnabled(pref.foleyEnabled);
      HapticService.enabled = pref.hapticsEnabled;
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

  Future<bool> setHardwareEdition(HardwareEditionType type) async {
    final applied = _themeController?.setHardwareEdition(type) ?? true;
    if (!applied) return false;
    state = state.copyWith(selectedEdition: type.name);
    await _database?.updatePreferences(selectedEdition: type.name);
    return true;
  }

  Future<void> setProSimulated(bool value) async {
    _themeController?.setProUnlocked(value);
    if (!value) {
      _vinylController?.revertIfProRevoked();
    }
    final activeEdition = _themeController?.state.edition.type.name ?? state.selectedEdition;
    state = state.copyWith(
      isProSimulated: value,
      selectedEdition: activeEdition,
    );
    await _database?.updatePreferences(
      isProSimulated: value,
      selectedEdition: activeEdition,
    );
  }

  Future<void> setAlarmChime(String chimeId) async {
    state = state.copyWith(alarmChimeId: chimeId);
    await _database?.updatePreferences(alarmChimeId: chimeId);
  }

  Future<void> setAutoUnlockMonastic(bool value) async {
    state = state.copyWith(autoUnlockMonastic: value);
    await _database?.updatePreferences(autoUnlockMonastic: value);
  }

  Future<void> clearAllSessions() async {
    await _database?.clearTimerSessions();
  }
}

final deskPreferencesControllerProvider =
    StateNotifierProvider<DeskPreferencesController, DeskPreferencesState>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final audioService = ref.watch(audioServiceProvider);
  final themeController = ref.watch(chassisThemeProvider.notifier);
  final vinylController = ref.watch(vinylProvider.notifier);
  return DeskPreferencesController(db, audioService, themeController, vinylController);
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
