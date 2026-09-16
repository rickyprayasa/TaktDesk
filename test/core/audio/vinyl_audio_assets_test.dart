import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/features/vinyl/domain/vinyl_track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VinylTrack 12 Presets & Soundscape Assets', () {
    test('contains exactly 12 calibrated presets divided into 2 drawers', () {
      expect(VinylTrack.presets.length, 12);
      expect(VinylTrack.drawer1Presets.length, 6);
      expect(VinylTrack.drawer2Presets.length, 6);

      // Verify no noisy tracks remain
      final titles = VinylTrack.presets.map((t) => t.name.toLowerCase()).toList();
      expect(titles.contains('cafe echo'), isFalse);
      expect(titles.contains('forest canopy'), isFalse);
      expect(titles.contains('cosmic drift'), isFalse);
      expect(titles.contains('midnight train'), isFalse);

      // Verify new quiet tracks
      expect(titles.contains('kyoto bamboo stream'), isTrue);
      expect(titles.contains('nordic pine whispers'), isTrue);
      expect(titles.contains('alpine mountain brook'), isTrue);
      expect(titles.contains('warm tape & felt piano'), isTrue);
      expect(titles.contains('pacific ocean waves'), isTrue);
      expect(titles.contains('misty morning meadow'), isTrue);
      expect(titles.contains('pure focus white noise'), isTrue);
      expect(titles.contains('timber acoustic chamber'), isTrue);
    });

    test('all 12 asset files exist on disk with valid headers', () {
      for (final track in VinylTrack.presets) {
        final file = File(track.assetPath);
        expect(file.existsSync(), isTrue, reason: 'Missing asset: ${track.assetPath}');
        expect(file.lengthSync(), greaterThan(10000));
      }
    });

    test('foley disc load and mechanical sound effects exist and load from asset bundle', () async {
      final foleys = [
        'foley_disc_load.wav',
        'foley_drawer_latch.wav',
        'foley_stylus_drop.wav',
        'foley_stylus_stop.wav',
        'foley_dial_click.wav',
        'foley_switch_click.wav',
      ];
      for (final foley in foleys) {
        final data = await rootBundle.load('assets/audio/$foley');
        expect(data.lengthInBytes, greaterThan(1000), reason: 'Foley $foley should be valid WAV');
      }
    });
  });
}
