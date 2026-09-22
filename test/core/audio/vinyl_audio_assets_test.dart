import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/features/vinyl/domain/vinyl_track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VinylTrack Presets & Soundscape Assets', () {
    test('contains exactly 24 calibrated presets divided into 2 drawers', () {
      expect(VinylTrack.presets.length, 24);
      expect(VinylTrack.drawer1Presets.length, 12);
      expect(VinylTrack.drawer2Presets.length, 12);

      // Verify no noisy tracks remain
      final titles = VinylTrack.presets.map((t) => t.name.toLowerCase()).toList();
      expect(titles.contains('cafe echo'), isFalse);
      expect(titles.contains('forest canopy'), isFalse);
      expect(titles.contains('cosmic drift'), isFalse);
      expect(titles.contains('midnight train'), isFalse);

      // Verify quiet nature tracks in drawer 1
      expect(titles.contains('kyoto bamboo stream'), isTrue);
      expect(titles.contains('nordic pine whispers'), isTrue);
      expect(titles.contains('alpine mountain brook'), isTrue);
      expect(titles.contains('pacific ocean waves'), isTrue);
      expect(titles.contains('misty morning meadow'), isTrue);
      expect(titles.contains('pure focus velvet noise'), isTrue);
      expect(titles.contains('timber acoustic chamber'), isTrue);
      expect(titles.contains('zen temple singing bowl'), isTrue);

      // Verify pure instrumental tracks in drawer 2
      expect(titles.contains('warm tape & felt piano'), isTrue);
      expect(titles.contains('monastic rhodes & velvet'), isTrue);
      expect(titles.contains('tape acoustic guitar'), isTrue);
      expect(titles.contains('cosmic ambient drift'), isTrue);
      expect(titles.contains('midnight solitude piano'), isTrue);
      expect(titles.contains('modular clockwork arp'), isTrue);
      expect(titles.contains('lo-fi tape jazz guitar'), isTrue);
      expect(titles.contains('aether chamber strings'), isTrue);
      expect(titles.contains('vintage wurlitzer 200a'), isTrue);
      expect(titles.contains('moog deep focus bass'), isTrue);
      expect(titles.contains('kalimba & crystal chords'), isTrue);
      expect(titles.contains('nocturne in f minor'), isTrue);
    });

    test('all 24 asset files exist on disk with valid headers', () {
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
