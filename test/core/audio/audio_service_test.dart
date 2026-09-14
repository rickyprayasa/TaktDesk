import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/core/audio/sound_effect.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AudioService audioService;
  late List<MethodCall> methodCalls;

  setUp(() {
    methodCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AudioService.channel, (call) async {
      methodCalls.add(call);
      return true;
    });

    audioService = AudioService();
    audioService.init();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AudioService.channel, null);
    audioService.dispose();
  });

  test('AudioService startAmbient sends 3-channel mixer parameters', () {
    audioService.startAmbient(
      trackIndex: 2,
      primaryVolume: 0.75,
      crackleVolume: 0.40,
      binauralVolume: 0.20,
    );

    expect(methodCalls, hasLength(1));
    expect(methodCalls.first.method, 'startAmbient');
    expect(methodCalls.first.arguments['trackIndex'], 2);
    expect(methodCalls.first.arguments['volume'], 0.8);
    expect(methodCalls.first.arguments['primaryVolume'], 0.75);
    expect(methodCalls.first.arguments['crackleVolume'], 0.40);
    expect(methodCalls.first.arguments['binauralVolume'], 0.20);
  });

  test('AudioService setVolume invokes setVolume and clamps volume values', () {
    audioService.setVolume(0.6);
    expect(methodCalls.last.method, 'setVolume');
    expect(methodCalls.last.arguments['volume'], 0.6);
    expect(audioService.volume, 0.6);

    audioService.setVolume(1.5);
    expect(methodCalls.last.arguments['volume'], 1.0);
    expect(audioService.volume, 1.0);

    audioService.setVolume(-0.5);
    expect(methodCalls.last.arguments['volume'], 0.0);
    expect(audioService.volume, 0.0);
  });

  test('AudioService setMixerLevels invokes setMixerLevels with clamped values', () {
    audioService.setMixerLevels(
      primaryVolume: 1.5,
      crackleVolume: -0.5,
      binauralVolume: 2.0,
    );

    expect(methodCalls, hasLength(1));
    expect(methodCalls.first.method, 'setMixerLevels');
    expect(methodCalls.first.arguments['primaryVolume'], 1.0);
    expect(methodCalls.first.arguments['crackleVolume'], 0.0);
    expect(methodCalls.first.arguments['binauralVolume'], 1.0);
    expect(audioService.primaryVolume, 1.0);
    expect(audioService.crackleVolume, 0.0);
    expect(audioService.binauralVolume, 1.0);
  });

  test('AudioService setMixerLevels updates internal levels and subsequent startAmbient retains them', () {
    audioService.setMixerLevels(
      primaryVolume: 0.60,
      crackleVolume: 0.20,
      binauralVolume: 0.10,
    );

    expect(audioService.primaryVolume, 0.60);
    expect(audioService.crackleVolume, 0.20);
    expect(audioService.binauralVolume, 0.10);

    audioService.startAmbient(trackIndex: 3);

    final startCall = methodCalls.last;
    expect(startCall.method, 'startAmbient');
    expect(startCall.arguments['trackIndex'], 3);
    expect(startCall.arguments['volume'], 0.8);
    expect(startCall.arguments['primaryVolume'], 0.60);
    expect(startCall.arguments['crackleVolume'], 0.20);
    expect(startCall.arguments['binauralVolume'], 0.10);
  });

  test('AudioService playFoley forwards sound effects', () {
    audioService.playFoley(SoundEffect.stylusDrop);
    expect(methodCalls.last.method, 'playFoley');
    expect(methodCalls.last.arguments['effect'], 'stylusDrop');
  });

  test('AudioService stopAmbient stops all channels', () {
    audioService.stopAmbient();
    expect(methodCalls.last.method, 'stopAmbient');
  });
}
