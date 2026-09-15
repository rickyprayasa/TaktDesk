import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/features/timer/domain/alarm_chime.dart';

void main() {
  group('AlarmChime Domain Model', () {
    test('contains 5 standard acoustic chimes all free without PRO restriction', () {
      const chimes = AlarmChimes.all;
      expect(chimes.length, equals(5));

      final freeChimes = chimes.where((c) => !c.isPro).toList();
      expect(freeChimes.length, equals(5));
      expect(freeChimes.map((c) => c.id), containsAll([
        'braunBell',
        'deskBell',
        'tibetanBowl',
        'zenGong',
        'tubularChime',
      ]));
    });

    test('findById returns correct chime and falls back to braunBell for unknown id', () {
      expect(AlarmChimes.findById('tibetanBowl').name, equals('TIBETAN SINGING BOWL'));
      expect(AlarmChimes.findById('deskBell').isPro, isFalse);
      expect(AlarmChimes.findById('unknown_chime_xyz').id, equals('braunBell'));
      expect(AlarmChimes.findById(null).id, equals('braunBell'));
    });

    test('equality and hashCode work as expected based on id', () {
      const chime1 = AlarmChimes.braunBell;
      const chime2 = AlarmChime(
        id: 'braunBell',
        name: 'Another Name',
        category: 'Another Cat',
        description: 'Desc',
        assetPath: 'path',
      );
      expect(chime1, equals(chime2));
      expect(chime1.hashCode, equals(chime2.hashCode));
    });
  });
}
