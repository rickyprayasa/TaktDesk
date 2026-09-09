# Hardware Material Editions (Freemium Model) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement cohesive 4-tier Hardware Material Editions (Braun Classic, Titanium Stealth, Bauhaus Heritage, Raw Brass & Patina), Drift SQLite persistence, simulated pro status toggle, Service Hatch material gallery UI, and dynamic component styling across the console.

**Architecture:** Extend `ChassisThemeState` and `ThemeController` with a type-safe `HardwareEdition` domain model containing rich material and color tokens. Persist user preference (`selected_edition` and `is_pro_simulated`) in Drift SQLite table `desk_preferences`. Provide an interactive material gallery in `TaktSettingsSheet` with instant feedback and a debug switch for simulated Pro status. Bind console canvas, dials, switches, and spec plates reactively to active edition tokens.

**Tech Stack:** Flutter, Flutter Riverpod (StateNotifier, Provider), Drift SQLite (NativeDatabase), Material Design / Braun Minimalist Aesthetics.

## Global Constraints
- Strictly adhere to Dieter Rams / Braun modernist industrial aesthetic (honest materials, high contrast, tactile feedback).
- Target platform: Mobile Android (maxWidth 440px handheld console).
- 0 analyzer issues (`flutter analyze`).
- 100% test pass rate across the full repository.
- Avoid external billing dependencies; use simulated pro toggle for this development phase.

---

### Task 1: Hardware Edition Domain Model & Theme Controller Enhancements

**Files:**
- Create: `lib/app/theme/hardware_edition.dart`
- Modify: `lib/app/theme/theme_controller.dart`
- Test: `test/app/theme/hardware_edition_test.dart`

**Interfaces:**
- Produces:
  - `enum HardwareEditionType { braunClassic, titaniumStealth, bauhausHeritage, rawBrassPatina }`
  - `class HardwareEdition`: type, title, subtitle, yearLabel, isPremium, darkCanvas, lightCanvas, darkModuleBg, lightModuleBg, darkBorder, lightBorder, needleColor, filamentColor, accentColor, plateGradientDark, plateGradientLight, rivetDark, rivetLight
  - `class ChassisThemeState`: `isDarkMode`, `edition`, `isProUnlocked`, dynamic getters (`canvasColor`, `moduleChassisColor`, `borderColor`, `needleColor`, `filamentColor`)
  - `class ThemeController`: `toggleTheme()`, `setHardwareEdition(HardwareEditionType type)`, `setProUnlocked(bool unlocked)`

- [ ] **Step 1: Write failing unit tests in test/app/theme/hardware_edition_test.dart**

Create `test/app/theme/hardware_edition_test.dart`:
```dart
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
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/app/theme/hardware_edition_test.dart`
Expected: FAIL with compilation error: file not found.

- [ ] **Step 3: Implement HardwareEdition domain model and update ThemeController**

Create `lib/app/theme/hardware_edition.dart`:
```dart
import 'package:flutter/material.dart';
import 'takt_colors.dart';

enum HardwareEditionType {
  braunClassic,
  titaniumStealth,
  bauhausHeritage,
  rawBrassPatina,
}

class HardwareEdition {
  final HardwareEditionType type;
  final String title;
  final String subtitle;
  final String yearLabel;
  final bool isPremium;

  // Canvas & Module Tokens
  final Color darkCanvas;
  final Color lightCanvas;
  final Color darkModuleBg;
  final Color lightModuleBg;
  final Color darkBorder;
  final Color lightBorder;

  // Accents & Hardware Details
  final Color needleColor;
  final Color filamentColor;
  final Color accentColor;
  final List<Color> plateGradientDark;
  final List<Color> plateGradientLight;
  final Color rivetDark;
  final Color rivetLight;

  const HardwareEdition({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.yearLabel,
    required this.isPremium,
    required this.darkCanvas,
    required this.lightCanvas,
    required this.darkModuleBg,
    required this.lightModuleBg,
    required this.darkBorder,
    required this.lightBorder,
    required this.needleColor,
    required this.filamentColor,
    required this.accentColor,
    required this.plateGradientDark,
    required this.plateGradientLight,
    required this.rivetDark,
    required this.rivetLight,
  });

  static const HardwareEdition braunClassic = HardwareEdition(
    type: HardwareEditionType.braunClassic,
    title: 'BRAUN CLASSIC',
    subtitle: 'GERMANIC MINIMALISM',
    yearLabel: 'MOD. 01 · 1960',
    isPremium: false,
    darkCanvas: TaktColors.chassisObsidian,
    lightCanvas: TaktColors.lightChassisCanvas,
    darkModuleBg: TaktColors.basaltSlate,
    lightModuleBg: TaktColors.lightChassisBasalt,
    darkBorder: TaktColors.slateBorder,
    lightBorder: TaktColors.lightChassisBorder,
    needleColor: TaktColors.mutedOchre, // #C85A32
    filamentColor: TaktColors.filamentAmber, // #D99B59
    accentColor: TaktColors.patinaOlive, // #4D5D4B
    plateGradientDark: [Color(0xFF282B32), Color(0xFF1E2126), Color(0xFF17191C)],
    plateGradientLight: [Color(0xFFE4E1D9), Color(0xFFDDD9D0), Color(0xFFCFCAC0)],
    rivetDark: Color(0xFF101214),
    rivetLight: Color(0xFFA8A398),
  );

  static const HardwareEdition titaniumStealth = HardwareEdition(
    type: HardwareEditionType.titaniumStealth,
    title: 'TITANIUM STEALTH',
    subtitle: 'AEROSPACE PVD GRADE 5',
    yearLabel: 'MOD. 02 · 2026',
    isPremium: true,
    darkCanvas: Color(0xFF111317),
    lightCanvas: Color(0xFFCBCED4),
    darkModuleBg: Color(0xFF1B1E24),
    lightModuleBg: Color(0xFFD8DBE2),
    darkBorder: Color(0xFF2C323D),
    lightBorder: Color(0xFFA2A7B2),
    needleColor: Color(0xFF3A86FF), // Electric Cobalt Cyan
    filamentColor: Color(0xFFFF9E00), // Vivid Amber Neon
    accentColor: Color(0xFF48CAE4),
    plateGradientDark: [Color(0xFF22262E), Color(0xFF181B20), Color(0xFF121417)],
    plateGradientLight: [Color(0xFFD6DAE2), Color(0xFFC8CCD4), Color(0xFFB8BCC6)],
    rivetDark: Color(0xFF0D0F12),
    rivetLight: Color(0xFF8E939E),
  );

  static const HardwareEdition bauhausHeritage = HardwareEdition(
    type: HardwareEditionType.bauhausHeritage,
    title: 'BAUHAUS HERITAGE',
    subtitle: 'TUBULAR CHROME & PRIMARY',
    yearLabel: 'MOD. 03 · 1925',
    isPremium: true,
    darkCanvas: Color(0xFF101114),
    lightCanvas: Color(0xFFDCDAD4),
    darkModuleBg: Color(0xFF1E2025),
    lightModuleBg: Color(0xFFEAE7E0),
    darkBorder: Color(0xFF4A4E58), // Tubular chrome highlight
    lightBorder: Color(0xFF9E9B93),
    needleColor: Color(0xFFD62828), // Bauhaus Crimson
    filamentColor: Color(0xFFFCBF49), // Bauhaus Primary Yellow
    accentColor: Color(0xFF003049), // Bauhaus Blue
    plateGradientDark: [Color(0xFF2A2D35), Color(0xFF1D2026), Color(0xFF14161B)],
    plateGradientLight: [Color(0xFFE8E6E0), Color(0xFFDDD9D0), Color(0xFFCEC9BE)],
    rivetDark: Color(0xFF4A4E58),
    rivetLight: Color(0xFF7A7870),
  );

  static const HardwareEdition rawBrassPatina = HardwareEdition(
    type: HardwareEditionType.rawBrassPatina,
    title: 'RAW BRASS & PATINA',
    subtitle: 'BURNISHED MARINE CHRONO',
    yearLabel: 'MOD. 04 · 1954',
    isPremium: true,
    darkCanvas: Color(0xFF151815),
    lightCanvas: Color(0xFFD5D2C7),
    darkModuleBg: Color(0xFF202520),
    lightModuleBg: Color(0xFFDFDBCF),
    darkBorder: Color(0xFF5A5844), // Burnished Brass Border
    lightBorder: Color(0xFFB2AD97),
    needleColor: Color(0xFFE0B858), // Polished Brass Gold
    filamentColor: Color(0xFFE8A048), // Warm Candlelight Glow
    accentColor: Color(0xFF4D5D4B), // Patina Forest Olive
    plateGradientDark: [Color(0xFF2B2B22), Color(0xFF202018), Color(0xFF161611)],
    plateGradientLight: [Color(0xFFE2DEC8), Color(0xFFD6D1B8), Color(0xFFC6C0A6)],
    rivetDark: Color(0xFF7A6836),
    rivetLight: Color(0xFF968249),
  );

  static const List<HardwareEdition> all = [
    braunClassic,
    titaniumStealth,
    bauhausHeritage,
    rawBrassPatina,
  ];

  static HardwareEdition fromType(HardwareEditionType type) {
    switch (type) {
      case HardwareEditionType.braunClassic:
        return braunClassic;
      case HardwareEditionType.titaniumStealth:
        return titaniumStealth;
      case HardwareEditionType.bauhausHeritage:
        return bauhausHeritage;
      case HardwareEditionType.rawBrassPatina:
        return rawBrassPatina;
    }
  }

  static HardwareEdition fromString(String? key) {
    for (final e in all) {
      if (e.type.name == key) return e;
    }
    return braunClassic;
  }
}
```

In `lib/app/theme/theme_controller.dart`:
Update `ChassisThemeState` and `ThemeController`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'hardware_edition.dart';

class ChassisThemeState {
  final bool isDarkMode;
  final HardwareEdition edition;
  final bool isProUnlocked;

  const ChassisThemeState({
    this.isDarkMode = true,
    this.edition = HardwareEdition.braunClassic,
    this.isProUnlocked = true,
  });

  Color get canvasColor =>
      isDarkMode ? edition.darkCanvas : edition.lightCanvas;

  Color get moduleChassisColor =>
      isDarkMode ? edition.darkModuleBg : edition.lightModuleBg;

  Color get borderColor =>
      isDarkMode ? edition.darkBorder : edition.lightBorder;

  Color get textColor =>
      isDarkMode ? edition.lightCanvas : edition.darkCanvas;

  Color get needleColor => edition.needleColor;

  Color get filamentColor => edition.filamentColor;

  ChassisThemeState copyWith({
    bool? isDarkMode,
    HardwareEdition? edition,
    bool? isProUnlocked,
  }) {
    return ChassisThemeState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      edition: edition ?? this.edition,
      isProUnlocked: isProUnlocked ?? this.isProUnlocked,
    );
  }
}

class ThemeController extends StateNotifier<ChassisThemeState> {
  ThemeController({ChassisThemeState? initial})
      : super(initial ?? const ChassisThemeState());

  void toggleTheme() {
    state = state.copyWith(isDarkMode: !state.isDarkMode);
  }

  void setDarkMode(bool value) {
    state = state.copyWith(isDarkMode: value);
  }

  bool setHardwareEdition(HardwareEditionType type) {
    final nextEdition = HardwareEdition.fromType(type);
    if (nextEdition.isPremium && !state.isProUnlocked) {
      return false; // Locked
    }
    state = state.copyWith(edition: nextEdition);
    return true;
  }

  void setProUnlocked(bool unlocked) {
    state = state.copyWith(isProUnlocked: unlocked);
    // If locked and current edition is premium, revert to braunClassic
    if (!unlocked && state.edition.isPremium) {
      state = state.copyWith(edition: HardwareEdition.braunClassic);
    }
  }
}

final chassisThemeProvider =
    StateNotifierProvider<ThemeController, ChassisThemeState>((ref) {
  return ThemeController();
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/app/theme/hardware_edition_test.dart`
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add lib/app/theme/ test/app/theme/
git commit -m "feat(theme): implement HardwareEdition domain models and ThemeController extensions"
```

---

### Task 2: Drift SQLite Preferences Schema Migration & Settings Controller Wiring

**Files:**
- Modify: `lib/core/database/tables/desk_preferences_table.dart`
- Modify: `lib/core/database/app_database.dart`
- Modify: `lib/features/settings/presentation/settings_controller.dart`
- Modify: `test/core/database_test.dart`
- Modify: `test/features/settings/settings_controller_test.dart`

**Interfaces:**
- Consumes: `HardwareEditionType` from `lib/app/theme/hardware_edition.dart`
- Produces:
  - Table column: `deskPreferences.selectedEdition` (text), `deskPreferences.isProSimulated` (boolean)
  - `AppDatabase.updatePreferences({..., String? selectedEdition, bool? isProSimulated})`
  - `DeskPreferencesState`: `selectedEdition` (String), `isProSimulated` (bool)
  - `DeskPreferencesController`: `setHardwareEdition(HardwareEditionType type)`, `setProSimulated(bool value)`

- [ ] **Step 1: Write failing database unit test in test/core/database_test.dart**

In `test/core/database_test.dart`, add tests for `selectedEdition` and `isProSimulated`:
```dart
test('can persist and update selectedEdition and isProSimulated in preferences', () async {
  final initialPref = await db.watchDeskPreferences().first;
  expect(initialPref.selectedEdition, equals('braunClassic'));
  expect(initialPref.isProSimulated, isTrue);

  await db.updatePreferences(
    selectedEdition: 'titaniumStealth',
    isProSimulated: false,
  );

  final updatedPref = await db.watchDeskPreferences().first;
  expect(updatedPref.selectedEdition, equals('titaniumStealth'));
  expect(updatedPref.isProSimulated, isFalse);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/core/database_test.dart`
Expected: FAIL with compilation error: `selectedEdition` is not defined.

- [ ] **Step 3: Update DeskPreferences table, AppDatabase, and SettingsController**

In `lib/core/database/tables/desk_preferences_table.dart`:
```dart
import 'package:drift/drift.dart';

class DeskPreferences extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get soundVolume => real().withDefault(const Constant(0.8))();
  BoolColumn get parallaxEnabled => boolean().withDefault(const Constant(true))();
  IntColumn get activeAmbientTrackIndex => integer().withDefault(const Constant(0))();
  BoolColumn get foleyEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get hapticsEnabled => boolean().withDefault(const Constant(true))();
  TextColumn get selectedEdition => text().withDefault(const Constant('braunClassic'))();
  BoolColumn get isProSimulated => boolean().withDefault(const Constant(true))();
}
```

In `lib/core/database/app_database.dart`:
Upgrade `schemaVersion` to `2`.
Add migration strategy and update `updatePreferences`:
```dart
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(deskPreferences, deskPreferences.selectedEdition);
            await m.addColumn(deskPreferences, deskPreferences.isProSimulated);
          }
        },
      );

  Future<void> updatePreferences({
    double? soundVolume,
    bool? parallaxEnabled,
    int? activeAmbientTrackIndex,
    bool? foleyEnabled,
    bool? hapticsEnabled,
    String? selectedEdition,
    bool? isProSimulated,
  }) async {
    final existing = await (select(deskPreferences)..limit(1)).getSingleOrNull();
    final companion = DeskPreferencesCompanion(
      soundVolume: soundVolume != null ? Value(soundVolume) : const Value.absent(),
      parallaxEnabled: parallaxEnabled != null ? Value(parallaxEnabled) : const Value.absent(),
      activeAmbientTrackIndex: activeAmbientTrackIndex != null ? Value(activeAmbientTrackIndex) : const Value.absent(),
      foleyEnabled: foleyEnabled != null ? Value(foleyEnabled) : const Value.absent(),
      hapticsEnabled: hapticsEnabled != null ? Value(hapticsEnabled) : const Value.absent(),
      selectedEdition: selectedEdition != null ? Value(selectedEdition) : const Value.absent(),
      isProSimulated: isProSimulated != null ? Value(isProSimulated) : const Value.absent(),
    );

    if (existing == null) {
      await into(deskPreferences).insert(companion);
    } else {
      await (update(deskPreferences)..where((t) => t.id.equals(existing.id))).write(companion);
    }
  }
```

Run Drift code generation:
`/home/tuneeca/RSQUARE/flutter/bin/dart run build_runner build --delete-conflicting-outputs`

In `lib/features/settings/presentation/settings_controller.dart`:
- Add `selectedEdition` and `isProSimulated` to `DeskPreferencesState`.
- Add `setHardwareEdition(HardwareEditionType type)` and `setProSimulated(bool value)` to `DeskPreferencesController`, synchronizing with `ref.read(chassisThemeProvider.notifier)`.

- [ ] **Step 4: Run database and settings controller tests**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/core/database_test.dart test/features/settings/settings_controller_test.dart`
Expected: ALL PASS

- [ ] **Step 5: Commit changes**

```bash
git add lib/core/database/ lib/features/settings/ test/core/ test/features/settings/
git commit -m "feat(database): persist selectedEdition and isProSimulated preferences with Drift migration"
```

---

### Task 3: Material Gallery Card Swatches & Pro Simulator in TaktSettingsSheet

**Files:**
- Modify: `lib/features/settings/presentation/takt_settings_sheet.dart`
- Modify: `test/features/settings/takt_settings_sheet_test.dart`

**Interfaces:**
- Consumes: `HardwareEdition`, `HardwareEditionType`, `chassisThemeProvider`, `deskPreferencesControllerProvider`
- Produces:
  - Interactive Material Edition Gallery in Service Hatch
  - Simulated Studio Pro Switch row
  - Simulated Studio Pro upgrade dialog

- [ ] **Step 1: Write failing widget test in test/features/settings/takt_settings_sheet_test.dart**

Add tests to `test/features/settings/takt_settings_sheet_test.dart`:
```dart
testWidgets('TaktSettingsSheet renders Hardware Editions section with 4 swatches', (tester) async {
  await tester.pumpWidget(buildSheet());
  await tester.pump();

  expect(find.text('HARDWARE EDITIONS // CHASSIS MATERIALITY'), findsOneWidget);
  expect(find.text('BRAUN CLASSIC'), findsOneWidget);
  expect(find.text('TITANIUM STEALTH'), findsOneWidget);
  expect(find.text('BAUHAUS HERITAGE'), findsOneWidget);
  expect(find.text('RAW BRASS & PATINA'), findsOneWidget);
  expect(find.textContaining('SIMULATE STUDIO PRO CLEARANCE'), findsOneWidget);
});

testWidgets('Tapping unlocked edition equips it and triggers haptic click', (tester) async {
  await tester.pumpWidget(buildSheet());
  await tester.pump();

  final titaniumFinder = find.byKey(const ValueKey('edition_card_titaniumStealth'));
  expect(titaniumFinder, findsOneWidget);

  await tester.tap(titaniumFinder);
  await tester.pumpAndSettle();

  expect(find.text('EQUIPPED'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/settings/takt_settings_sheet_test.dart`
Expected: FAIL with missing text 'HARDWARE EDITIONS // CHASSIS MATERIALITY'.

- [ ] **Step 3: Implement Hardware Editions Gallery & Pro Simulator in TaktSettingsSheet**

In `lib/features/settings/presentation/takt_settings_sheet.dart`:
- Insert `_HardwareEditionsSection` with:
  1. `_SectionHeader(title: 'HARDWARE EDITIONS // CHASSIS MATERIALITY', textColor: primaryTextColor)`
  2. Horizontal scrollable row of 4 `_EditionCard` widgets:
     - Dimensions ~180w x 140h.
     - Gradient background matching `edition.plateGradient(isDark)`.
     - 4 corner rivet dots.
     - Title, year label, tier badge (`FREE` in bone, `STUDIO PRO` in filament amber).
     - Action button:
       - If currently selected: `EQUIPPED` (subtle disabled pill).
       - If unlocked: `EQUIP` (clickable pill).
       - If locked: `LOCKED // PRO` (with lock icon).
  3. `SIMULATE STUDIO PRO CLEARANCE` switch:
     - Mechanical toggle bound to `deskPreferencesControllerProvider.notifier.setProSimulated(val)` and `chassisThemeProvider.notifier.setProUnlocked(val)`.
  4. Dialog `_showStudioProDialog(BuildContext context)`:
     - Homage Dieter Rams design modal: "TAKT DESK STUDIO PRO // LIFETIME CLEARANCE".
     - Option to "UNLOCK NOW (SIMULATED)" which toggles pro on and equips the requested edition.

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/settings/takt_settings_sheet_test.dart`
Expected: ALL PASS

- [ ] **Step 5: Commit changes**

```bash
git add lib/features/settings/presentation/takt_settings_sheet.dart test/features/settings/takt_settings_sheet_test.dart
git commit -m "feat(settings): add Hardware Editions swatch gallery and simulated pro toggle to TaktSettingsSheet"
```

---

### Task 4: Dynamic Console Background, Ambient Layer & Spec Plate Edition Theming

**Files:**
- Modify: `lib/features/desk/presentation/widgets/desk_spec_plate_widget.dart`
- Modify: `lib/features/desk/presentation/ambient_lighting_layer.dart`
- Modify: `lib/features/desk/presentation/desk_canvas_screen.dart`
- Modify: `test/features/desk/desk_spec_plate_widget_test.dart`
- Modify: `test/features/desk/desk_screen_test.dart`

**Interfaces:**
- Consumes: `HardwareEdition` from `chassisThemeProvider`
- Produces:
  - Reactive ambient background lighting matched to active edition
  - Dynamic spec plate metallurgy: gradient, rivet color, subtitle stamp (`edition.subtitle`, `edition.yearLabel`)

- [ ] **Step 1: Write failing widget test in test/features/desk/desk_spec_plate_widget_test.dart**

Add test checking that `DeskSpecPlateWidget` updates stamp text and gradient when edition changes:
```dart
testWidgets('DeskSpecPlateWidget updates stamp title and gradient based on active edition', (tester) async {
  final container = ProviderContainer(
    overrides: [
      todayFocusStatsProvider.overrideWith(
        (ref) => Stream.value(const TodayFocusStats(completedCount: 1, totalMinutes: 25)),
      ),
    ],
  );
  addTearDown(container.dispose);

  container.read(chassisThemeProvider.notifier).setHardwareEdition(HardwareEditionType.titaniumStealth);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: DeskSpecPlateWidget(),
        ),
      ),
    ),
  );
  await tester.pump();

  expect(find.textContaining('TITANIUM STEALTH'), findsOneWidget);
  expect(find.textContaining('AEROSPACE PVD GRADE 5'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/desk/desk_spec_plate_widget_test.dart`
Expected: FAIL (text contains 'TAKT DESK' instead of 'TITANIUM STEALTH').

- [ ] **Step 3: Update DeskSpecPlateWidget and AmbientLightingLayer to reflect edition**

In `lib/features/desk/presentation/widgets/desk_spec_plate_widget.dart`:
- Consume `themeState.edition`.
- In Title: `${themeState.edition.title} · ${themeState.edition.yearLabel}`.
- In Subtitle: `${themeState.edition.subtitle} · STEREO 44.1kHz`.
- Gradient: `colors: isDark ? themeState.edition.plateGradientDark : themeState.edition.plateGradientLight`.
- Rivet dots: use `themeState.edition.rivetDark` / `rivetLight`.
- LEDs: lit LED uses `themeState.filamentColor`.

In `lib/features/desk/presentation/ambient_lighting_layer.dart`:
- Match subtle glow tint to `themeState.edition.accentColor`.

In `lib/features/desk/presentation/desk_canvas_screen.dart`:
- Scaffold background uses `themeState.canvasColor`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/desk/desk_spec_plate_widget_test.dart test/features/desk/desk_screen_test.dart`
Expected: ALL PASS

- [ ] **Step 5: Commit changes**

```bash
git add lib/features/desk/ test/features/desk/
git commit -m "feat(desk): dynamically theme ambient layer and spec plate with active HardwareEdition"
```

---

### Task 5: Instrument Dynamic Needle & Filament Accent Theming

**Files:**
- Modify: `lib/features/timer/presentation/chrono_dial_widget.dart`
- Modify: `lib/features/desk/presentation/widgets/monastic_switch_widget.dart`
- Test: `test/features/timer/chrono_dial_test.dart`
- Test: `test/features/desk/monastic_switch_test.dart`

**Interfaces:**
- Consumes: `themeState.needleColor`, `themeState.filamentColor` from `chassisThemeProvider`
- Produces:
  - Analog dial second/minute hand rendered in edition's needle color
  - Monastic switch vacuum tube warm filament rendered in edition's filament glow color

- [ ] **Step 1: Write failing widget test for ChronoDial needle color**

In `test/features/timer/chrono_dial_test.dart` (or create if needed):
Verify that needle paint color reflects `chassisThemeProvider.needleColor`.

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test test/features/timer/chrono_dial_test.dart`
Expected: FAIL.

- [ ] **Step 3: Connect needleColor and filamentColor to widgets**

In `lib/features/timer/presentation/chrono_dial_widget.dart`:
- Read `final themeState = ref.watch(chassisThemeProvider);`.
- Pass `themeState.needleColor` to dial hand painter.

In `lib/features/desk/presentation/widgets/monastic_switch_widget.dart`:
- Read `final themeState = ref.watch(chassisThemeProvider);`.
- Use `themeState.filamentColor` for the active vacuum tube filament lamp glow and shadow.

- [ ] **Step 4: Run full test suite and flutter analyze**

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter test`
Expected: 100% PASS across repository.

Run: `/home/tuneeca/RSQUARE/flutter/bin/flutter analyze`
Expected: 0 issues.

- [ ] **Step 5: Commit changes and push to GitHub**

```bash
git add lib/features/timer/ lib/features/desk/ test/
git commit -m "feat(instruments): connect dial needle and vacuum tube filament to active HardwareEdition"
git push origin main
```
