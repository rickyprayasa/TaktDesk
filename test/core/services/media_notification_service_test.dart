import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/services/media_notification_service.dart';
import 'package:takt_desk/features/vinyl/presentation/vinyl_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<MethodCall> log;

  setUp(() {
    log = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.zykl.app/media_notification'),
      (call) async {
        log.add(call);
        return true;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.zykl.app/media_notification'),
      null,
    );
  });

  test('startNotification invokes startMediaNotification with payload', () async {
    final service = MediaNotificationService();
    await service.startNotification(
      trackIndex: 0,
      trackName: 'Lo-fi Rain',
      isPlaying: true,
      volume: 0.8,
      phase: 'focus',
      remainingSeconds: 1500,
      cycleCount: 1,
    );

    expect(log.length, 1);
    expect(log.first.method, 'startMediaNotification');
    expect(log.first.arguments['trackName'], 'Lo-fi Rain');
    expect(log.first.arguments['isPlaying'], isTrue);
    expect(log.first.arguments['volume'], 0.8);
    expect(log.first.arguments['phase'], 'focus');
    expect(log.first.arguments['remainingSeconds'], 1500);
    expect(log.first.arguments['cycleCount'], 1);
    expect(service.isActive, isTrue);
  });

  test('updatePlaybackState invokes updatePlaybackState with payload', () async {
    final service = MediaNotificationService();
    final res = await service.updatePlaybackState(
      isPlaying: true,
      trackIndex: 2,
      trackName: 'Library Atmosphere',
      volume: 0.5,
    );

    expect(res, isTrue);
    expect(log.length, 1);
    expect(log.first.method, 'updatePlaybackState');
    expect(log.first.arguments['isPlaying'], isTrue);
    expect(log.first.arguments['trackIndex'], 2);
    expect(log.first.arguments['trackName'], 'Library Atmosphere');
    expect(log.first.arguments['volume'], 0.5);
  });

  test('updateTimerTelemetry invokes updateTimerTelemetry with payload when active', () async {
    final service = MediaNotificationService();
    await service.startNotification(
      trackIndex: 0,
      trackName: 'Lo-fi Rain',
      isPlaying: true,
      phase: 'focus',
      remainingSeconds: 1500,
      cycleCount: 1,
    );
    log.clear();

    final res = await service.updateTimerTelemetry(
      phase: 'shortBreak',
      remainingSeconds: 300,
      cycleCount: 2,
    );

    expect(res, isTrue);
    expect(log.length, 1);
    expect(log.first.method, 'updateTimerTelemetry');
    expect(log.first.arguments['phase'], 'shortBreak');
    expect(log.first.arguments['remainingSeconds'], 300);
    expect(log.first.arguments['cycleCount'], 2);
  });

  test('updateTimerTelemetry returns false when service is not active', () async {
    final service = MediaNotificationService();
    final res = await service.updateTimerTelemetry(
      phase: 'focus',
      remainingSeconds: 1500,
      cycleCount: 1,
    );

    expect(res, isFalse);
    expect(log.isEmpty, isTrue);
  });

  test('stopNotification invokes stopMediaNotification and marks service inactive', () async {
    final service = MediaNotificationService();
    await service.startNotification(
      trackIndex: 0,
      trackName: 'Lo-fi Rain',
      isPlaying: true,
      phase: 'focus',
      remainingSeconds: 1500,
      cycleCount: 1,
    );
    expect(service.isActive, isTrue);
    log.clear();

    final res = await service.stopNotification();
    expect(res, isTrue);
    expect(log.length, 1);
    expect(log.first.method, 'stopMediaNotification');
    expect(service.isActive, isFalse);
  });

  test('handles channel errors gracefully without throwing', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.zykl.app/media_notification'),
      (call) async {
        throw PlatformException(code: 'ERROR', message: 'Failed');
      },
    );

    final service = MediaNotificationService();
    final startRes = await service.startNotification(
      trackIndex: 0,
      trackName: 'Lo-fi Rain',
      isPlaying: true,
      phase: 'focus',
      remainingSeconds: 1500,
      cycleCount: 1,
    );
    expect(startRes, isFalse);

    final updateRes = await service.updatePlaybackState(
      isPlaying: false,
      trackIndex: 0,
      trackName: 'Lo-fi Rain',
    );
    expect(updateRes, isFalse);

    final stopRes = await service.stopNotification();
    expect(stopRes, isFalse);
  });

  test('dispatches incoming onMediaControlAction to registered listeners', () async {
    final service = MediaNotificationService();
    final receivedActions = <String>[];
    service.addListener((action) {
      receivedActions.add(action);
    });

    final message = const StandardMethodCodec().encodeMethodCall(
      const MethodCall('onMediaControlAction', {'action': 'play'}),
    );
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      'com.zykl.app/media_notification',
      message,
      (data) {},
    );

    expect(receivedActions, ['play']);
  });

  test('mediaNotificationServiceProvider wires media control actions to VinylController', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Read mediaNotificationServiceProvider to activate listener
    container.read(mediaNotificationServiceProvider);

    expect(container.read(vinylProvider).needleOnRecord, isFalse);

    // Send 'play' action
    final playMessage = const StandardMethodCodec().encodeMethodCall(
      const MethodCall('onMediaControlAction', {'action': 'play'}),
    );
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      'com.zykl.app/media_notification',
      playMessage,
      (data) {},
    );
    expect(container.read(vinylProvider).needleOnRecord, isTrue);

    // Send 'next' action
    final nextMessage = const StandardMethodCodec().encodeMethodCall(
      const MethodCall('onMediaControlAction', {'action': 'next'}),
    );
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      'com.zykl.app/media_notification',
      nextMessage,
      (data) {},
    );
    expect(container.read(vinylProvider).selectedTrackIndex, 1);

    // Send 'previous' action
    final prevMessage = const StandardMethodCodec().encodeMethodCall(
      const MethodCall('onMediaControlAction', {'action': 'previous'}),
    );
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      'com.zykl.app/media_notification',
      prevMessage,
      (data) {},
    );
    expect(container.read(vinylProvider).selectedTrackIndex, 0);

    // Send 'pause' action
    final pauseMessage = const StandardMethodCodec().encodeMethodCall(
      const MethodCall('onMediaControlAction', {'action': 'pause'}),
    );
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      'com.zykl.app/media_notification',
      pauseMessage,
      (data) {},
    );
    expect(container.read(vinylProvider).needleOnRecord, isFalse);
  });
}
