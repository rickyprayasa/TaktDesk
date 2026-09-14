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

  test('AudioService startAmbient sends trackIndex and volume', () {
    audioService.startAmbient(trackIndex: 2);

    expect(methodCalls, hasLength(1));
    expect(methodCalls.first.method, 'startAmbient');
    expect(methodCalls.first.arguments['trackIndex'], 2);
    expect(methodCalls.first.arguments['volume'], 0.8);
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

  test('AudioService playFoley forwards sound effects', () {
    audioService.playFoley(SoundEffect.stylusDrop);
    expect(methodCalls.last.method, 'playFoley');
    expect(methodCalls.last.arguments['effect'], 'stylusDrop');
  });

  test('AudioService stopAmbient stops ambient playback', () {
    audioService.stopAmbient();
    expect(methodCalls.last.method, 'stopAmbient');
  });
}
