import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/app/theme/hardware_edition.dart';
import 'package:takt_desk/app/theme/theme_controller.dart';

void main() {
  group('HardwareEdition Catalog', () {
    test('catalog contains exactly 12 curated editions', () {
      expect(HardwareEdition.all.length, equals(12));
    });

    test('free editions are braunClassic, braunAtelierCream, bauhausHeritage, and industrialMonoSteel', () {
      final freeEditions = HardwareEdition.all.where((e) => !e.isPremium).toList();
      expect(freeEditions.length, equals(4));
      expect(freeEditions.map((e) => e.type), containsAll([
        HardwareEditionType.braunClassic,
        HardwareEditionType.braunAtelierCream,
        HardwareEditionType.bauhausHeritage,
        HardwareEditionType.industrialMonoSteel,
      ]));
    });

    test('pro editions are titaniumStealth, rawBrassPatina, midCenturyWalnut, forgedCarbon, obsidianCeramic, copperHearthAsh, britishRacingGreen, and indigoAstronomical', () {
      final proEditions = HardwareEdition.all.where((e) => e.isPremium).toList();
      expect(proEditions.length, equals(8));
      expect(proEditions.map((e) => e.type), containsAll([
        HardwareEditionType.titaniumStealth,
        HardwareEditionType.rawBrassPatina,
        HardwareEditionType.midCenturyWalnut,
        HardwareEditionType.forgedCarbon,
        HardwareEditionType.obsidianCeramic,
        HardwareEditionType.copperHearthAsh,
        HardwareEditionType.britishRacingGreen,
        HardwareEditionType.indigoAstronomical,
      ]));
    });

    test('fromType resolves all 12 editions correctly with valid tokens', () {
      for (final type in HardwareEditionType.values) {
        final edition = HardwareEdition.fromType(type);
        expect(edition.type, equals(type));
        expect(edition.title, isNotEmpty);
        expect(edition.subtitle, isNotEmpty);
        expect(edition.needleColor, isNotNull);
        expect(edition.filamentColor, isNotNull);
        expect(edition.plateGradientDark.length, greaterThanOrEqualTo(2));
        expect(edition.plateGradientLight.length, greaterThanOrEqualTo(2));
      }
    });

    test('each edition assigns its corresponding HardwareTextureType', () {
      expect(HardwareEdition.braunClassic.textureType, equals(HardwareTextureType.matteAbsGrain));
      expect(HardwareEdition.braunAtelierCream.textureType, equals(HardwareTextureType.matteAbsGrain));
      expect(HardwareEdition.bauhausHeritage.textureType, equals(HardwareTextureType.tubularChrome));
      expect(HardwareEdition.industrialMonoSteel.textureType, equals(HardwareTextureType.matteAbsGrain));
      expect(HardwareEdition.titaniumStealth.textureType, equals(HardwareTextureType.brushedTitanium));
      expect(HardwareEdition.rawBrassPatina.textureType, equals(HardwareTextureType.burnishedBrass));
      expect(HardwareEdition.midCenturyWalnut.textureType, equals(HardwareTextureType.organicWalnut));
      expect(HardwareEdition.forgedCarbon.textureType, equals(HardwareTextureType.forgedCarbon));
      expect(HardwareEdition.obsidianCeramic.textureType, equals(HardwareTextureType.matteAbsGrain));
      expect(HardwareEdition.copperHearthAsh.textureType, equals(HardwareTextureType.burnishedBrass));
      expect(HardwareEdition.britishRacingGreen.textureType, equals(HardwareTextureType.matteAbsGrain));
      expect(HardwareEdition.indigoAstronomical.textureType, equals(HardwareTextureType.brushedTitanium));
    });

    test('module background has distinct contrast from canvas in both dark and light modes', () {
      for (final edition in HardwareEdition.all) {
        expect(
          edition.darkModuleBg,
          isNot(equals(edition.darkCanvas)),
          reason: '${edition.title} darkModuleBg must not match darkCanvas',
        );
        expect(
          edition.lightModuleBg,
          isNot(equals(edition.lightCanvas)),
          reason: '${edition.title} lightModuleBg must not match lightCanvas',
        );
      }
    });

    test('fromString safely resolves known keys and defaults unknown to braunClassic', () {
      for (final edition in HardwareEdition.all) {
        expect(HardwareEdition.fromString(edition.type.name).type, equals(edition.type));
      }
      expect(HardwareEdition.fromString('unknown_key').type, equals(HardwareEditionType.braunClassic));
      expect(HardwareEdition.fromString(null).type, equals(HardwareEditionType.braunClassic));
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

      // Free editions can still be equipped
      final freeChanged = controller.setHardwareEdition(HardwareEditionType.braunAtelierCream);
      expect(freeChanged, isTrue);
      expect(controller.state.edition.type, equals(HardwareEditionType.braunAtelierCream));
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

    test('ChassisThemeState dynamic getters resolve dark and light tokens accurately', () {
      const stateDark = ChassisThemeState(isDarkMode: true);
      expect(stateDark.canvasColor, equals(HardwareEdition.braunClassic.darkCanvas));
      expect(stateDark.moduleChassisColor, equals(HardwareEdition.braunClassic.darkModuleBg));
      expect(stateDark.borderColor, equals(HardwareEdition.braunClassic.darkBorder));
      expect(stateDark.plateGradient, equals(HardwareEdition.braunClassic.plateGradientDark));
      expect(stateDark.rivetColor, equals(HardwareEdition.braunClassic.rivetDark));
      expect(stateDark.accentColor, equals(HardwareEdition.braunClassic.accentColor));
      expect(stateDark.chassisTextColor, equals(const Color(0xFFE8E5DE)));
      expect(stateDark.chassisMutedTextColor, equals(const Color(0x99E8E5DE)));
      expect(stateDark.textureType, equals(HardwareTextureType.matteAbsGrain));

      const stateLight = ChassisThemeState(isDarkMode: false);
      expect(stateLight.canvasColor, equals(HardwareEdition.braunClassic.lightCanvas));
      expect(stateLight.moduleChassisColor, equals(HardwareEdition.braunClassic.lightModuleBg));
      expect(stateLight.borderColor, equals(HardwareEdition.braunClassic.lightBorder));
      expect(stateLight.plateGradient, equals(HardwareEdition.braunClassic.plateGradientLight));
      expect(stateLight.rivetColor, equals(HardwareEdition.braunClassic.rivetLight));
      expect(stateLight.accentColor, equals(HardwareEdition.braunClassic.accentColor));
      expect(stateLight.chassisTextColor, equals(const Color(0xFF1B1E23)));
      expect(stateLight.chassisMutedTextColor, equals(const Color(0x991B1E23)));
      expect(stateLight.textureType, equals(HardwareTextureType.matteAbsGrain));

      const walnutState = ChassisThemeState(
        isDarkMode: false,
        edition: HardwareEdition.midCenturyWalnut,
      );
      expect(walnutState.textureType, equals(HardwareTextureType.organicWalnut));
      expect(walnutState.hasDarkChassis, isFalse);
      expect(walnutState.chassisTextColor, equals(const Color(0xFF1B1E23)));
      expect(walnutState.chassisMutedTextColor, equals(const Color(0x991B1E23)));

      const carbonState = ChassisThemeState(
        isDarkMode: false,
        edition: HardwareEdition.forgedCarbon,
      );
      expect(carbonState.textureType, equals(HardwareTextureType.forgedCarbon));
      expect(carbonState.hasDarkChassis, isFalse);
      expect(carbonState.chassisTextColor, equals(const Color(0xFF1B1E23)));
      expect(carbonState.chassisMutedTextColor, equals(const Color(0x991B1E23)));

      expect(stateLight.hasDarkChassis, isFalse);
      expect(stateDark.hasDarkChassis, isTrue);
    });
  });
}
