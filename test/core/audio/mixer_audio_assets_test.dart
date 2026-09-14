import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mixer Companion Audio Assets', () {
    test('vinyl_surface_crackle.wav exists and loads from asset bundle', () async {
      final data = await rootBundle.load('assets/audio/vinyl_surface_crackle.wav');
      expect(data.lengthInBytes, greaterThan(100000));
    });

    test('binaural_alpha_432.wav exists and loads from asset bundle', () async {
      final data = await rootBundle.load('assets/audio/binaural_alpha_432.wav');
      expect(data.lengthInBytes, greaterThan(100000));
    });

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
  });
}
