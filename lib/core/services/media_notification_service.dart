import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/presentation/settings_controller.dart';
import '../../features/vinyl/presentation/vinyl_controller.dart';

final Provider<MediaNotificationService> mediaNotificationServiceProvider =
    Provider<MediaNotificationService>((ref) {
  final service = MediaNotificationService();
  service.addListener((action) {
    final vinylNotifier = ref.read(vinylProvider.notifier);
    bool isPro = false;
    try {
      isPro = ref.read(deskPreferencesControllerProvider).isProSimulated;
    } catch (_) {}

    switch (action) {
      case 'play':
        vinylNotifier.dropNeedle();
        break;
      case 'pause':
        vinylNotifier.liftNeedle();
        break;
      case 'next':
        vinylNotifier.selectNextTrack(isPro: isPro);
        break;
      case 'previous':
        vinylNotifier.selectPreviousTrack(isPro: isPro);
        break;
      case 'stop':
        vinylNotifier.liftNeedle();
        service.stopNotification();
        break;
    }
  });

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

class MediaNotificationService {
  static const MethodChannel channel =
      MethodChannel('com.zykl.app/media_notification');

  final List<void Function(String action)> _listeners = [];
  final StreamController<String> _actionController =
      StreamController<String>.broadcast();
  bool _handlerInitialized = false;
  bool _isActive = false;

  int _lastTrackIndex = 0;
  String _lastTrackName = 'LO-FI RAIN';
  bool _lastIsPlaying = false;
  double _lastVolume = 0.8;
  String _lastPhase = 'focus';
  int _lastRemainingSeconds = 1500;
  int _lastCycleCount = 1;

  MediaNotificationService() {
    _ensureHandler();
  }

  bool get isActive => _isActive;
  int get lastTrackIndex => _lastTrackIndex;
  String get lastTrackName => _lastTrackName;
  bool get lastIsPlaying => _lastIsPlaying;
  double get lastVolume => _lastVolume;
  String get lastPhase => _lastPhase;
  int get lastRemainingSeconds => _lastRemainingSeconds;
  int get lastCycleCount => _lastCycleCount;

  void _ensureHandler() {
    if (_handlerInitialized) return;
    _handlerInitialized = true;
    channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onMediaControlAction') {
      final args = call.arguments;
      final action = args is Map ? args['action'] as String? : null;
      if (action != null && action.isNotEmpty) {
        if (!_actionController.isClosed) {
          _actionController.add(action);
        }
        for (final listener in List<void Function(String)>.from(_listeners)) {
          listener(action);
        }
      }
    }
    return null;
  }

  void addListener(void Function(String action) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(String action) listener) {
    _listeners.remove(listener);
  }

  Stream<String> get onMediaAction => _actionController.stream;

  Future<bool> startNotification({
    required int trackIndex,
    required String trackName,
    required bool isPlaying,
    double volume = 0.8,
    required String phase,
    required int remainingSeconds,
    required int cycleCount,
  }) async {
    _lastTrackIndex = trackIndex;
    _lastTrackName = trackName;
    _lastIsPlaying = isPlaying;
    _lastVolume = volume;
    _lastPhase = phase;
    _lastRemainingSeconds = remainingSeconds;
    _lastCycleCount = cycleCount;

    try {
      final res = await channel.invokeMethod<bool>('startMediaNotification', {
        'trackIndex': trackIndex,
        'trackName': trackName,
        'isPlaying': isPlaying,
        'volume': volume,
        'phase': phase,
        'remainingSeconds': remainingSeconds,
        'cycleCount': cycleCount,
      });
      final success = res ?? false;
      if (success) {
        _isActive = true;
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updatePlaybackState({
    required bool isPlaying,
    required int trackIndex,
    required String trackName,
    double volume = 0.8,
  }) async {
    _lastIsPlaying = isPlaying;
    _lastTrackIndex = trackIndex;
    _lastTrackName = trackName;
    _lastVolume = volume;

    try {
      final res = await channel.invokeMethod<bool>('updatePlaybackState', {
        'isPlaying': isPlaying,
        'trackIndex': trackIndex,
        'trackName': trackName,
        'volume': volume,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateTimerTelemetry({
    required String phase,
    required int remainingSeconds,
    required int cycleCount,
  }) async {
    _lastPhase = phase;
    _lastRemainingSeconds = remainingSeconds;
    _lastCycleCount = cycleCount;

    if (!_isActive) {
      return false;
    }

    try {
      final res = await channel.invokeMethod<bool>('updateTimerTelemetry', {
        'phase': phase,
        'remainingSeconds': remainingSeconds,
        'cycleCount': cycleCount,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> stopNotification() async {
    _isActive = false;
    try {
      final res = await channel.invokeMethod<bool>('stopMediaNotification');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    channel.setMethodCallHandler(null);
    _listeners.clear();
    _actionController.close();
  }
}
