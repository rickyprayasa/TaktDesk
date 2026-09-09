import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  const DeskPreferencesState({
    this.soundVolume = 0.8,
    this.foleyEnabled = true,
    this.hapticsEnabled = true,
    this.parallaxEnabled = true,
  });

  DeskPreferencesState copyWith({
    double? soundVolume,
    bool? foleyEnabled,
    bool? hapticsEnabled,
    bool? parallaxEnabled,
  }) {
    return DeskPreferencesState(
      soundVolume: soundVolume ?? this.soundVolume,
      foleyEnabled: foleyEnabled ?? this.foleyEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      parallaxEnabled: parallaxEnabled ?? this.parallaxEnabled,
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
          parallaxEnabled == other.parallaxEnabled;

  @override
  int get hashCode =>
      soundVolume.hashCode ^
      foleyEnabled.hashCode ^
      hapticsEnabled.hashCode ^
      parallaxEnabled.hashCode;
}

class DeskPreferencesController extends StateNotifier<DeskPreferencesState> {
  final AppDatabase? _database;
  final AudioService? _audioService;

  DeskPreferencesController([this._database, this._audioService])
      : super(const DeskPreferencesState()) {
    init();
  }

  Future<void> init() async {
    final db = _database;
    if (db == null) return;
    final pref = await (db.select(db.deskPreferences)..limit(1)).getSingleOrNull();
    if (pref != null) {
      state = state.copyWith(
        soundVolume: pref.soundVolume,
        parallaxEnabled: pref.parallaxEnabled,
        foleyEnabled: pref.foleyEnabled,
        hapticsEnabled: pref.hapticsEnabled,
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
    state = state.copyWith(soundVolume: val);
    _audioService?.setVolume(val);
    await _database?.updatePreferences(soundVolume: val);
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

  Future<void> clearAllSessions() async {
    await _database?.clearTimerSessions();
  }
}

final deskPreferencesControllerProvider =
    StateNotifierProvider<DeskPreferencesController, DeskPreferencesState>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final audioService = ref.watch(audioServiceProvider);
  return DeskPreferencesController(db, audioService);
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
