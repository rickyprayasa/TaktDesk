import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/hardware_edition.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/config/app_security_config.dart';
import '../../../core/database/app_database.dart';
import '../../../core/haptics/haptic_service.dart';
import '../../analytics/domain/focus_session_rules.dart';
import '../../vinyl/presentation/vinyl_controller.dart';

class TodayFocusStats {
  /// Completed Pomodoro cycles today (see FocusSessionRules).
  final int completedCount;

  /// Focus minutes today, lockdown-only sessions included.
  final int totalMinutes;

  /// Consecutive days with at least one completed cycle.
  final int streakDays;

  const TodayFocusStats({
    this.completedCount = 0,
    this.totalMinutes = 0,
    this.streakDays = 0,
  });

  int get quadrantProgress => completedCount % 4;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodayFocusStats &&
          runtimeType == other.runtimeType &&
          completedCount == other.completedCount &&
          totalMinutes == other.totalMinutes &&
          streakDays == other.streakDays;

  @override
  int get hashCode => Object.hash(completedCount, totalMinutes, streakDays);
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

  /// Completed focus cycles per day the user aims for (1–12, default 4).
  final int dailyGoalCycles;

  /// Desk clock: keep the screen on while a timer runs, dimmed after a minute untouched.
  final bool deskClockMode;

  const DeskPreferencesState({
    this.soundVolume = 0.8,
    this.foleyEnabled = true,
    this.hapticsEnabled = true,
    this.parallaxEnabled = true,
    this.selectedEdition = 'braunClassic',
    this.isProSimulated = AppSecurityConfig.isProSimulationEnabled,
    this.alarmChimeId = 'braunBell',
    this.autoUnlockMonastic = false,
    this.dailyGoalCycles = 4,
    this.deskClockMode = false,
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
    int? dailyGoalCycles,
    bool? deskClockMode,
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
      dailyGoalCycles: dailyGoalCycles ?? this.dailyGoalCycles,
      deskClockMode: deskClockMode ?? this.deskClockMode,
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
          autoUnlockMonastic == other.autoUnlockMonastic &&
          dailyGoalCycles == other.dailyGoalCycles &&
          deskClockMode == other.deskClockMode;

  @override
  int get hashCode =>
      soundVolume.hashCode ^
      foleyEnabled.hashCode ^
      hapticsEnabled.hashCode ^
      parallaxEnabled.hashCode ^
      selectedEdition.hashCode ^
      isProSimulated.hashCode ^
      alarmChimeId.hashCode ^
      autoUnlockMonastic.hashCode ^
      dailyGoalCycles.hashCode ^
      deskClockMode.hashCode;
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
    ready = init();
  }

  /// Completes once the saved preferences (theme, edition, haptics, sound) are
  /// applied. The opening screen waits on this so it never shows the wrong
  /// finish or fires haptics the user switched off.
  late final Future<void> ready;

  Future<void> init() async {
    final db = _database;
    if (db == null) return;
    final pref = await (db.select(db.deskPreferences)..limit(1)).getSingleOrNull();
    if (!mounted) return;
    if (pref != null) {
      final effectivePro = AppSecurityConfig.isProSimulationEnabled
          ? pref.isProSimulated
          : false;
      _themeController?.setDarkMode(pref.isDarkMode);
      _themeController?.setProUnlocked(effectivePro);
      if (!effectivePro) {
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
        isProSimulated: effectivePro,
        alarmChimeId: pref.alarmChimeId,
        autoUnlockMonastic: pref.autoUnlockMonastic,
        dailyGoalCycles: pref.dailyGoalCycles,
        deskClockMode: pref.deskClockMode,
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

  /// Dark/light chassis finish, persisted so it survives a restart.
  Future<void> setDarkMode(bool value) async {
    _themeController?.setDarkMode(value);
    await _database?.updatePreferences(isDarkMode: value);
  }

  Future<void> toggleDarkMode() =>
      setDarkMode(!(_themeController?.state.isDarkMode ?? true));

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

  static const int minDailyGoal = 1;
  static const int maxDailyGoal = 12;

  Future<void> setDailyGoalCycles(int cycles) async {
    final clamped = cycles.clamp(minDailyGoal, maxDailyGoal);
    if (clamped == state.dailyGoalCycles) return;
    state = state.copyWith(dailyGoalCycles: clamped);
    await _database?.updatePreferences(dailyGoalCycles: clamped);
  }

  Future<void> setAlarmChime(String chimeId) async {
    state = state.copyWith(alarmChimeId: chimeId);
    await _database?.updatePreferences(alarmChimeId: chimeId);
  }

  Future<void> setAutoUnlockMonastic(bool value) async {
    state = state.copyWith(autoUnlockMonastic: value);
    await _database?.updatePreferences(autoUnlockMonastic: value);
  }

  Future<void> setDeskClockMode(bool value) async {
    state = state.copyWith(deskClockMode: value);
    await _database?.updatePreferences(deskClockMode: value);
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
  // All sessions (not only today's) so the streak can look back.
  return db.watchAllTimerSessions().map((sessions) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day + 1);
    final today = sessions.where((s) => !s.startedAt.isBefore(startOfDay) && s.startedAt.isBefore(endOfDay));
    final completed = today.where((s) => s.isCompletedCycle).length;
    final totalSeconds = today.fold<int>(0, (sum, s) => sum + s.elapsedSeconds);
    return TodayFocusStats(
      completedCount: completed,
      totalMinutes: (totalSeconds / 60).round(),
      streakDays: FocusStreak.compute(sessions, now).current,
    );
  });
});

final lifetimeFocusStatsProvider = StreamProvider<LifetimeFocusStats>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAllTimerSessions().map((sessions) {
    final totalSessions = sessions.where((s) => s.isCompletedCycle).length;
    final totalSeconds = sessions.fold<int>(0, (sum, s) => sum + s.elapsedSeconds);
    final totalHours = totalSeconds / 3600.0;
    return LifetimeFocusStats(
      totalSessions: totalSessions,
      totalHours: totalHours,
    );
  });
});
