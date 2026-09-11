import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/audio/audio_service.dart';

void main() {
  test('AudioService registers channel com.takt.desk/audio', () {
    expect(AudioService.channel.name, equals('com.takt.desk/audio'));
  });
}
