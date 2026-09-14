import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/core/audio/sound_effect.dart';
import 'package:takt_desk/core/haptics/haptic_service.dart';

void main() {
  test('SoundEffect enum provides all analog foley sound types', () {
    expect(SoundEffect.values.contains(SoundEffect.dialClick), isTrue);
    expect(SoundEffect.values.contains(SoundEffect.springButton), isTrue);
    expect(SoundEffect.values.contains(SoundEffect.stepperPrint), isTrue);
    expect(SoundEffect.values.contains(SoundEffect.paperTear), isTrue);
    expect(SoundEffect.values.contains(SoundEffect.inkStamp), isTrue);
    expect(SoundEffect.values.contains(SoundEffect.stylusDrop), isTrue);
    expect(SoundEffect.values.contains(SoundEffect.stylusStop), isTrue);
    expect(SoundEffect.values.contains(SoundEffect.discLoad), isTrue);
  });

  test('AudioService handles mock/graceful mode when audio devices unavailable', () async {
    final audio = AudioService(isMock: true);
    await audio.init();
    expect(audio.isInitialized, isTrue);
    expect(() => audio.playFoley(SoundEffect.dialClick), returnsNormally);
  });

  test('AudioService manages volume and ambient track state', () async {
    final audio = AudioService(isMock: true);
    await audio.init();
    audio.setVolume(0.5);
    expect(audio.volume, 0.5);
    audio.setVolume(1.5);
    expect(audio.volume, 1.0);
    audio.setVolume(-0.5);
    expect(audio.volume, 0.0);

    audio.startAmbient(trackIndex: 2);
    expect(audio.isAmbientPlaying, isTrue);
    expect(audio.activeTrackIndex, 2);

    audio.stopAmbient();
    expect(audio.isAmbientPlaying, isFalse);

    audio.dispose();
    expect(audio.isInitialized, isFalse);
  });

  test('HapticService triggers haptic feedback methods without throwing', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    expect(() async => await HapticService.dialTick(), returnsNormally);
    expect(() async => await HapticService.mechanicalPress(), returnsNormally);
    expect(() async => await HapticService.paperTorn(), returnsNormally);
    expect(() async => await HapticService.stampDone(), returnsNormally);
    expect(() async => await HapticService.tick(), returnsNormally);
    expect(() async => await HapticService.selectionClick(), returnsNormally);
    expect(() async => await HapticService.impactLight(), returnsNormally);
    expect(() async => await HapticService.impactHeavy(), returnsNormally);
    expect(() async => await HapticService.heavyClick(), returnsNormally);
    expect(() async => await HapticService.lightClick(), returnsNormally);
  });

  test('audioServiceProvider provides AudioService instance', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final service = container.read(audioServiceProvider);
    expect(service, isA<AudioService>());
    expect(service.isInitialized, isTrue);
  });
}
