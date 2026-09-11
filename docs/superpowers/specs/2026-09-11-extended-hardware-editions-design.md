# Design Spec: Extended Hardware Editions & Procedural Textures (Organic Walnut & Forged Carbon)

**Date:** 2026-09-11  
**Feature:** Extended Hardware Editions (Free Atelier Cream + Pro Walnut & Carbon) & Live Theme Preview  
**Platform:** Android Mobile Console (Takt Desk, Braun / Dieter Rams Industrial Aesthetic)

---

## 1. Overview & Philosophy

Takt Desk honors Dieter Rams' 1960s Braun design philosophy (*"Weniger, aber besser"* / *"Less, but better"*) and honest materiality (*"Good design is honest"*). 

Currently, Takt Desk has 4 hardware editions with only 1 available to Free users (`Braun Classic`) and 3 Pro editions (`Titanium Stealth`, `Bauhaus Heritage`, `Raw Brass & Patina`).

To provide greater value to Free users while creating compelling tactile desire for Pro upgrades, this feature introduces:
1. **New FREE Edition: `Braun Atelier Cream` (MOD. 05 · 1965):**
   - Inspired by the iconic Braun T3 pocket radio and Atelier audio components by Dieter Rams. Warm off-white/cream matte ABS thermoplastic with signature Signal Orange needle and warm amber filament glow.
2. **New PRO Edition: `Mid-Century Dark Walnut` (MOD. 06 · 1958):**
   - Inspired by the warm architectural timber of the Braun SK-4 "Snow White's Coffin" and Atelier PK-G hi-fi consoles. Features rich organic walnut hardwood, satin polyurethane sheen, and champagne gold horological accents.
3. **New PRO Edition: `Forged Carbon Horology` (MOD. 07 · 2024):**
   - Inspired by high-end avant-garde horology crafted from compressed chopped carbon fibers. Features dark obsidian marble composite flakes, anisotropic light reflections, and vivid racing amber accents.
4. **Authentic Multi-Layer Procedural Textures:**
   - 100% mathematical vector canvas shaders for `HardwareTextureType.organicWalnut` and `HardwareTextureType.forgedCarbon` inside `MaterialTexturePainter` and `ChronoDialPainter`. Zero raster asset bloat, 120 FPS performance, razor-sharp on all DPIs.
5. **Interactive Theme Preview for FREE Users:**
   - Pro cards in `TaktSettingsSheet` display an interactive `[ PREVIEW 👁 ]` tactile badge.
   - `StudioProDialog` features an authentic **Physical Horological Plaque Showcase** rendering the exact material texture, metallic rivets, genuine needle accent, and glowing filament lamp, enticing Free users to unlock or simulate Pro clearance.

---

## 2. Hardware Editions Master Catalog

The catalog now comprises **7 Curated Editions** (2 Free, 5 Pro):

| ID | Title | Year / Model | Texture Type | Tier | Key Accents |
| :--- | :--- | :--- | :--- | :---: | :--- |
| `braunClassic` | BRAUN CLASSIC | MOD. 01 · 1960 | `matteAbsGrain` | **FREE** | Obsidian Matte ABS, Muted Ochre Needle, Amber Filament |
| `braunAtelierCream` | BRAUN ATELIER CREAM | MOD. 05 · 1965 | `matteAbsGrain` | **FREE** | Warm Bone / Cream Matte ABS, Signal Orange Needle, Amber Filament |
| `titaniumStealth` | TITANIUM STEALTH | MOD. 02 · 2026 | `brushedTitanium` | **PRO** | Grade 5 Brushed Titanium, Cobalt Cyan Needle, Neon Amber Filament |
| `bauhausHeritage` | BAUHAUS HERITAGE | MOD. 03 · 1925 | `tubularChrome` | **PRO** | Tubular Chrome Steel, Bauhaus Crimson Needle, Primary Yellow Filament |
| `rawBrassPatina` | RAW BRASS & PATINA | MOD. 04 · 1954 | `burnishedBrass` | **PRO** | Burnished Marine Brass, Gold Needle, Patina Olive Accent |
| `midCenturyWalnut` | MID-CENTURY WALNUT | MOD. 06 · 1958 | `organicWalnut` | **PRO** | Smoked Walnut Hardwood, Champagne Gold Needle, Hearthfire Filament |
| `forgedCarbon` | FORGED CARBON | MOD. 07 · 2024 | `forgedCarbon` | **PRO** | Marbled Forged Carbon Flakes, Racing Amber Needle, Phosphor Filament |

---

## 3. Token Definitions & Palette Specifications

### 3.1 `braunAtelierCream` (FREE)
- **Texture:** `HardwareTextureType.matteAbsGrain`
- **Dark Mode:**
  - Canvas: `#242321` (Warm Charcoal), Module: `#1E1D1B`, Border: `#3A3835`
  - Plate Gradient: `[#2C2A27, #211F1D, #181716]`, Rivet: `#4D4944`
- **Light Mode:**
  - Canvas: `#EAE6DC` (Warm Bone Cream), Module: `#DDD9CE`, Border: `#BDB8AB`
  - Plate Gradient: `[#F4F1EA, #EAE6DC, #DFDBD0]`, Rivet: `#A8A398`
- **Accents:**
  - Needle: `#FF5500` (Braun Signal Orange)
  - Filament: `#FFB703` (Warm Amber Glow)
  - Accent: `#4A5568` (Slate Neutral)

### 3.2 `midCenturyWalnut` (PRO)
- **Texture:** `HardwareTextureType.organicWalnut`
- **Dark Mode:**
  - Canvas: `#1C140E` (Deep Smoked Walnut), Module: `#16100B`, Border: `#4A3525`
  - Plate Gradient: `[#2E2218, #221811, #18100A]`, Rivet: `#C99A40` (Satin Brass Rivet)
- **Light Mode:**
  - Canvas: `#8D5B3A` (Warm Natural Teak), Module: `#73472A`, Border: `#B07C54`
  - Plate Gradient: `[#A8734C, #8D5B3A, #6E4426]`, Rivet: `#E0B858`
- **Accents:**
  - Needle: `#F3C68F` (Champagne Gold)
  - Filament: `#FF9233` (Warm Hearthfire Orange)
  - Accent: `#5E4028` (Warm Umber Accent)

### 3.3 `forgedCarbon` (PRO)
- **Texture:** `HardwareTextureType.forgedCarbon`
- **Dark Mode:**
  - Canvas: `#0F1012` (Obsidian Carbon Ash), Module: `#15161A`, Border: `#2D3039`
  - Plate Gradient: `[#1E2025, #141518, #0B0C0E]`, Rivet: `#3D424F` (Gunmetal Rivet)
- **Light Mode:**
  - Canvas: `#4A4D55` (Gunmetal Carbon), Module: `#3A3D44`, Border: `#636773`
  - Plate Gradient: `[#6B707B, #535760, #3E4148]`, Rivet: `#8E939E`
- **Accents:**
  - Needle: `#FF3B00` (Electric Racing Amber)
  - Filament: `#FFAA00` (Phosphor Neon Amber)
  - Accent: `#00B4D8` (Cobalt Precision Accent)

---

## 4. Procedural Texture Engine Algorithms

### 4.1 Organic Walnut Wood Grain (`_paintOrganicWalnut`)
Located in `lib/app/theme/widgets/material_texture_painter.dart`:
1. **Multi-frequency sinusoidal grain paths:**
   - Draw horizontal hairline wave curves every 3.0px:
     `yOffset = y + sin(x * 0.015) * 2.5 + sin(x * 0.04) * 1.2`
   - Alternating paint passes:
     - Heartwood grain: Dark rich umber (`#1C140E`, alpha 0.08–0.14)
     - Sapwood vein: Warm amber golden striations (`#D49B55`, alpha 0.05–0.10)
2. **Micro-Pore Wood Grain Vessels:**
   - Scatter elongated micro-oval stippling along grain flow lines.
3. **Polyurethane Satin Lacquer Sheen:**
   - 35-degree angled `LinearGradient` overlay simulating a hand-rubbed satin oil finish.
4. **Radial Vignette Relief:**
   - Perimeter radial gradient providing 2.5D architectural depth.

### 4.2 Forged Carbon Composite Flakes (`_paintForgedCarbon`)
1. **Randomized Polygon Facets:**
   - Grid-partitioned random facets simulating compressed chopped carbon fibers.
2. **Anisotropic Reflectivity Shading:**
   - Alternating reflectance: Specular graphite highlights (`#E0E5EC`, alpha 0.08–0.14) contrasted against deep light-absorbing carbon matrix (`#050507`, alpha 0.10–0.20).
3. **Diagonal Anisotropic Sheen:**
   - 45-degree dual specular linear gradient across the matrix.

---

## 5. Free User Experience & Live Theme Preview

### 5.1 Card Visual Badges (`_EditionCard`)
- Unlocked editions display `EQUIPPED` (amber) or `EQUIP` (button).
- Locked PRO editions display:
  - Header: `STUDIO PRO 🔒`
  - Action Row: `[ PREVIEW 👁 ]` (subtle outlined button) alongside `LOCKED // PRO`.
- Tapping anywhere on the locked card opens the enriched `StudioProDialog`.

### 5.2 Studio Pro Showcase Plaque (`StudioProDialog`)
When `showStudioProDialog` is opened for a hardware edition:
- It renders a dedicated **Physical Horological Plaque Showcase** widget:
  - 240dp x 90dp chassis card with 4 corner metallic rivets.
  - Authentic live background painted with `MaterialTexturePainter(textureType: edition.textureType)`.
  - Miniature circular dial with genuine `edition.needleColor` indicator hand.
  - Warm glowing filament lamp (`edition.filamentColor`).
  - Tactile edition metadata: title, year label, and poetic material provenance.
- Below the showcase plaque:
  - Secondary text: *"Lifetime clearance grants unlimited access to organic American walnut, marbled forged carbon, aerospace titanium, and all future artisanal console editions."*
  - Action Buttons: `CANCEL`, `TRY LIVE PREVIEW (10s)`, and `UNLOCK NOW (SIMULATED)`.

---

## 6. Architecture & Database Compatibility

- `HardwareEditionType`: enum updated with `braunAtelierCream`, `midCenturyWalnut`, `forgedCarbon`.
- `HardwareTextureType`: enum updated with `organicWalnut`, `forgedCarbon`.
- `AppDatabase`: The `selectedEdition` column in `DeskPreferencesTable` is a `TextColumn`. No SQLite schema migration or version bump is required; `HardwareEdition.fromString(key)` resolves all 7 enum strings seamlessly.
- Riverpod state management: `chassisThemeProvider` consumes the updated catalog seamlessly.

---

## 7. Testing & Verification

1. **Unit Tests:**
   - `test/app/theme/hardware_edition_test.dart`: Assert all 7 editions exist, assert `braunClassic` and `braunAtelierCream` have `isPremium == false`, and 5 others have `isPremium == true`. Verify token color validity.
   - `test/app/theme/material_texture_painter_test.dart`: Verify `MaterialTexturePainter` paints all texture types (`organicWalnut`, `forgedCarbon`, etc.) without throwing.
2. **Widget Tests:**
   - `test/features/settings/takt_settings_sheet_test.dart`: Verify 7 editions render in carousel, verify `(01 / 07)` counter, verify Free users can equip `braunAtelierCream` directly without Pro prompt, and verify Pro prompt with showcase plaque appears for Walnut and Carbon.
3. **Static Analysis & Full Suite:**
   - `flutter analyze`: 0 issues.
   - `flutter test`: 100% pass rate (270+ tests).
   - Zero occurrences of `tuneeca`.
