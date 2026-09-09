import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/hardware_edition.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';

void main() {
  group('HardwareEdition domain model', () {
    test('contains all 4 curated editions with distinct titles and tokens', () {
      expect(HardwareEdition.all.length, equals(4));
      
      final types = HardwareEdition.all.map((e) => e.type).toSet();
      expect(types, contains(HardwareEditionType.braunClassic));
      expect(types, contains(HardwareEditionType.titaniumStealth));
      expect(types, contains(HardwareEditionType.bauhausHeritage));
      expect(types, contains(HardwareEditionType.rawBrassPatina));

      // Free vs Premium check
      expect(HardwareEdition.fromType(HardwareEditionType.braunClassic).isPremium, isFalse);
      expect(HardwareEdition.fromType(HardwareEditionType.titaniumStealth).isPremium, isTrue);
      expect(HardwareEdition.fromType(HardwareEditionType.bauhausHeritage).isPremium, isTrue);
      expect(HardwareEdition.fromType(HardwareEditionType.rawBrassPatina).isPremium, isTrue);
    });

    test('each edition provides valid dark and light visual tokens', () {
      for (final edition in HardwareEdition.all) {
        expect(edition.title, isNotEmpty);
        expect(edition.subtitle, isNotEmpty);
        expect(edition.needleColor, isNotNull);
        expect(edition.filamentColor, isNotNull);
        expect(edition.plateGradientDark.length, greaterThanOrEqualTo(2));
        expect(edition.plateGradientLight.length, greaterThanOrEqualTo(2));
      }
    });
  });

  group('ThemeController with HardwareEditions', () {
    test('initial state defaults to braunClassic, dark mode, and isProUnlocked true', () {
      final controller = ThemeController();
      expect(controller.state.isDarkMode, isTrue);
      expect(controller.state.edition.type, equals(HardwareEditionType.braunClassic));
      expect(controller.state.isProUnlocked, isTrue);
      expect(controller.state.needleColor, equals(const Color(0xFFC85A32))); // mutedOchre
    });

    test('setHardwareEdition updates active edition', () {
      final controller = ThemeController();
      controller.setHardwareEdition(HardwareEditionType.titaniumStealth);

      expect(controller.state.edition.type, equals(HardwareEditionType.titaniumStealth));
      expect(controller.state.needleColor, equals(const Color(0xFF3A86FF))); // electric cobalt
    });

    test('setHardwareEdition prevents equipping premium edition if isProUnlocked is false', () {
      final controller = ThemeController();
      controller.setProUnlocked(false);
      expect(controller.state.isProUnlocked, isFalse);

      final changed = controller.setHardwareEdition(HardwareEditionType.titaniumStealth);
      expect(changed, isFalse);
      expect(controller.state.edition.type, equals(HardwareEditionType.braunClassic));

      // But free edition can still be equipped
      final freeChanged = controller.setHardwareEdition(HardwareEditionType.braunClassic);
      expect(freeChanged, isTrue);
    });

    test('toggleTheme preserves selected edition tokens', () {
      final controller = ThemeController();
      controller.setHardwareEdition(HardwareEditionType.bauhausHeritage);
      expect(controller.state.isDarkMode, isTrue);

      controller.toggleTheme();
      expect(controller.state.isDarkMode, isFalse);
      expect(controller.state.edition.type, equals(HardwareEditionType.bauhausHeritage));
      expect(controller.state.needleColor, equals(const Color(0xFFD62828))); // bauhaus crimson
    });

    test('setProUnlocked(false) atomically reverts active premium edition to braunClassic', () {
      final controller = ThemeController();
      controller.setHardwareEdition(HardwareEditionType.titaniumStealth);
      expect(controller.state.edition.type, equals(HardwareEditionType.titaniumStealth));

      controller.setProUnlocked(false);
      expect(controller.state.isProUnlocked, isFalse);
      expect(controller.state.edition.type, equals(HardwareEditionType.braunClassic));
    });

    test('setHardwareEdition returns true early if edition is already equipped', () {
      final controller = ThemeController();
      expect(controller.setHardwareEdition(HardwareEditionType.braunClassic), isTrue);
    });

    test('fromString parses valid names and falls back safely to braunClassic', () {
      expect(HardwareEdition.fromString('titaniumStealth').type, equals(HardwareEditionType.titaniumStealth));
      expect(HardwareEdition.fromString('bauhausHeritage').type, equals(HardwareEditionType.bauhausHeritage));
      expect(HardwareEdition.fromString('rawBrassPatina').type, equals(HardwareEditionType.rawBrassPatina));
      expect(HardwareEdition.fromString('invalid').type, equals(HardwareEditionType.braunClassic));
      expect(HardwareEdition.fromString(null).type, equals(HardwareEditionType.braunClassic));
    });

    test('ChassisThemeState dynamic getters resolve dark and light tokens accurately', () {
      const stateDark = ChassisThemeState(isDarkMode: true);
      expect(stateDark.canvasColor, equals(HardwareEdition.braunClassic.darkCanvas));
      expect(stateDark.moduleChassisColor, equals(HardwareEdition.braunClassic.darkModuleBg));
      expect(stateDark.borderColor, equals(HardwareEdition.braunClassic.darkBorder));

      const stateLight = ChassisThemeState(isDarkMode: false);
      expect(stateLight.canvasColor, equals(HardwareEdition.braunClassic.lightCanvas));
      expect(stateLight.moduleChassisColor, equals(HardwareEdition.braunClassic.lightModuleBg));
      expect(stateLight.borderColor, equals(HardwareEdition.braunClassic.lightBorder));
    });
  });
}
