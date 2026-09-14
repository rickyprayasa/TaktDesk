import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/database/app_database.dart';
import '../domain/soundscape_mixer_state.dart';

final soundscapeMixerProvider =
    StateNotifierProvider<SoundscapeMixerController, SoundscapeMixerState>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final audioService = ref.watch(audioServiceProvider);
  return SoundscapeMixerController(db, audioService);
});

class SoundscapeMixerController extends StateNotifier<SoundscapeMixerState> {
  final AppDatabase _db;
  final AudioService _audioService;
  Timer? _debounceTimer;

  SoundscapeMixerController(this._db, this._audioService)
      : super(const SoundscapeMixerState()) {
    _loadFromDatabase();
  }

  Future<void> _loadFromDatabase() async {
    try {
      final prefs = await _db.getDeskPreferences();
      if (!mounted) return;
      if (prefs != null) {
        state = SoundscapeMixerState(
          primaryVolume: prefs.primaryVolume,
          crackleVolume: prefs.crackleVolume,
          binauralVolume: prefs.binauralVolume,
          isPrimaryMuted: prefs.primaryMuted,
          isCrackleMuted: prefs.crackleMuted,
          isBinauralMuted: prefs.binauralMuted,
        );
        _syncToAudioService();
      }
    } catch (_) {}
  }

  void _syncToAudioService() {
    _audioService.setMixerLevels(
      primaryVolume: state.effectivePrimary,
      crackleVolume: state.effectiveCrackle,
      binauralVolume: state.effectiveBinaural,
    );
  }

  void setPrimaryVolume(double val) {
    state = state.copyWith(primaryVolume: val.clamp(0.0, 1.0));
    _syncToAudioService();
    _persist(immediate: false);
  }

  void setCrackleVolume(double val) {
    state = state.copyWith(crackleVolume: val.clamp(0.0, 1.0));
    _syncToAudioService();
    _persist(immediate: false);
  }

  void setBinauralVolume(double val) {
    state = state.copyWith(binauralVolume: val.clamp(0.0, 1.0));
    _syncToAudioService();
    _persist(immediate: false);
  }

  void togglePrimaryMute() {
    state = state.copyWith(isPrimaryMuted: !state.isPrimaryMuted);
    _syncToAudioService();
    _persist(immediate: true);
  }

  void toggleCrackleMute() {
    state = state.copyWith(isCrackleMuted: !state.isCrackleMuted);
    _syncToAudioService();
    _persist(immediate: true);
  }

  void toggleBinauralMute() {
    state = state.copyWith(isBinauralMuted: !state.isBinauralMuted);
    _syncToAudioService();
    _persist(immediate: true);
  }

  void commitPersist() {
    _persist(immediate: true);
  }

  void _persist({bool immediate = false}) {
    if (immediate) {
      _debounceTimer?.cancel();
      _debounceTimer = null;
      _executePersist();
      return;
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _executePersist();
    });
  }

  Future<void> _executePersist() async {
    try {
      await _db.updateDeskPreferences(
        primaryVolume: state.primaryVolume,
        crackleVolume: state.crackleVolume,
        binauralVolume: state.binauralVolume,
        primaryMuted: state.isPrimaryMuted,
        crackleMuted: state.isCrackleMuted,
        binauralMuted: state.isBinauralMuted,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
