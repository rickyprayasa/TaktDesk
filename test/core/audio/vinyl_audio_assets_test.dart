import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Vinyl Audio Assets', () {
    test('all 8 vinyl track WAV files exist and load from asset bundle', () async {
      final tracks = [
        'vinyl_lofi_rain.wav',
        'vinyl_brown_noise.wav',
        'vinyl_library.wav',
        'vinyl_cafe.wav',
        'vinyl_campfire.wav',
        'vinyl_forest.wav',
        'vinyl_cosmic.wav',
        'vinyl_train.wav',
      ];
      for (final track in tracks) {
        final data = await rootBundle.load('assets/audio/$track');
        expect(data.lengthInBytes, greaterThan(50000), reason: 'Track $track should be valid WAV');
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
