# Takt Desk: Hardware Material Editions (Freemium Architecture) Specification

**Date:** 2026-09-09  
**Platform Target:** Mobile Android  
**Status:** Approved for Implementation Planning  
**Design Philosophy:** Dieter Rams & Braun Industrial Aesthetic (*Weniger, aber besser*) — Freemium Craftsmanship  

---

## 1. Overview & Vision

Takt Desk is designed as an uncompromised, distraction-free analog workstation console. To support sustainable development under a **Freemium** model without introducing toxic monetization mechanisms (such as ads, user tracking, or pushy monthly subscriptions), Takt Desk introduces **Hardware Material Editions**.

Instead of cartoonish skins or garish gamification, each edition is a meticulously curated homage to landmark 20th-century Germanic and modernist industrial design. Switching editions re-skins the entire console cohesively:
- The desk canvas background and ambient lighting reflections
- Instrument chassis finishes and bevel borders
- Dial analog hands, ticks, and vacuum tube filament glow temperatures
- Lower debossed specification plate metallurgy and manufacture stamps

---

## 2. Hardware Editions Catalog

### 2.1 The 4 Curated Editions

| Edition Name | Tier | Inspiration | Primary Finishes | Accent & Needles | Glow Filament |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Braun Classic** | **FREE** | Dieter Rams, Braun 1960s (*Atelier & TP-1*) | Obsidian Black (`#141517`) / Warm Bone (`#EFECE6`) | Muted Ochre (`#C85A32`) | Filament Amber (`#D99B59`) |
| **Titanium Stealth** | **PRO** | Precision Anodized Aerospace Metallurgy | Deep Gunmetal (`#181A1E`) / Basalt Carbon (`#22262C`) | Electric Cobalt Cyan (`#3A86FF`) | Vivid Amber Neon (`#FF9E00`) |
| **Bauhaus Heritage** | **PRO** | Walter Gropius & Marcel Breuer Dessau 1925 | Tubular Chrome Steel (`#D4D8DD`) / Pure Stark Charcoal (`#111215`) | Bauhaus Crimson (`#D62828`) / Primary Yellow (`#FCBF49`) | Bauhaus Warm Gold (`#FCBF49`) |
| **Raw Brass & Patina** | **PRO** | Marine Navigation & Vintage Laboratory Chronometers | Burnished Raw Brass (`#C5A059`) / Thermal Carbon (`#1B1E1A`) | Polished Gold Brass (`#E0B858`) & Patina Olive (`#4D5D4B`) | Incandescent Candlelight (`#E8A048`) |

Each edition fully supports both **Dark** and **Light** chassis illumination modes via the existing mechanical header switch.

---

## 3. Data Architecture & State Management

### 3.1 Domain Model (`HardwareEdition`)
Located at `lib/app/theme/hardware_edition.dart`:
```dart
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

  // Visual Tokens
  final Color darkCanvas;
  final Color lightCanvas;
  final Color darkModuleBg;
  final Color lightModuleBg;
  final Color darkBorder;
  final Color lightBorder;
  final Color needleColor;
  final Color filamentColor;
  final Color accentColor;
  final List<Color> plateGradientDark;
  final List<Color> plateGradientLight;

  const HardwareEdition({...});

  static const List<HardwareEdition> all = [...];
  static HardwareEdition fromType(HardwareEditionType type) => ...;
}
```

### 3.2 State Controller (`ThemeController` & `ChassisThemeState`)
Located at `lib/app/theme/theme_controller.dart`:
```dart
class ChassisThemeState {
  final bool isDarkMode;
  final HardwareEdition edition;
  final bool isProUnlocked;

  const ChassisThemeState({
    this.isDarkMode = true,
    this.edition = const HardwareEdition.braunClassic(),
    this.isProUnlocked = true, // Default to true for simulated development mode
  });

  // Dynamic getters derived from selected edition
  Color get canvasColor => isDarkMode ? edition.darkCanvas : edition.lightCanvas;
  Color get moduleChassisColor => isDarkMode ? edition.darkModuleBg : edition.lightModuleBg;
  Color get borderColor => isDarkMode ? edition.darkBorder : edition.lightBorder;
  Color get needleColor => edition.needleColor;
  Color get filamentColor => edition.filamentColor;
}
```

Methods in `ThemeController`:
- `void toggleTheme()`: Switch between Dark and Light mode.
- `void setHardwareEdition(HardwareEditionType type)`: Switch active edition (checks `isProUnlocked` if `edition.isPremium`).
- `void setProUnlocked(bool unlocked)`: Simulate pro unlock state.

### 3.3 Database Persistence (Drift SQLite)
Table `desk_preferences` in `lib/core/database/tables/desk_preferences_table.dart`:
- `TextColumn get selectedEdition => text().withDefault(const Constant('braunClassic'))();`
- `BoolColumn get isProSimulated => boolean().withDefault(const Constant(true))();`

Database migration strategy:
- Upgrade database schema version to `3`.
- In `migration.onUpgrade`: add columns `selected_edition` and `is_pro_simulated` with default fallback values.

---

## 4. User Interface & Interactions

### 4.1 Service Hatch Material Gallery (`TaktSettingsSheet`)
Located in `lib/features/settings/presentation/takt_settings_sheet.dart`:
A dedicated section inserted between `HARDWARE ACOUSTICS & TACTILITY` and `SYSTEM CLEARANCE & LOCKDOWN`:

```
┌────────────────────────────────────────────────────────┐
│ HARDWARE EDITIONS // STUDIO ARCHIVE                    │
├────────────────────────────────────────────────────────┤
│ [CAROUSEL / HORIZONTAL SWATCH CARDS]                   │
│                                                        │
│ ┌──────────────────────┐  ┌──────────────────────────┐ │
│ │ BRAUN CLASSIC        │  │ TITANIUM STEALTH         │ │
│ │ 1960 · ATELIER       │  │ 2026 · AEROSPACE PVD     │ │
│ │ [FREE]               │  │ [STUDIO PRO]             │ │
│ │                      │  │                          │ │
│ │ [EQUIPPED]           │  │ [EQUIP] / [LOCKED]       │ │
│ └──────────────────────┘  └──────────────────────────┘ │
│                                                        │
│ ┌────────────────────────────────────────────────────┐ │
│ │ SIMULATE STUDIO PRO CLEARANCE           [ TOGGLE ] │ │
│ │ Toggle to test Pro locked vs equipped state        │ │
│ └────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────┘
```

**Card Interaction:**
- Tap on an unlocked edition:
  - Updates `chassisThemeProvider`.
  - Persists preference in database.
  - Plays `SoundEffect.dialClick` and `HapticService.selectionClick()`.
- Tap on a locked edition (when `isProUnlocked == false`):
  - Triggers soft tactile warning `HapticService.lightClick()`.
  - Shows simulated Studio Pro Upgrade Dialog ("Takt Desk Studio Edition · Permanent Lifetime Unlock").

### 4.2 Console Dynamic Styling
1. **`DeskCanvasScreen`**: Background ambient lighting and canvas color reactively adapt to `themeState.canvasColor`.
2. **`ChronoDialWidget`**: Dial needle painter uses `themeState.needleColor`. The knurled crown and bezel use `themeState.moduleChassisColor` and `borderColor`.
3. **`MonasticSwitchWidget`**: Tube glow lamp uses `themeState.filamentColor`.
4. **`DeskSpecPlateWidget`**: Metal plate background uses `edition.plateGradient`, rivets use edition-matched metal tone, and subtitle displays edition lineage.
5. **`VinylPlayerWidget`** & **`ReceiptRunnerWidget`**: Tone arm, vinyl label, paper casing, and hardware rivets adopt edition material colors.

---

## 5. Testing & Quality Gates

1. **Unit Tests:**
   - `HardwareEdition` test: Verify all 4 editions have valid distinct color tokens and labels.
   - `ThemeController` test: Test edition switching, dark/light toggle within editions, and pro simulation lock guard.
   - `AppDatabase` test: Verify saving and loading `selectedEdition` and `isProSimulated`.
2. **Widget Tests:**
   - Test edition swatches in `TaktSettingsSheet`: selecting an edition updates the state and persists to database.
   - Test simulated pro switch: toggles lock/unlock status of Pro editions.
   - Test `DeskCanvasScreen` and `DeskSpecPlateWidget`: correctly reflects selected edition tokens.
3. **Quality Standards:**
   - `flutter analyze`: 0 warnings, 0 lints.
   - `flutter test`: 100% test pass rate across the full repository.
