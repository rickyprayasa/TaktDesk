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

  test('AudioService setMixerLevels invokes setMixerLevels with clamped values', () {
    audioService.setMixerLevels(
      primaryVolume: 0.90,
      crackleVolume: 0.30,
      binauralVolume: 0.15,
    );

    expect(methodCalls, hasLength(1));
    expect(methodCalls.first.method, 'setMixerLevels');
    expect(methodCalls.first.arguments['primaryVolume'], 0.90);
    expect(methodCalls.first.arguments['crackleVolume'], 0.30);
    expect(methodCalls.first.arguments['binauralVolume'], 0.15);
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
