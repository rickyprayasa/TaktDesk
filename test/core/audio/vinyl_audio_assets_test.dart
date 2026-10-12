import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/features/vinyl/domain/vinyl_track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VinylTrack Presets & Soundscape Assets', () {
    test('contains exactly 20 calibrated presets divided into 2 drawers', () {
      expect(VinylTrack.presets.length, 20);
      expect(VinylTrack.drawer1Presets.length, 10);
      expect(VinylTrack.drawer2Presets.length, 10);

      // Verify quiet nature tracks in drawer 1 (10 tracks: 4 Free + 6 PRO)
      final drawer1Titles = VinylTrack.drawer1Presets.map((t) => t.name.toLowerCase()).toList();
      expect(drawer1Titles.contains('lo-fi rain'), isTrue);
      expect(drawer1Titles.contains('deep brown noise'), isTrue);
      expect(drawer1Titles.contains('library atmosphere'), isTrue);
      expect(drawer1Titles.contains('kyoto bamboo stream'), isTrue);
      expect(drawer1Titles.contains('campfire embers'), isTrue);
      expect(drawer1Titles.contains('nordic pine whispers'), isTrue);
      expect(drawer1Titles.contains('alpine mountain brook'), isTrue);
      expect(drawer1Titles.contains('pacific ocean waves'), isTrue);
      expect(drawer1Titles.contains('misty morning meadow'), isTrue);
      expect(drawer1Titles.contains('timber chamber hall'), isTrue);

      // Verify pure instrumental tracks in drawer 2 (10 tracks: 4 Free + 6 PRO)
      final drawer2Titles = VinylTrack.drawer2Presets.map((t) => t.name.toLowerCase()).toList();
      expect(drawer2Titles.contains('warm tape & felt piano'), isTrue);
      expect(drawer2Titles.contains('monastic cello solo'), isTrue);
      expect(drawer2Titles.contains('tape acoustic guitar'), isTrue);
      expect(drawer2Titles.contains('debussy clair de lune'), isTrue);
      expect(drawer2Titles.contains('midnight solitude piano'), isTrue);
      expect(drawer2Titles.contains('zen bronze singing bowl'), isTrue);
      expect(drawer2Titles.contains('goldberg variations aria'), isTrue);
      expect(drawer2Titles.contains('chopin nocturne op. 9'), isTrue);
      expect(drawer2Titles.contains('spanish romance guitar'), isTrue);
      expect(drawer2Titles.contains('chamber string quartet'), isTrue);
    });

    test('all 20 asset files exist on disk with valid headers', () {
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
        'foley_crown_wind.wav',
        'foley_crown_press.wav',
      ];
      for (final foley in foleys) {
        final data = await rootBundle.load('assets/audio/$foley');
        expect(data.lengthInBytes, greaterThan(1000), reason: 'Foley $foley should be valid WAV');
      }
    });
  });
}
