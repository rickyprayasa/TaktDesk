import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sound_effect.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(service.dispose);
  return service;
});

class AudioService {
  final bool isMock;
  bool _initialized = false;
  double _volume = 0.8;
  int _activeTrackIndex = 0;
  bool _isAmbientPlaying = false;

  AudioService({this.isMock = false});

  bool get isInitialized => _initialized;
  double get volume => _volume;
  bool get isAmbientPlaying => _isAmbientPlaying;
  int get activeTrackIndex => _activeTrackIndex;

  Future<void> init() async {
    _initialized = true;
  }

  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
  }

  void playFoley(SoundEffect effect) {
    if (!_initialized) return;
    // When assets are provided, triggers flutter_soloud sample playback
  }

  void startAmbient(int trackIndex) {
    if (!_initialized) return;
    _activeTrackIndex = trackIndex;
    _isAmbientPlaying = true;
  }

  void stopAmbient() {
    _isAmbientPlaying = false;
  }

  void dispose() {
    _initialized = false;
  }
}
