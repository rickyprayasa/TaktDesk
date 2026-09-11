import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/hardware_edition.dart';

void main() {
  group('HardwareEdition Catalog', () {
    test('catalog contains exactly 7 curated editions', () {
      expect(HardwareEdition.all.length, equals(7));
    });

    test('free editions are braunClassic and braunAtelierCream', () {
      final freeEditions = HardwareEdition.all.where((e) => !e.isPremium).toList();
      expect(freeEditions.length, equals(2));
      expect(freeEditions.map((e) => e.type), containsAll([
        HardwareEditionType.braunClassic,
        HardwareEditionType.braunAtelierCream,
      ]));
    });

    test('pro editions are titaniumStealth, bauhausHeritage, rawBrassPatina, midCenturyWalnut, and forgedCarbon', () {
      final proEditions = HardwareEdition.all.where((e) => e.isPremium).toList();
      expect(proEditions.length, equals(5));
      expect(proEditions.map((e) => e.type), containsAll([
        HardwareEditionType.titaniumStealth,
        HardwareEditionType.bauhausHeritage,
        HardwareEditionType.rawBrassPatina,
        HardwareEditionType.midCenturyWalnut,
        HardwareEditionType.forgedCarbon,
      ]));
    });

    test('fromType resolves all 7 editions correctly', () {
      for (final type in HardwareEditionType.values) {
        final edition = HardwareEdition.fromType(type);
        expect(edition.type, equals(type));
        expect(edition.title, isNotEmpty);
        expect(edition.plateGradientDark.length, greaterThanOrEqualTo(2));
        expect(edition.plateGradientLight.length, greaterThanOrEqualTo(2));
      }
    });

    test('fromString safely resolves known keys and defaults unknown to braunClassic', () {
      expect(HardwareEdition.fromString('braunAtelierCream').type, equals(HardwareEditionType.braunAtelierCream));
      expect(HardwareEdition.fromString('midCenturyWalnut').type, equals(HardwareEditionType.midCenturyWalnut));
      expect(HardwareEdition.fromString('forgedCarbon').type, equals(HardwareEditionType.forgedCarbon));
      expect(HardwareEdition.fromString('unknown_key').type, equals(HardwareEditionType.braunClassic));
      expect(HardwareEdition.fromString(null).type, equals(HardwareEditionType.braunClassic));
    });

    test('texture types are correctly assigned', () {
      expect(HardwareEdition.midCenturyWalnut.textureType, equals(HardwareTextureType.organicWalnut));
      expect(HardwareEdition.forgedCarbon.textureType, equals(HardwareTextureType.forgedCarbon));
      expect(HardwareEdition.braunAtelierCream.textureType, equals(HardwareTextureType.matteAbsGrain));
    });
  });
}
