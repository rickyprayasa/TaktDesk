import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/core/audio/sound_effect.dart';

void main() {
  testWidgets('foley stays silent while the app is in the background', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(AudioService.channel, (call) async {
      calls.add(call);
      return true;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(AudioService.channel, null));

    final audio = AudioService();
    await audio.init();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    audio.playFoley(SoundEffect.dialClick);
    await tester.pump();
    expect(calls.where((c) => c.method == 'playFoley'), isEmpty);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    audio.playFoley(SoundEffect.dialClick);
    await tester.pump();
    expect(calls.where((c) => c.method == 'playFoley'), hasLength(1));
  });
}
