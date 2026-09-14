import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/soundscape_mixer_state.dart';
import '../domain/vinyl_track.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/sound_effect.dart';
import '../../../core/haptics/haptic_service.dart';
import 'soundscape_mixer_controller.dart';

class VinylState {
  final bool needleOnRecord;
  final double turntableSpeed; // 0.0 to 1.0
  final int selectedTrackIndex;
  final bool isDrawerOpen;

  const VinylState({
    this.needleOnRecord = false,
    this.turntableSpeed = 0.0,
    this.selectedTrackIndex = 0,
    this.isDrawerOpen = false,
  });

  VinylTrack get currentTrack => VinylTrack.presets[selectedTrackIndex];

  VinylState copyWith({
    bool? needleOnRecord,
    double? turntableSpeed,
    int? selectedTrackIndex,
    bool? isDrawerOpen,
  }) {
    return VinylState(
      needleOnRecord: needleOnRecord ?? this.needleOnRecord,
      turntableSpeed: turntableSpeed ?? this.turntableSpeed,
      selectedTrackIndex: selectedTrackIndex ?? this.selectedTrackIndex,
      isDrawerOpen: isDrawerOpen ?? this.isDrawerOpen,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VinylState &&
          runtimeType == other.runtimeType &&
          needleOnRecord == other.needleOnRecord &&
          turntableSpeed == other.turntableSpeed &&
          selectedTrackIndex == other.selectedTrackIndex &&
          isDrawerOpen == other.isDrawerOpen;

  @override
  int get hashCode =>
      needleOnRecord.hashCode ^
      turntableSpeed.hashCode ^
      selectedTrackIndex.hashCode ^
      isDrawerOpen.hashCode;
}

class VinylController extends StateNotifier<VinylState> {
  final AudioService? _audioService;
  final SoundscapeMixerState Function()? _getMixerState;

  VinylController([this._audioService, this._getMixerState]) : super(const VinylState());

  void dropNeedle() {
    state = state.copyWith(needleOnRecord: true, turntableSpeed: 1.0);
    HapticService.mechanicalPress();
    _audioService?.playFoley(SoundEffect.stylusDrop);
    final mixer = _getMixerState?.call();
    _audioService?.startAmbient(
      trackIndex: state.selectedTrackIndex,
      primaryVolume: mixer?.effectivePrimary,
      crackleVolume: mixer?.effectiveCrackle,
      binauralVolume: mixer?.effectiveBinaural,
    );
  }

  void liftNeedle() {
    state = state.copyWith(needleOnRecord: false, turntableSpeed: 0.0);
    HapticService.mechanicalPress();
    _audioService?.playFoley(SoundEffect.stylusStop);
    _audioService?.stopAmbient();
  }

  void toggleNeedle() {
    if (state.needleOnRecord) {
      liftNeedle();
    } else {
      dropNeedle();
    }
  }

  bool selectTrack(int index, {bool isPro = false}) {
    if (index < 0 || index >= VinylTrack.presets.length) {
      return false;
    }
    final track = VinylTrack.presets[index];
    if (track.isPremium && !isPro) {
      return false;
    }
    state = state.copyWith(selectedTrackIndex: index);
    HapticService.dialTick();
    _audioService?.playFoley(SoundEffect.discLoad);
    if (state.needleOnRecord) {
      final mixer = _getMixerState?.call();
      _audioService?.startAmbient(
        trackIndex: index,
        primaryVolume: mixer?.effectivePrimary,
        crackleVolume: mixer?.effectiveCrackle,
        binauralVolume: mixer?.effectiveBinaural,
      );
    }
    return true;
  }

  void revertIfProRevoked() {
    if (state.currentTrack.isPremium) {
      selectTrack(0, isPro: true);
    }
  }

  void toggleDrawer() {
    final nextOpen = !state.isDrawerOpen;
    state = state.copyWith(isDrawerOpen: nextOpen);
    HapticService.selectionClick();
    _audioService?.playFoley(
      nextOpen ? SoundEffect.drawerSlide : SoundEffect.drawerLatch,
    );
  }

  void setDrawerOpen(bool open) {
    if (state.isDrawerOpen != open) {
      state = state.copyWith(isDrawerOpen: open);
      HapticService.selectionClick();
      _audioService?.playFoley(
        open ? SoundEffect.drawerSlide : SoundEffect.drawerLatch,
      );
    }
  }
}

final vinylProvider = StateNotifierProvider<VinylController, VinylState>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return VinylController(audioService, () => ref.read(soundscapeMixerProvider));
});

final vinylControllerProvider = vinylProvider;
