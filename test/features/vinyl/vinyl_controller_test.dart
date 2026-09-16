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
  void startAmbient({
    required int trackIndex,
    double? primaryVolume,
    double? crackleVolume,
    double? binauralVolume,
  }) {
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
    test('presets contain exactly 12 analog soundscapes with correct tiers and metadata', () {
      expect(VinylTrack.presets.length, equals(12));
      for (int i = 0; i < 4; i++) {
        expect(VinylTrack.presets[i].isPremium, isFalse, reason: 'Track $i should be Free');
      }
      for (int i = 4; i < 12; i++) {
        expect(VinylTrack.presets[i].isPremium, isTrue, reason: 'Track $i should be Studio Pro');
      }
      for (final track in VinylTrack.presets) {
        expect(track.catalogId, isNotEmpty);
        expect(track.name, isNotEmpty);
        expect(track.subtitle, isNotEmpty);
        expect(track.description, isNotEmpty);
        expect(track.labelColorHex, isNotEmpty);
        expect(track.assetPath, isNotEmpty);
      }
    });

    test('labelColor parses hex code correctly for all 12 tracks', () {
      expect(VinylTrack.presets[0].labelColor.toARGB32(), equals(0xFFC85A32));
      expect(VinylTrack.presets[1].labelColor.toARGB32(), equals(0xFF4D5D4B));
      expect(VinylTrack.presets[2].labelColor.toARGB32(), equals(0xFFD99B59));
      expect(VinylTrack.presets[3].labelColor.toARGB32(), equals(0xFF4A6B53));
      expect(VinylTrack.presets[4].labelColor.toARGB32(), equals(0xFFE05A2B));
      expect(VinylTrack.presets[5].labelColor.toARGB32(), equals(0xFF3B7A57));
      expect(VinylTrack.presets[6].labelColor.toARGB32(), equals(0xFF4A90E2));
      expect(VinylTrack.presets[7].labelColor.toARGB32(), equals(0xFFD97736));
      expect(VinylTrack.presets[8].labelColor.toARGB32(), equals(0xFF9B72AA));
      expect(VinylTrack.presets[9].labelColor.toARGB32(), equals(0xFF7E9F8E));
      expect(VinylTrack.presets[10].labelColor.toARGB32(), equals(0xFF707070));
      expect(VinylTrack.presets[11].labelColor.toARGB32(), equals(0xFF8C6747));
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

      expect(mockAudio.playedEffects, equals([SoundEffect.discLoad, SoundEffect.stylusDrop]));
      expect(mockAudio.ambientStarted, equals([2]));
      expect(mockAudio.ambientStoppedCount, equals(0));

      controller.liftNeedle();
      expect(mockAudio.playedEffects, equals([SoundEffect.discLoad, SoundEffect.stylusDrop, SoundEffect.stylusStop]));
      expect(mockAudio.ambientStoppedCount, equals(1));
    });

    test('selectTrack triggers discLoad foley sound effect', () {
      final mockAudio = MockAudioService();
      final controller = VinylController(mockAudio);

      controller.selectTrack(1);
      expect(mockAudio.playedEffects, equals([SoundEffect.discLoad]));
    });

    test('selectTrack updates ambient track if needle is currently dropped', () {
      final mockAudio = MockAudioService();
      final controller = VinylController(mockAudio);

      controller.dropNeedle();
      expect(mockAudio.ambientStarted, equals([0]));

      controller.selectTrack(3);
      expect(mockAudio.ambientStarted, equals([0, 3]));
      expect(mockAudio.playedEffects, contains(SoundEffect.discLoad));
    });

    test('selectTrack does NOT start ambient if needle is lifted', () {
      final mockAudio = MockAudioService();
      final controller = VinylController(mockAudio);

      controller.selectTrack(1);
      expect(mockAudio.ambientStarted, isEmpty);
      expect(mockAudio.playedEffects, equals([SoundEffect.discLoad]));
    });

    test('selectTrack guards premium tracks when not Pro and permits when Pro', () {
      final controller = VinylController();
      expect(controller.state.selectedTrackIndex, equals(0));

      // Attempt selecting premium track 4 without Pro
      final freeSuccess = controller.selectTrack(4, isPro: false);
      expect(freeSuccess, isFalse);
      expect(controller.state.selectedTrackIndex, equals(0));

      // Select free track 1 without Pro
      final freeTrack1 = controller.selectTrack(1, isPro: false);
      expect(freeTrack1, isTrue);
      expect(controller.state.selectedTrackIndex, equals(1));

      // Attempt selecting premium track 4 with Pro
      final proSuccess = controller.selectTrack(4, isPro: true);
      expect(proSuccess, isTrue);
      expect(controller.state.selectedTrackIndex, equals(4));
    });

    test('revertIfProRevoked resets to track 0 if on a premium track, no-op if on free track', () {
      final controller = VinylController();
      controller.selectTrack(4, isPro: true);
      expect(controller.state.selectedTrackIndex, equals(4));

      controller.revertIfProRevoked();
      expect(controller.state.selectedTrackIndex, equals(0));

      // Reverting while on free track remains at free track
      controller.selectTrack(2, isPro: false);
      controller.revertIfProRevoked();
      expect(controller.state.selectedTrackIndex, equals(2));
    });

    test('isDrawerOpen defaults to false', () {
      final controller = VinylController();
      expect(controller.state.isDrawerOpen, isFalse);
    });

    test('toggleDrawer flips isDrawerOpen and setDrawerOpen sets explicit state', () {
      final controller = VinylController();
      expect(controller.state.isDrawerOpen, isFalse);

      controller.toggleDrawer();
      expect(controller.state.isDrawerOpen, isTrue);

      controller.toggleDrawer();
      expect(controller.state.isDrawerOpen, isFalse);

      controller.setDrawerOpen(true);
      expect(controller.state.isDrawerOpen, isTrue);

      controller.setDrawerOpen(true);
      expect(controller.state.isDrawerOpen, isTrue);

      controller.setDrawerOpen(false);
      expect(controller.state.isDrawerOpen, isFalse);
    });
  });
}
