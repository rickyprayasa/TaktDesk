import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_visibility.dart';
import 'sound_effect.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  service.init();
  ref.onDispose(service.dispose);
  return service;
});

class AudioService {
  static const MethodChannel channel = MethodChannel('com.takt.desk/audio');

  final bool isMock;
  bool _initialized = false;
  double _volume = 0.8;
  int _activeTrackIndex = 0;
  bool _isAmbientPlaying = false;
  bool _foleyEnabled = true;

  AudioService({this.isMock = false});

  bool get isInitialized => _initialized;
  double get volume => _volume;
  bool get isAmbientPlaying => _isAmbientPlaying;
  int get activeTrackIndex => _activeTrackIndex;
  bool get foleyEnabled => _foleyEnabled;

  Future<void> init() async {
    _initialized = true;
  }

  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    if (!isMock && _initialized) {
      channel.invokeMethod('setVolume', {'volume': _volume}).catchError((_) {});
    }
  }

  void setFoleyEnabled(bool val) {
    _foleyEnabled = val;
  }

  void playFoley(SoundEffect effect) {
    if (!_initialized || !_foleyEnabled || !appIsVisible) return;
    if (!isMock) {
      channel.invokeMethod('playFoley', {'effect': effect.name}).catchError((_) {});
    }
  }

  void play(SoundEffect effect) => playFoley(effect);

  /// The real end-of-session alarm (alarm stream, de-duplicated natively).
  void playAlarmChime(String chimeId) {
    if (!_initialized) return;
    if (!isMock) {
      channel.invokeMethod('playAlarmChime', {'chimeId': chimeId}).catchError((_) {});
    }
  }

  /// Audition from Settings: plays immediately on every tap, cuts off the
  /// previous preview, and follows the media stream at the master volume.
  void previewAlarmChime(String chimeId) {
    if (!_initialized) return;
    if (!isMock) {
      channel.invokeMethod('playAlarmChime', {
        'chimeId': chimeId,
        'preview': true,
        'volume': _volume,
      }).catchError((_) {});
    }
  }

  void startAmbient({
    required int trackIndex,
    String? assetPath,
    double? primaryVolume,
    double? crackleVolume,
    double? binauralVolume,
  }) {
    if (!_initialized) return;
    _activeTrackIndex = trackIndex;
    _isAmbientPlaying = true;
    if (!isMock) {
      channel.invokeMethod('startAmbient', {
        'trackIndex': trackIndex,
        'volume': primaryVolume ?? _volume,
        if (assetPath != null) 'assetPath': assetPath,
      }).catchError((_) {});
    }
  }

  void stopAmbient() {
    _isAmbientPlaying = false;
    if (!isMock) {
      channel.invokeMethod('stopAmbient').catchError((_) {});
    }
  }

  void dispose() {
    stopAmbient();
    _initialized = false;
  }
}
