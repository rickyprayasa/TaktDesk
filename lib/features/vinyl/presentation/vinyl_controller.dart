import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/vinyl_track.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/sound_effect.dart';
import '../../../core/haptics/haptic_service.dart';
import '../../../core/services/media_notification_service.dart';

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
  final MediaNotificationService? _mediaNotificationService;

  VinylController([this._audioService, this._mediaNotificationService])
      : super(const VinylState());

  void dropNeedle() {
    state = state.copyWith(needleOnRecord: true, turntableSpeed: 1.0);
    HapticService.mechanicalPress();
    _audioService?.playFoley(SoundEffect.stylusDrop);
    _audioService?.startAmbient(trackIndex: state.selectedTrackIndex);
    if (_mediaNotificationService?.isActive == true) {
      _mediaNotificationService?.updatePlaybackState(
        isPlaying: true,
        trackIndex: state.selectedTrackIndex,
        trackName: state.currentTrack.name,
      );
    } else {
      final phase = _mediaNotificationService?.lastPhase ?? 'focus';
      final remainingSeconds =
          _mediaNotificationService?.lastRemainingSeconds ?? 1500;
      final cycleCount = _mediaNotificationService?.lastCycleCount ?? 1;
      _mediaNotificationService?.startNotification(
        trackIndex: state.selectedTrackIndex,
        trackName: state.currentTrack.name,
        isPlaying: true,
        phase: phase,
        remainingSeconds: remainingSeconds,
        cycleCount: cycleCount,
      );
    }
  }

  void liftNeedle() {
    state = state.copyWith(needleOnRecord: false, turntableSpeed: 0.0);
    HapticService.mechanicalPress();
    _audioService?.playFoley(SoundEffect.stylusStop);
    _audioService?.stopAmbient();
    if (_mediaNotificationService?.isActive == true) {
      _mediaNotificationService?.updatePlaybackState(
        isPlaying: false,
        trackIndex: state.selectedTrackIndex,
        trackName: state.currentTrack.name,
      );
    }
  }

  void toggleNeedle() {
    if (state.needleOnRecord) {
      liftNeedle();
    } else {
      dropNeedle();
    }
  }

  void togglePlayback() => toggleNeedle();

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
      _audioService?.startAmbient(trackIndex: index);
    }
    if (_mediaNotificationService?.isActive == true) {
      _mediaNotificationService?.updatePlaybackState(
        isPlaying: state.needleOnRecord,
        trackIndex: index,
        trackName: track.name,
      );
    }
    return true;
  }

  bool selectNextTrack({bool isPro = false}) {
    final count = VinylTrack.presets.length;
    for (int i = 1; i <= count; i++) {
      final next = (state.selectedTrackIndex + i) % count;
      if (selectTrack(next, isPro: isPro)) {
        return true;
      }
    }
    return false;
  }

  bool selectPreviousTrack({bool isPro = false}) {
    final count = VinylTrack.presets.length;
    for (int i = 1; i <= count; i++) {
      final prev = (state.selectedTrackIndex - i + count) % count;
      if (selectTrack(prev, isPro: isPro)) {
        return true;
      }
    }
    return false;
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
  final mediaNotificationService = ref.watch(mediaNotificationServiceProvider);
  return VinylController(audioService, mediaNotificationService);
});

final vinylControllerProvider = vinylProvider;
