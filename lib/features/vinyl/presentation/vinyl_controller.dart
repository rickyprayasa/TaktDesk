import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/vinyl_track.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/sound_effect.dart';
import '../../../core/haptics/haptic_service.dart';

class VinylState {
  final bool needleOnRecord;
  final double turntableSpeed; // 0.0 to 1.0
  final int selectedTrackIndex;

  const VinylState({
    this.needleOnRecord = false,
    this.turntableSpeed = 0.0,
    this.selectedTrackIndex = 0,
  });

  VinylTrack get currentTrack => VinylTrack.presets[selectedTrackIndex];

  VinylState copyWith({
    bool? needleOnRecord,
    double? turntableSpeed,
    int? selectedTrackIndex,
  }) {
    return VinylState(
      needleOnRecord: needleOnRecord ?? this.needleOnRecord,
      turntableSpeed: turntableSpeed ?? this.turntableSpeed,
      selectedTrackIndex: selectedTrackIndex ?? this.selectedTrackIndex,
    );
  }
}

class VinylController extends StateNotifier<VinylState> {
  final AudioService? _audioService;

  VinylController([this._audioService]) : super(const VinylState());

  void dropNeedle() {
    state = state.copyWith(needleOnRecord: true, turntableSpeed: 1.0);
    HapticService.mechanicalPress();
    _audioService?.playFoley(SoundEffect.stylusDrop);
    _audioService?.startAmbient(state.selectedTrackIndex);
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
    if (state.needleOnRecord) {
      _audioService?.startAmbient(index);
    }
    return true;
  }

  void revertIfProRevoked() {
    if (state.currentTrack.isPremium) {
      selectTrack(0, isPro: true);
    }
  }
}

final vinylProvider = StateNotifierProvider<VinylController, VinylState>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return VinylController(audioService);
});

final vinylControllerProvider = vinylProvider;
