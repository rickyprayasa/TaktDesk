import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/audio/audio_service.dart';
import 'package:takt_desk/core/audio/sound_effect.dart';
import 'package:takt_desk/features/vinyl/domain/vinyl_track.dart';
import 'package:takt_desk/features/vinyl/presentation/vinyl_controller.dart';

class MockAudioService extends AudioService {
  final List<SoundEffect> playedEffects = [];
  final List<int> ambientStarted = [];
  int ambientStoppedCount = 0;

  @override
  void playFoley(SoundEffect effect) {
    playedEffects.add(effect);
  }

  @override
  void startAmbient(int trackIndex) {
    ambientStarted.add(trackIndex);
  }

  @override
  void stopAmbient() {
    ambientStoppedCount++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VinylTrack domain', () {
    test('presets contain exactly 4 analog soundscapes', () {
      expect(VinylTrack.presets.length, equals(4));
      expect(VinylTrack.presets[0].name, equals('Lo-fi Rain'));
      expect(VinylTrack.presets[0].labelColorHex, equals('#C85A32'));
      expect(VinylTrack.presets[1].name, equals('Deep Brown Noise'));
      expect(VinylTrack.presets[1].labelColorHex, equals('#4D5D4B'));
      expect(VinylTrack.presets[2].name, equals('Library Atmosphere'));
      expect(VinylTrack.presets[2].labelColorHex, equals('#D99B59'));
      expect(VinylTrack.presets[3].name, equals('Cafe Echo'));
      expect(VinylTrack.presets[3].labelColorHex, equals('#2E3238'));
    });

    test('labelColor parses hex code correctly', () {
      expect(VinylTrack.presets[0].labelColor.toARGB32(), equals(0xFFC85A32));
      expect(VinylTrack.presets[1].labelColor.toARGB32(), equals(0xFF4D5D4B));
      expect(VinylTrack.presets[2].labelColor.toARGB32(), equals(0xFFD99B59));
      expect(VinylTrack.presets[3].labelColor.toARGB32(), equals(0xFF2E3238));
    });
  });

  group('VinylController', () {
    test('VinylController manages needle position and presets', () {
      final controller = VinylController();
      expect(controller.state.needleOnRecord, isFalse);
      expect(controller.state.turntableSpeed, equals(0.0));
      expect(controller.state.currentTrack.name, equals('Lo-fi Rain'));

      controller.dropNeedle();
      expect(controller.state.needleOnRecord, isTrue);
      expect(controller.state.turntableSpeed, equals(1.0));

      controller.selectTrack(1);
      expect(controller.state.currentTrack.name, equals('Deep Brown Noise'));
      expect(controller.state.selectedTrackIndex, equals(1));

      controller.liftNeedle();
      expect(controller.state.needleOnRecord, isFalse);
      expect(controller.state.turntableSpeed, equals(0.0));
    });

    test('toggleNeedle alternates between dropped and lifted states', () {
      final controller = VinylController();
      expect(controller.state.needleOnRecord, isFalse);

      controller.toggleNeedle();
      expect(controller.state.needleOnRecord, isTrue);
      expect(controller.state.turntableSpeed, equals(1.0));

      controller.toggleNeedle();
      expect(controller.state.needleOnRecord, isFalse);
      expect(controller.state.turntableSpeed, equals(0.0));
    });

    test('selectTrack ignores out of bound indices', () {
      final controller = VinylController();
      expect(controller.state.selectedTrackIndex, equals(0));

      controller.selectTrack(-1);
      expect(controller.state.selectedTrackIndex, equals(0));

      controller.selectTrack(99);
      expect(controller.state.selectedTrackIndex, equals(0));
    });

    test('AudioService triggers stylusDrop and startAmbient on dropNeedle, stylusStop and stopAmbient on liftNeedle', () {
      final mockAudio = MockAudioService();
      final controller = VinylController(mockAudio);

      controller.selectTrack(2); // Library Atmosphere
      controller.dropNeedle();

      expect(mockAudio.playedEffects, equals([SoundEffect.stylusDrop]));
      expect(mockAudio.ambientStarted, equals([2]));
      expect(mockAudio.ambientStoppedCount, equals(0));

      controller.liftNeedle();
      expect(mockAudio.playedEffects, equals([SoundEffect.stylusDrop, SoundEffect.stylusStop]));
      expect(mockAudio.ambientStoppedCount, equals(1));
    });

    test('selectTrack updates ambient track if needle is currently dropped', () {
      final mockAudio = MockAudioService();
      final controller = VinylController(mockAudio);

      controller.dropNeedle();
      expect(mockAudio.ambientStarted, equals([0]));

      controller.selectTrack(3);
      expect(mockAudio.ambientStarted, equals([0, 3]));
    });

    test('selectTrack does NOT start ambient if needle is lifted', () {
      final mockAudio = MockAudioService();
      final controller = VinylController(mockAudio);

      controller.selectTrack(1);
      expect(mockAudio.ambientStarted, isEmpty);
    });
  });
}
