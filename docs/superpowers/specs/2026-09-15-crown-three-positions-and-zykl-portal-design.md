# Technical Specification: Crown Three-Position Physical Mechanics & Zykl.app Portal Integration

## 1. Overview & Context

This specification addresses two key enhancements for **ZYKL (Takt Desk)**:
1. **Mechanical Crown 3-Level Physical Positioning**:
   Resolves the visual issue where the crown appeared submerged/pre-started in standby, by creating three distinct, mechanically authentic vertical elevations:
   - **NORMAL (Standby / Idle)**: Crown rests proudly outside the case bezel, seated on the collar.
   - **START / RUNNING (Active Pomodoro)**: Crown depresses $+4\text{px}$ into the case socket while timer is running (bi-stable monopusher engaged state).
   - **PULL CROWN (Sequential Calibration)**: Crown pulls upward $-8\text{px}$ outward, exposing an $8\text{px}$ polished metallic stem shaft for stage calibration.
2. **Zykl.app Website & Privacy Integration**:
   Provides an official portal entry in the application settings / about section (`TaktSettingsSheet`), allowing users to open `https://zykl.app` to access web content, user guides, and privacy disclosures. Implemented natively via Android `ACTION_VIEW` Intent through the existing system `MethodChannel` without third-party plugin bloat.

---

## 2. Architecture & Mechanical Geometry

### 2.1 Dial Headroom & Crown Base Geometry

In `ChronoDialWidget`:
- Currently, `SizedBox(width: dialDimensions.width, height: dialDimensions.height + 14)` with the dial positioned at `top: 14` left only $14\text{px}$ of headroom, causing the crown cap ($12\text{px}$) to sit at $y \in [14, 26]$, which submerged it inside the dial circle.
- **New Geometry**:
  - Headroom increased to $24\text{px}$:
    `SizedBox(width: dialDimensions.width, height: dialDimensions.height + 24)`
  - Circular Dial Canvas positioned at `top: 24`:
    Outer rim peak at 12 o'clock sits at $(x = \text{center}, y = 24)$.
  - `CrownPushButton` positioned at `top: 0`:
    Outer bounding box: $36\text{px}$ wide, $28\text{px}$ high.
  - **Stem Collar** ($14\text{px} \times 4\text{px}$):
    Anchored at `bottom: 0` ($y = 24..28$ in stack coordinates), seating flush into the dial's 12 o'clock outer bezel socket.
  - **Stem Shaft** ($8\text{px} \times 8\text{px}$):
    Anchored at `bottom: 4` ($y = 16..24$ in stack coordinates), polished metallic gradient.

### 2.2 The Three Physical Elevations

Inside `CrownPushButton`:
- Bounding Box: `width: 36, height: 28`.
- Crown Cap: `width: 32, height: 12`.
- Base resting cap position: `top: 12.0` ($y = 12..24$ in widget coordinates, matching $y = 12..24$ in parent dial coordinates).
- Visual levels:
  1. **NORMAL (Standby / Idle)**:
     - `isPressed = false`, `isPulledOut = false`.
     - Cap offset: $\Delta y = 0.0\text{px}$ (`top = 12.0`).
     - Cap spans $y = 12..24$, sitting squarely above the dial rim ($y = 24$).
     - The cap is 100% visible, protruding outside the case bezel like a genuine watch crown. Stem shaft is completely hidden.
  2. **START / RUNNING (Active)**:
     - `isPressed = true`, `isPulledOut = false`.
     - Cap offset: $\Delta y = +4.0\text{px}$ (`top = 16.0`).
     - Cap spans $y = 16..28$, depressed $4\text{px}$ into the collar/socket.
     - Animated with `Curves.easeInOut` ($140\text{ms}$).
     - Provides tactile visual confirmation of the running chronograph mechanism.
     - When paused or reset, smoothly returns to Normal ($\Delta y = 0.0\text{px}$).
  3. **PULL CROWN (Calibration)**:
     - `isPressed = false`, `isPulledOut = true`.
     - Cap offset: $\Delta y = -8.0\text{px}$ (`top = 4.0`).
     - Cap spans $y = 4..16$, lifted $8\text{px}$ away from the collar.
     - The $8\text{px}$ polished metallic stem shaft ($y = 16..24$) is fully exposed and gleaming.
     - Animated with `Curves.easeOutBack` ($160\text{ms}$).
     - Accompanied by `SoundEffect.drawerLatch` and `HapticService.selectionClick()`.

### 2.3 Gestures & State Transitions

- **Swipe/Drag Up ($\Delta y < -8\text{px}$ or fling velocity $< -200\text{px/s}$)**:
  - If idle in Standby: triggers `onPullOut` $\to$ transitions to `PULL CROWN` mode.
  - If running or already pulled out: no-op.
- **Swipe/Drag Down ($\Delta y > 8\text{px}$ or fling velocity $> 200\text{px/s}$)**:
  - If in `PULL CROWN` mode: triggers `onPushIn` $\to$ transitions back to `NORMAL`, playing `SoundEffect.springButton`.
- **Tap**:
  - In `NORMAL`: starts timer $\to$ transitions to `START / RUNNING`.
  - In `START / RUNNING`: pauses timer $\to$ transitions to `NORMAL`.
  - In `PULL CROWN`: sequentially advances calibration stages ($1/4 \to 2/4 \to 3/4 \to 4/4 \to \text{NORMAL}$).

---

## 3. Zykl.app Portal & Privacy Integration

### 3.1 Native Intent Handling (`MainActivity.kt`)

In `android/app/src/main/kotlin/com/zykl/app/MainActivity.kt`:
- Under `FOCUS_CHANNEL` (`com.takt.desk/focus_lock`) or dedicated `SYSTEM_CHANNEL` (`com.takt.desk/system`):
  Add `openUrl` method:
  ```kotlin
  "openUrl" -> {
      val url = call.argument<String>("url")
      if (!url.isNullOrBlank()) {
          try {
              val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                  addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
              }
              startActivity(intent)
              result.success(true)
          } catch (e: Exception) {
              result.error("URL_ERROR", e.localizedMessage, null)
          }
      } else {
          result.error("INVALID_ARGS", "URL is null or empty", null)
      }
  }
  ```

### 3.2 Flutter Service Client (`url_service.dart`)

In `lib/core/services/url_service.dart`:
```dart
class UrlService {
  static const MethodChannel _channel = MethodChannel('com.takt.desk/focus_lock');

  static Future<bool> openUrl(String url) async {
    try {
      final success = await _channel.invokeMethod<bool>('openUrl', {'url': url});
      return success ?? false;
    } catch (_) {
      return false;
    }
  }
}
```

### 3.3 UI Integration in `TaktSettingsSheet`

In `lib/features/settings/presentation/takt_settings_sheet.dart` within `_buildBraunCreedCard`:
- Add a prominent, beautifully styled industrial action block above the open-source licenses:
  ```dart
  // ZYKL.APP Official Web Portal & Privacy Policy
  InkWell(
    onTap: () {
      HapticService.selectionClick();
      UrlService.openUrl('https://zykl.app');
    },
    borderRadius: BorderRadius.circular(4.0),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2125) : const Color(0xFFDDD9CE),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: TaktColors.filamentAmber.withValues(alpha: 0.6), width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.language, size: 14, color: TaktColors.filamentAmber),
          const SizedBox(width: 8),
          Text(
            'ZYKL.APP // PORTAL & PRIVACY',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: TaktColors.filamentAmber,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.arrow_outward, size: 12, color: TaktColors.filamentAmber),
        ],
      ),
    ),
  ),
  ```
- Additionally, display `zykl.app` in the legal/privacy attribution text.

---

## 4. Verification Plan

1. **Widget Tests for 3 Crown Positions**:
   - `Normal`: Crown cap sits at `top: 12.0`, stem hidden, dial headroom clear.
   - `Start/Running`: Crown cap moves down to `top: 16.0` ($+4\text{px}$ depression).
   - `Pull Crown`: Crown cap moves up to `top: 4.0` ($-8\text{px}$ elevation), stem shaft visible.
2. **Native & Unit Tests for UrlService**:
   - Verify `UrlService.openUrl` invokes `openUrl` with URL string on MethodChannel.
3. **Settings Sheet Test**:
   - Tap `ZYKL.APP // PORTAL & PRIVACY` triggers `UrlService.openUrl` and haptic feedback.
4. **Full Regression Test Suite**:
   - `flutter test` (all 362+ tests pass).
   - `flutter analyze` (0 issues).
   - Clean namespace check (`tuneeca` = 0).
   - Production APK build verification.
