# ZYKL Flutter app — Agent Handoff Log

> Read this first when taking over. Newest entry on top. Any AI agent (Claude, Codex, Gemini, ...) should
> append an entry here after finishing work, keeping the same structure. Product context: `docs/zykl-summary/`.

## Project facts (stable)
- App: **ZYKL: Pomodoro Focus Timer**, Flutter, package `com.zykl.app`, folder name `Takt Desk` is legacy
  (Dart package `takt_desk`, MethodChannels `com.takt.desk/*` — do not rename casually).
- Website repo (separate): `/home/tuneeca/RSQUARE/Android/zykl.app` (Next.js on Cloudflare Worker).
- Native Android code: `android/app/src/main/kotlin/com/zykl/app/` (MainActivity = audio/focus/widget channels,
  TimerForegroundService = background countdown + completion, MediaNotificationService = vinyl notification).
- Verify with: `flutter analyze` → 0 issues; `flutter test -j 1` → all pass (416+ at last full run);
  Kotlin: `cd android && ./gradlew :app:compileDebugKotlin --offline -q`.
- Run heavy jobs (build/render/test) one at a time with `nice`. Do NOT build APK/AAB unless the user asks —
  the user reviews on the Linux emulator first. Release outputs go to `build_outputs/` (git-ignored).
- **Always build with `scripts/build_test_apks.sh [developer-pro] [user-testing] [aab]`.** It runs each build in a
  systemd cgroup (MemoryMax 4.5 GB, 2 cores, nice 19) and stops the Gradle daemons between builds. Plain
  `flutter build` back-to-back froze the PC twice on 2026-10-01 (Gradle + Dart AOT + the owner's Chrome > 7.6 GB RAM).
  `android/gradle.properties` also sets `kotlin.compiler.execution.strategy=in-process` (no separate Kotlin daemon).
- Build recipe (one build at a time): `nice -n 19 flutter build apk --release [--dart-define=ENABLE_PRO_SIMULATION=true]`
  → copy `build/app/outputs/flutter-apk/app-release.apk` to `build_outputs/zykl-{developer-pro|user-testing}-universal.apk`.
  **Do NOT use `--split-per-abi` for test APKs**: (1) the owner's test phone rejects arm64-only APKs ("package
  appears to be invalid", most likely a 32-bit/armeabi-v7a Android), and (2) split builds get versionCode 2001/4001,
  which then blocks installing the Play build (versionCode 1) as a "downgrade". The universal APK (~45 MB) runs on
  phones (32/64-bit) and the x86_64 Linux emulator. AAB: `flutter build appbundle --release` →
  `zykl-playstore-release.aab` (no dart-define, so PRO simulation is off). Older outputs live in `build_outputs/previous/<date>/`.
- **Do not build APK/AAB unless the owner asks in that message** (owner reviews code changes on Linux first).
- Never print/commit the upload keystore (`../keystores/zykl-upload.jks`, `android/key.properties`).
- Brand: keep "Quiet Time. Physical Intent."; avoid the word "Braun" in user-facing text.

## 2026-10-07 (c) — Audit hardening  (status: done + verified; NOT committed; website NOT deployed)

App (`Takt Desk`):
- **Release signing fails closed** (`android/app/build.gradle.kts`): `assembleRelease`/`bundleRelease` without
  `android/key.properties` now throws instead of silently using the debug key. Escape hatch for a throwaway local
  release: `ZYKL_ALLOW_DEBUG_RELEASE=1`. Verified with Gradle dry runs (`-m`): no key → fails; no key + escape → ok;
  debug build → ok; devpro → ok; with key → ok.
- **Developer-pro APK is now a separate app**: Gradle decodes `-Pdart-defines` (what `flutter build --dart-define`
  passes); when `ENABLE_PRO_SIMULATION=true` it sets `applicationIdSuffix = ".devpro"`, launcher label
  "ZYKL DEV PRO" (manifest `android:label="${appLabel}"` placeholder, default `@string/app_name`) and signs with the
  **debug key**, never the upload key. It installs next to the Play version and a leaked copy cannot pass as the store
  app. `scripts/build_test_apks.sh` needs no change. Note for the owner's test phone: the old dev-pro install
  (`com.zykl.app`) stays until uninstalled; the new one is `com.zykl.app.devpro`.
- `MainActivity.startAmbient` accepts a Dart asset path only if it matches `assets/audio/vinyl_[a-z0-9_]+\.ogg`
  (all 20 tracks do); anything else falls back to the index table.
- Root `.gitignore`: `.env`, `.env.*`, `*.jks`, `*.keystore`, `*.p12`, `*.pem`, `key.properties`, `Claude outputs/`;
  `android/.gitignore`: `/build/` (Gradle reports).

Website (`zykl.app`):
- CSP drops `'unsafe-eval'` (`public/_headers`, `vercel.json`); the production bundles contain no `eval`/`new Function`.
  `'unsafe-inline'` stays: the static export inlines ~10 per-build RSC/JSON-LD scripts and has no server for nonces.
  Verified by serving `out/` locally with the exact `_headers` CSP: home, /coming-soon, /changelog, /terms, /about
  hydrate with no CSP violations; `frame-ancestors 'none'` blocks framing.
- Removed dead `src/components/sections/FeedbackTerminal.tsx` (never imported).
- Apps Script webhook: global rate limit 20 requests / 10 min via `CacheService` under the script lock → `busy`
  (no caller IP in Apps Script). Stub-tested. **Owner must redeploy the Apps Script** (new version of the existing
  deployment) for this and the formula fix to go live.

Not done (by design or owner action): billing server verification (no backend), `WidgetActionReceiver` writing SQLite
next to Drift (consistency, not security), GitHub token in `11labs.md` (owner: move to credential helper + rotate),
`img-src https:` in CSP (needed for external images in content).

## 2026-10-07 (b) — Security audit + fixes, demo videos v3 rendered, v1.0.1+2 built  (status: committed + pushed, tag v1.0.1; AAB not uploaded yet)

- **Demo videos v3 rendered** (all 8, 1080×1350, 60 fps, AAC): `promo/Konten/Konten 1/video/ZYKL_Demo_*_4x5.mp4`
  (Overview 31.1 s, Reading 20.9, Coding 29.2, Studying 33.8, Writing 26.3, Creative 34.3, Languages 25.2, Admin 29.3).
  Calm camera: whole phone, still, zooms only on the SHOTS in `promo/Konten/demo/compose.py`. Awaiting owner review.
  Old v2 videos: `~/.cache/zykl-film/content_videos_v2/`.
- **Security audit** (skill `security-audit`, quick profile, scoped to this repo + `zykl.app/`, source-only: no target
  code executed). Artifacts: `~/security-audit-skill/zykl/run-1/` (`REPORT.md`, `NEEDS-VALIDATION.md`, `findings.json`,
  `coverage-ledger.json`; both skill validators pass). 0 confirmed, 3 needs_validation leads, all fixed below.
  1. **Unpaid pending purchase unlocked PRO** via restore: `in_app_purchase_android` 0.5.3 `restorePurchases` marks every
     Play purchase `restored`, including `purchaseState == pending` (cash not paid). Fix: `isPaidPurchase()` in
     `lib/core/billing/pro_store.dart` (GooglePlayPurchaseDetails → `purchaseState == purchased`);
     `ProPurchaseController._onPurchases` keeps such purchases `pending`, grants nothing and does not acknowledge them.
     `in_app_purchase_android: ^0.5.3` is now a direct dependency (lock unchanged except "direct main").
     Tests: 2 new cases in `test/core/billing/pro_purchase_controller_test.dart`; the pending one fails without the fix.
     Device check still worth doing: closed-testing licence tester + Play "slow test card", relaunch before approval.
  2. **Other apps could start/pause the timer** with `open_feature=toggleTimer` on the exported `MainActivity`
     (`onNewIntent` forwarded any value to the widget-action stream). Fix: `MainActivity.externalFeature()` allowlists
     `studio_pro`, `tasks`, `dial` at all three reads; `toggleTimer` now only comes from the non-exported
     `WidgetActionReceiver` via `sendWidgetAction`. Kotlin compiles. Emulator check: `adb shell am start -n
     com.zykl.app/.MainActivity --es open_feature toggleTimer` must not change the timer.
  3. **Website feedback → Sheet formula injection** (`zykl.app/scripts/feedback-apps-script.gs`): values starting with
     `= + - @` were stored as formulas. Fix: `text_()` caps every field, `literal_()` prefixes an apostrophe, category
     allowlist (unknown → `OTHER`), lock result honoured (`busy`), generic `error` response (details in `console.error`).
     Verified with a node stub harness (scratch only). **Owner must paste the new script into the Apps Script editor and
     deploy a new version**; the repo copy does not update the live web app.
- Hardening done: `promo/Video Motion v4 (wip)/audio/generate_audio.py` reads only the first line of `11labs.md`
  (that file also holds a GitHub token; whole-file read could send it to ElevenLabs). Owner advised to move the token to
  a credential helper and rotate it.
- Hardening NOT done (open): release signing falls back to the debug key silently (`build.gradle.kts:52-55`, make it
  fail); developer-pro APK is a release build with PRO unlocked, same applicationId and upload key (use a `.devpro`
  flavor + debug signing); CSP `'unsafe-inline' 'unsafe-eval'`; unused `FeedbackTerminal.tsx`; webhook rate limit;
  root `.gitignore` patterns for `.env*`, `*.jks`, `*.pem`.
- Verified: `flutter analyze` 0 issues; `flutter test -j 1` **450 pass** (1 skipped); Kotlin compiles.
- Version bumped to **1.0.1+2** (pubspec). v1.0.0 outputs archived in `build_outputs/previous/2026-10-02-v1.0.0/`.
- **Built 2026-10-07 12:28–12:36** with `scripts/build_test_apks.sh aab user-testing developer-pro` (exit 0):
  `build_outputs/zykl-playstore-release.aab` (65.4 MB), `zykl-user-testing-universal.apk` (66.9 MB),
  `zykl-developer-pro-universal.apk` (66.4 MB). versionCode 2 / 1.0.1. All signed with the upload key (SHA-256
  `27:5B:8E:D7…A1:23`, same as v1.0.0; no debug-key fallback). Next: owner uploads the AAB to Play Console → Closed
  testing → Create new release.
- **Committed and pushed 2026-10-07:** app repo `16f64a0` billing, `e435002` android intent, `1b743b1` promo key,
  `db83929` release (tag **`v1.0.1`**, source identical to the build), handoff; website repo `0ab09ea` (Apps Script fix).
- **Website NOT deployed yet:** `npx wrangler whoami` = not authenticated on this machine. The owner runs
  `npx wrangler login` once (browser OAuth), then `npm run deploy` in `zykl.app/` (next build passes; `out/` verified:
  opt-in link on /coming-soon, Rp 69.000 copy on /terms). Unless Cloudflare Workers Builds is connected to the GitHub
  repo (check the Worker's Settings → Build), pushing does not update zykl.app. The Apps Script fix is separate: paste
  into the Apps Script editor and deploy a new version of the existing web app deployment.

## 2026-10-07 — Closed test live; PRO badge, docs rewrite, beta link, calm camera for the demo videos  (status: committed + pushed; website NOT deployed)

- **Play status (owner, 2026-10-07):** Closed testing track "Tester" is **Active**, release 1 (1.0.0) available to
  testers since 2026-10-05, 178 countries. Owner still needs **3 more testers** to reach 12, then 14 days.
- **PRO badge bug fixed** (`vinyl_disc_drawer_widget.dart`): premium sleeves showed "STUDIO PRO 🔒" even when owned.
  Now `STUDIO PRO 🔒` only while locked, `STUDIO PRO` when unlocked (uses the card's existing `isUnlocked`).
  Test assertions added (scoped to `record_sleeve_14`; the PageView also builds neighbour cards).
  `flutter test -j 1 test/features/vinyl` → 36 pass. Note: `dart format` reformats whole files here; don't run it
  on untouched files (noise diffs).
- **Docs:** `docs/zykl-summary/01_APP_ARCHITECTURE.md` **rewritten from the real code** (the old one described Kotlin
  Jetpack Compose, Room, Billing v7, EncryptedSharedPreferences, SKU `zykl_studio_pro`: none of that exists).
  `00_OVERVIEW_PRODUCT.md`: version (was "v1.0.5 Build 105"), the 12 edition names (the old table was invented),
  the 20 soundscape names (8 free / 12 PRO), SDK levels (minSdk 24, targetSdk 36). `02_UI_UX…`: note that the app
  uses system `monospace`, JetBrains Mono is website-only. README index updated.
- Verified while auditing: release builds ignore the DB's `isProSimulated` (`settings_controller.dart` forces
  `effectivePro = false` unless simulation), so the column default `true` is harmless. Tag `v1.0.0` = HEAD for
  `lib/`, `android/`, pubspec (the uploaded AAB matches the source). Website remote URL no longer embeds a token.
- **Website** (`zykl.app/src/data/app.ts`): `BETA_OPT_IN_URL` = `https://play.google.com/apps/testing/com.zykl.app`,
  so step 02 on `/coming-soon` is a live button. `tsc` clean; checked on `next dev` (link present, no console errors).
  **Needs `npm run deploy` (owner OK)**; that deploy also ships the pricing copy from `0bf41f7`.
- **Content-pack demo videos, camera v3** (owner: too much auto-zoom following the cursor, viewers get dizzy).
  `promo/Konten/demo/compose.py` no longer follows the per-tap `cam` cues. The phone stays whole and still; each clip
  has 2–4 **SHOTS** (key moments only: preset dial in Overview, typing the first task, DONE stamp, crown wind,
  countdown start, lockdown hold). Each shot frames a screen **region** (`DIAL`, `DIAL_LOCK`, `SLIP`, `DISP`,
  `LOCK`) between the caption scrims, max zoom 1.55, holds perfectly still, eases in/out once (smootherstep 1.0 s,
  zoom interpolated geometrically); shots < 1.6 s apart glide directly. Result: 2–6 moves per clip (was 12–23 cue
  changes), camera moving 11–21 % of the time. `--cues` prints a capture's chapter/tap timeline for retiming SHOTS
  (times are capture seconds; re-check after any re-capture). No re-capture was needed.
  Render: `~/.cache/zykl-film/render_content_v3.sh` (sequential, cgroup 3 GB, resumable: skips existing files), log
  `~/.cache/zykl-film/render_content_v3.log`. Old v2 videos moved to `~/.cache/zykl-film/content_videos_v2/`.
- Still open: timer notification channel is `IMPORTANCE_LOW` (lands in "Silent"); changing it needs a NEW channel ID
  (existing installs keep the old importance). `promo/Konten/` (≈71 MB of mp4/png) is untracked; keep renders out of
  git. README.md is still the Flutter template.

## 2026-10-06 — Content-pack demo videos (all 8 use-case posts)  (status: v2 with opening/closing rendered, awaiting owner review; nothing committed)

- Owner asked for "screen-record style" demo videos with a device mockup and smooth auto-zoom, matching the
  use-case content pack (`promo/Konten/Konten 1/zykl-use-case-content-pack-en-id.docx`, posts 1/4/2 = overview,
  reading, coding). Video remaster work is **paused** by the owner.
- Q&A same day: on the Play internal-test build, "Upgrade PRO" unlocking instantly is a **license-tester test
  purchase** (no charge), not a leak. Release code only unlocks on Play `purchased/restored`. Non-license testers pay
  for real. Cosmetic bug noted, not fixed: vinyl card badge still shows "STUDIO PRO 🔒" when owned
  (`vinyl_disc_drawer_widget.dart:587`).
- **Capture (real widgets, no device):** `film_capture/content_clips_test.dart` + `film_capture/run_content.sh
  [--smoke] [overview|reading|coding]` (one at a time, cgroup-capped). Output `~/.cache/zykl-film/content/<clip>/`.
  The clips drive the UI like a person: tap preset segment, open record drawer, page to the disc, LOAD, tap the platter,
  "+" → type the task into the slip sheet → FEED PAPER, double-tap to stamp, crown to start.
- `film_capture/film_scene.dart`: new `FilmAudioService` (overrides `audioServiceProvider`) logs every foley/ambient
  event per frame; new `s.cam(point, zoom)` / `s.camOn(finder, zoom)` camera cues, `s.typeText`, and
  `s.rec.chapter = 'NN|Label|Value'` captions. All written into `touches.json` (`cam`, `sfx`, `ch`).
- **Compose:** `promo/Konten/demo/compose.py <clip> [--still s ...]` → 1080×1350 (4:5, matches the carousel
  slides) 60 fps: phone mockup + status bar, critically-damped spring camera toward the cues (no touch circles),
  slide-style header/footer/frame, step captions, audio = the app's real foley (MainActivity mapping; springButton /
  stepperPrint are silent on device too) + the loaded soundscape, loudnorm −16 LUFS. Output:
  `promo/Konten/Konten 1/video/ZYKL_Demo_<Clip>_4x5.mp4`.
- Rendered 2026-10-06: Overview 18.6 s, Reading 16.9 s, Coding 25.2 s (1080×1350, 60 fps, AAC). Capture ≈3–4 min per
  clip at 3×, compose ≈2–5 min per clip (cgroup 3 GB). Possible next steps if the owner wants them: ID-language captions,
  a 9:16 cut (change W/H/DEVICE_H/ANCHOR in compose.py), and the remaining posts (studying, writing, creative, languages,
  admin; their slides are not in Konten 1 yet). `flutter analyze film_capture` = 0 issues.
- **v2 (owner feedback, same day):** Overview now also shows tasks (2 typed, 1 stamped). All videos get a 1.2 s
  opening (copy reveals, phone rises in) and a 2.8 s closing (phone fades, end card: icon, ZYKL, "Pomodoro Focus Timer",
  tagline, zykl.app, the app's twin-hammer bell). No "beta" wording (content-pack rule). Added the 5 remaining posts:
  studying (25/5, Lo-Fi Rain, 3 tasks, Lockdown + 5 s hold), writing (crown → 40/8, Warm Tape), creative (crown → 45/10,
  Atelier Cream edition via Settings + LIGHT theme, Clair de Lune), languages (25/5, Kyoto Bamboo), admin (15/3,
  Monastic Cello Solo, stamp all 3). Headlines for these 5 are my own (no slides yet): edit `CLIPS` in compose.py.
- **App code touched:** `AppSecurityConfig.showDeveloperTools` now also requires `!FILM_HIDE_DEV_TOOLS` (dart-define
  set only by `run_content.sh`) so the debug-mode capture doesn't show the "SIMULATE STUDIO PRO CLEARANCE" switch.
  Release behaviour unchanged. `app_security_config_test` + `takt_settings_sheet_test` pass (28).

## 2026-10-05 — Closed Testing submitted to review & Promo Remaster unified Dial scene plan  (status: Play review pending; film revision planned, NOT executed)

- **Google Play Console Closed Testing (v1.0.0, versionCode 1) submitted for review:**
  - 14 changes submitted: attached `zykl-playstore-release.aab` from library, completed declarations for Foreground Service (Special Use + Media Playback with video demo links), Exact Alarm (`USE_EXACT_ALARM`), Data Safety (0 data collected/shared), and Advertising ID (`No`).
  - Status is currently **"Changes in review"** (automated checks passed; under Google Play review).
  - One-time product **`studio_pro_lifetime`** (Rp 69.000, "ZYKL Studio PRO") is verified active in One-time products.
  - Next for release: once Google approves, share opt-in link (`zykl-beta@googlegroups.com`) and run the mandatory 14-day closed test with ≥12 active testers before applying for Production.
  - Device test note: if ongoing countdown notification does not show on Android 13+, check system settings (sideloaded APKs default `POST_NOTIFICATIONS` to off); consider promoting channel importance from `IMPORTANCE_LOW` to `IMPORTANCE_DEFAULT` with `setSound(null, null)` in future update so it doesn't get collapsed into "Silent notifications".

- **Promo Video Motion Remaster: Unified Dial Scene Plan (Agreed with owner; DO NOT EXECUTE YET):**
  - **Context & Feedback:** In the 44s remaster, audio was artificially extended to 44s by duplicating 2 bars (11.97–16.0s), creating an audible repetitive music loop. Moreover, having separate scenes for Analog Preset and Pull Crown caused duplicate static layouts (mockup sitting statically on the right side across two scenes).
  - **Decision:** Merge **Pull the Crown (Custom rhythm calibration)** and **Analog Presets & Cycle (1.0 Hz escapement)** into **ONE single unified Dial scene** (Scene 04 / 4.0 seconds, 12.0s – 16.0s on the 120 BPM grid).
  - **Duration & Music:** Overall video duration returns to **40.0s** (2400 frames @ 60 fps, 10 scenes x 4.0s). Audio returns to the original, seamless **40.0s master mix** (`ZYKL_Promo_Motion_40s_EN_audio_v2.wav` or `mix2.py` with `music_a`), eliminating the music loop repeat completely. If extra audio/SFX is needed, owner provided ElevenLabs API (`11labs.md`).
  - **Choreography (Continuous Take):**
    1. **12.0s – 13.5s (Beat 1: Macro Crown Pull):** Scene starts with device already **zoomed in macro (~1.4x scale)** focused on the top crown button. Crown is pulled and dial wound. As it pulls back to ~0.92x scale, device docks on the **LEFT side**. Text appears on the RIGHT: `UNIT 01 // CROWN CALIBRATION`, `Pull the crown. Set your own rhythm.`, with dynamic counters `40 · 05 · 15`.
    2. **13.5s – 14.2s (Beat 2: Dynamic Glide Across):** On the musical beat, the mockup glides with a smooth 3D tilt across from the **LEFT side to the RIGHT side** with a light sheen across the screen glass. Crown text blurs out.
    3. **14.2s – 16.0s (Beat 3: Analog Presets & Escapement):** Mockup settles on the **RIGHT side**, needle ticks smoothly at 1.0 Hz. Text appears on the **LEFT side**: `UNIT 01 // ANALOG CHRONOMETER`, `Analog hands. A calmer rhythm.`, with rows `ESCAPEMENT 1.0 Hz`, `DEEP FOCUS 25 MIN`, `CYCLE 1/4`.
    4. **Transition to Scene 05 (16.0s):** Because the device ends on the **RIGHT side**, it seamlessly connects into Scene 05 (**Monastic Lockdown**, which is also positioned on the right) with zero position jump cut!
  - **Files involved when executed later:**
    - `zykl.app/promo/Video Motion Remaster/source/anim.js` (re-route S4 timeline & device position interpolation; restore `TOTAL = 40`, `DUR = 36` warped to 40).
    - `audio_remaster_44s.wav` replaced by 40s audio master (`ZYKL_Promo_Motion_40s_EN_audio_v2.wav`).
    - Render pipeline: `render_chunks.sh` with 40s duration (`DUR=40`), 10s chunks, render one variant at a time under nice/cgroup only when owner instructs.

## 2026-10-02 (p) — v1.0.0 built and tagged  (status: owner uploads the AAB to Play Console Internal testing)

- `build_outputs/zykl-playstore-release.aab` (65.4 MB), `zykl-user-testing-universal.apk`, `zykl-developer-pro-universal.apk`.
  versionCode 1 / 1.0.0, targetSdk 36, signed with the upload key (SHA-256 `27:5B:8E:D7…A1:23`), BILLING permission
  present, 16 KB-aligned native libs. The AAB's `libapp.so` is byte-identical to the user-testing APK's (so PRO
  simulation is off); the dev-pro build differs, as expected.
- Git tag `v1.0.0` marks the commit these were built from.
- Copy-paste texts for Play Console (exact alarm, foreground service, Data safety, content rating, the
  `studio_pro_lifetime` product, release steps): `docs/play-console-declarations.md`.
- Next releases: bump `version:` in pubspec.yaml (e.g. 1.0.1+2). The versionCode must increase on every upload.

## 2026-10-02 (o) — Everything committed and pushed  (status: ready to build the v1.0.0 AAB)

- Flutter repo → `github.com/rickyprayasa/TaktDesk` `main`: `387f844` feat(app) v1.0.0 RC, `28e505e` film_capture,
  `e2b3478` docs, `a639ea6` promo, plus the 23 older local commits that had never been pushed. Secret scan clean;
  `11labs.md` and `android/key.properties` are git-ignored. `Claude outputs/` (old preview PNGs) is left untracked on purpose.
- Website repo → `github.com/rickyprayasa/ZYKL` `main`: pricing copy is in `0bf41f7` (final text, no paid packs).
  It is NOT deployed (deploy is manual: `npm run deploy`, wrangler).
- ⚠ **Security:** the website repo's `origin` URL embeds a GitHub personal access token (`https://ghp_…@github.com/…`).
  The owner was advised to revoke it and use a credential helper (the Flutter repo already uses `credential.helper store`).
  Never print or commit it.
- Next: build `aab` + both universal APKs with `scripts/build_test_apks.sh aab user-testing developer-pro` (one at a
  time, capped), tag `v1.0.0` on the built commit, then the owner uploads the AAB to Play Console → Internal testing.

## 2026-10-02 (n) — PRO promise finalised: every future addition is free for PRO owners  (status: DONE, not committed)

Owner decision: **no optional/themed paid packs, ever.** Studio PRO = a single payment for every edition and soundscape,
**including everything added in future updates at no extra cost**. Revenue grows by raising the price for *new* buyers as
the library grows (Rp 69k launch → e.g. 89k → 99k, only a Play Console price change), plus an optional tip jar that
unlocks nothing (not built yet). **Do not add paid content packs.** That would break the public promise.
- App: `studio_pro_dialog.dart` copy ("Every new edition & soundscape in future updates"; body text says "including
  everything added in future updates").
- Website (local, NOT committed/deployed): `src/app/terms/page.tsx` (packs sentence removed, "plus every new soundscape
  and edition we add in future updates, at no extra cost"), `src/data/faq.ts`, `src/components/sections/HonestSpecs.tsx`
  ("all future additions included"). Deploy before the public release.

## 2026-10-02 (m) — RENDERING (started 2026-10-02 afternoon, sequential light_16x9 → dark_9x16 → light_9x16; logs `~/.cache/zykl-film/render_remaster_<variant>.log`; if interrupted, re-run the same command and it resumes) — the 3 remaining remaster videos  (status: Dark 16:9 approved by the owner)

The owner approved `zykl.app/promo/Video Motion Remaster/ZYKL_Promo_Remaster_44s_EN_Dark_16x9.mp4` (13:45) and
**postponed** the other three. Work moved to the AAB/APK release. When the owner asks, render ONE AT A TIME (PC freezes
otherwise; each takes ~30 min):
```
cd "/home/tuneeca/RSQUARE/Android/zykl.app/promo/Video Motion Remaster/source"
./render_chunks.sh light_16x9      # then show the owner, then:
./render_chunks.sh dark_9x16
./render_chunks.sh light_9x16
```
Nothing else needs changing: the same `anim.js` (device-only zooms, single crown push-in, no zoom on Honest
Ownership/editions) and `audio_remaster_44s.wav` are used. Check each output: `ffprobe -count_frames` = 2640 frames,
and the chunk seams at 11/22/33 s. Afterwards (only when asked): 720p/30 fps web cuts + posters for
`zykl.app/public/video/` (names `zykl-promo-{dark,light}[-portrait].mp4/-poster.jpg`, encode as in v3 `composite.sh`),
then commit/deploy the website only on the owner's request.

## 2026-10-02 (l) — FILM DIRECTION CHANGED: remaster of the v3 website film (44 s)  (status: rendering Dark 16:9)

**Owner feedback on v4 (82 s):** too long and boring; there was a sound gap at the noise → opening cut; many SFX did
not fit the picture; they prefer the current website film. **v4 is shelved** (kept in `zykl.app/promo/Video Motion v4/`
for reference; do not continue it). **New brief:** remaster the v3 film exactly (animation, music, SFX unchanged),
replace the phone screen recordings with the crisp Flutter captures, add a **Pull Crown** scene, stay under 60 s.
Zooms (owner, 2026-10-02 after reviewing): **device zoom only.** `growPhone` scales the WHOLE mockup about the feature
point (so the phone stays on its side, clear of copy and overlays). The in-screen zoom (`scrZoom`) is **not used**:
it cropped the UI. Zoom only rhythm, crown, lockdown, dispenser (light) and vinyl. **No zoom on Honest Ownership**
(analytics + badges) or the editions.

**Remaster source:** `zykl.app/promo/Video Motion Remaster/source/` (a copy of `Video Motion 40s EN/source_v3`;
`anim_v3_original.js` = untouched original; `frames` symlinks to `../../Video Motion v4/source/frames`, i.e. the JPG
captures + `manifest.js`).
- `anim.js` changes (search "remaster"): `CAP()` maps v3 clip names to the captures (dark/light via `?theme`). `KN`
  holds per-clip retiming knots (tau since the scene's `setFrame` t0 → clip frame) so the captures hit v3's overlay
  beats: lock pill at 1.15 s, hold bar 2.33–3.97 s, receipt stamp 2.52 s, needle ≈2.4 s. `scrZoom()` / `sceneZooms()`
  do the in-screen zooms. The **crown scene is inserted at 16–20 s** (`crownScene()`: background from the pomodoro
  shot at NT 15.5, its own phone/text/counters, a speed-ramped crown clip via `KN.crown`), and everything after shifts
  +4 s (`render()` wrapper; HUD counts 11 scenes). Always render with `?lang=en&grid=1` (the 40 s grid = the website
  cut).
- Audio: `audio_remaster_44s.wav` = v3 master audio (identical in all v3 masters) with 2 bars (11.97–16.0 s)
  duplicated at 16 s. 30 ms crossfades; the tail is verified identical to the original shifted by +4 s. No new SFX
  (owner: keep sound unchanged).
- Render: `./render_chunks.sh dark_16x9` (11 s chunks, fresh browser each, cgroup 2.5 GB / 1.5 cores, resumable;
  parts in `~/.cache/zykl-film/render_remaster/<variant>/`). Output:
  `zykl.app/promo/Video Motion Remaster/ZYKL_Promo_Remaster_44s_EN_<Variant>.mp4`. **One variant at a time; wait for
  the owner between variants.** Website `public/video/` (720p/30 fps web cuts + posters, see v3 `composite.sh`
  for the encode settings) is updated only when the owner asks.
- **2026-10-02 12:05: `ZYKL_Promo_Remaster_44s_EN_Dark_16x9.mp4` DONE** (2640 frames = 44 s, chunk seams verified). Bug
  fixed: `render.mjs` must read `window.DUR`, because v3's global `const DUR = 36` shadows it and the last chunk had
  stopped at 36 s. Waiting for the owner's review; next variants one at a time on request.
- **2026-10-02 13:33: Dark 16:9 re-rendered with device-only zooms** (2640 frames, seams OK). Waiting for review; the
  other 3 variants have NOT been rendered yet.
- **13:45:** the crown scene had two zooms (looked like a double zoom). It is now ONE continuous push-in (`qZ`), with the
  focus gliding crown → dial (`wD`). Only chunk 11–22 was re-rendered. Dark 16:9 is final pending the owner's OK.

## 2026-10-02 (k) — Film v4 IN PROGRESS: resume here  (status: clips captured, film source built, NOT rendered)

**Owner decisions:** 82 s master is fine (later cut 30 s / 15 s versions for social); **full English**; storyboard
approved (`promo/Video Motion v4 (wip)/STORYBOARD.md`); camera rules in memory `film-camera-style` (calm, zoom only
on key moments, no touch circles).

**Where everything is**
- App clips (PNG 3×): `~/.cache/zykl-film/frames/<clip>/` (`opening|pomo|crown|lock|disp|vinyl|anal`_`dark|light`,
  `edition_{bauhaus,walnut,brass,titanium}`). Capture log: `~/.cache/zykl-film/capture_full.log`.
  Re-capture one clip: `film_capture/run_clips.sh "crown dark"` (add `--smoke` for 1× tests).
- Film source v4: `/home/tuneeca/RSQUARE/Android/zykl.app/promo/Video Motion v4/source/` (promo/ is git-ignored
  in the website repo):
  - `index.html` (EN copy, v3 CSS + counters/flare). Edit `v4_scenes.js`, then run `python3 build_anim.py`. This
    regenerates `anim.js` from v3 intro pieces + v4 scenes. **Never edit anim.js by hand.**
  - `prep_frames.py`: PNG → `frames/<clip>/NNNN.jpg` + `frames/manifest.js` (FR = frame counts, EV = touch spans
    used for zoom timing, crown counters and SFX). Incremental; run after captures.
  - `render.mjs W H "?theme=light" OUT.mp4` = full film at 60 fps; `render.mjs W H "" OUTDIR 12.5 30 …` = stills.
    Needs `NODE_PATH=~/.cache/zykl-render/node_modules`. Wrap every render in
    `systemd-run --user --scope -p MemoryMax=3000M -p CPUQuota=150% nice -n 19 …`, and **never run it alongside a
    capture** (RAM).
  - `mix_v4.py [score_v1|score_v2] OUT.wav`: score + SFX + app foley cued from EV, hard silence at 4.96 s, music duck
    under the lockdown hold, normalised to −14.5 LUFS. score_v1 is chosen (better dynamic arc); the owner can compare.
- Audio sources: `Takt Desk/promo/Video Motion v4 (wip)/audio/{music,sfx}` (ElevenLabs, key in `11labs.md`),
  app foley `assets/audio/foley_*.wav`, older SFX `zykl.app/promo/scripts/zykl_promo_audio_v2/`.

**Verified so far:** stills at 2.5/7/11/16.5/21.5/26/28/31/36 s look right (boot, rhythm zoom, crown counters
25→40 / 5→8 / 15→20 synced to the dial). The crown dial zoom keeps the phone on the right (`fx: 134`) so the copy and
counters stay readable. Mix test passes (−59 dB silence at 5.0–5.3 s).

**Progress 2026-10-02 09:05:** all 18 clips captured and prepped (frames 607 MB). Stills for every scene verified
in dark, light and 9:16. The final mix is written (`source/mix_v4.wav`, 88 cues, score_v1). **`source/render_all.sh` is
rendering the 4 masters sequentially** (log `~/.cache/zykl-film/render_all.log`, ~28 min each at ~2.9 fps; temp
video in `~/.cache/zykl-film/render/`, final muxed files in `zykl.app/promo/Video Motion v4/ZYKL_Film_v4_*.mp4`).
If interrupted: `./render_all.sh light_16x9 dark_9x16 …` re-renders only the given variants. Steps 1–3 below are
done; continue at step 4.

**2026-10-02 09:45: the PC froze again during the first full render** (at frame ~3900 the browser's memory had
grown until the system thrashed). Rendering is now **chunked**: `source/render_chunks.sh <variant>` renders 10 s chunks,
each in a fresh browser (cgroup 2.5 GB / 1.5 cores), marks them `part_XXX.mp4.done` in
`~/.cache/zykl-film/render/<variant>/`, joins them with ffmpeg concat (`-c copy`) and muxes `mix_v4.wav` into
`zykl.app/promo/Video Motion v4/ZYKL_Film_v4_<Variant>.mp4`. **Re-running resumes.** The owner wants ONE master at a
time: render `dark_16x9` first, show it, and start the next variant only when the owner says so.
(`render_all.sh` is obsolete; do not use it.)
**2026-10-02 10:35: `ZYKL_Film_v4_Dark_16x9.mp4` is DONE** (4920 frames, 82 s, seams at 10 s / 30 s verified
identical). It is waiting for the owner's review (pacing, camera, audio balance, score_v1 vs score_v2, which needs
only a re-mix plus re-mux). **Do not render light_16x9 / dark_9x16 / light_9x16 until the owner says so; one at a time.**

**Remaining (in order):**
1. Wait for the capture to finish, then `python3 prep_frames.py`.
2. Stills for scenes 7–13 (e.g. 39, 42.5, 45, 49, 51, 56, 59.5, 63, 68.5, 70, 75, 79.5), dark AND light AND portrait
   (1080×1920). Fix framing (zoom targets u/v in `v4_scenes.js`: lock hold point, disp `tear[3]`, vinyl
   needle `.6/.46`, analytics panel `.5/.34`).
3. `python3 mix_v4.py score_v1 mix_v4.wav`.
4. Render 4 masters ONE AT A TIME (~25–40 min each): 1920×1080 `""` and `"?theme=light"`; 1080×1920 the same.
   Mux: `ffmpeg -i video.mp4 -i mix_v4.wav -c:v copy -c:a aac -b:a 256k -shortest out.mp4`. Output names:
   `zykl.app/promo/Video Motion v4/ZYKL_Film_v4_{Dark,Light}_{16x9,9x16}.mp4`.
5. Show the owner. Later: 30 s / 15 s cutdowns; website `public/video/` update only when asked (outward-facing).

## 2026-10-02 (j) — Film v4: all app clips scripted + ElevenLabs audio  (status: 3× capture running, film not built)

- Owner direction (memory `film-camera-style`): calm camera, zoom only on key moments, **no touch circles**,
  duration free (~82 s), "cinematic masterpiece". Storyboard: `promo/Video Motion v4 (wip)/STORYBOARD.md`
  (13 scenes). **Awaiting owner OK before generating the score.**
- `film_capture/film_scene.dart` = shared stage: real `DeskCanvasScreen`/opening under a fake clock, fake
  FocusLockService (no DND off-device), silent sensor channels (EventChannels + `sensors/method`), in-memory DB,
  `seed` hook, teardown that disposes providers and flushes timers (otherwise "Timer still pending").
- `film_capture/clips_test.dart` = 18 clips (opening/pomo/crown/lock/disp/vinyl/anal × dark/light + 4 editions),
  each asserting its steps. Gotchas fixed: `FocusAnalyticsDialog.show()` must not be awaited (completes on close);
  the record drawer uses local state (tap `vinyl_drawer_1_handle`, `02 · HARMONICS`, `load_track_button_<index>`);
  the analytics seed must not create a preferences row (it would force dark mode).
- `film_capture/run_clips.sh [--smoke] [clips…]`: one clip at a time in a 4 GB cgroup. Smoke = 1× into
  `~/.cache/zykl-film/smoke`; full = 3× into `~/.cache/zykl-film/frames` (log: `capture_full.log`).
- **ElevenLabs**: key in `11labs.md` at the repo root (now git-ignored, chmod 600; never print it). Generator:
  `promo/Video Motion v4 (wip)/audio/generate_audio.py sfx|music [N]`. The score is a composition plan with 13
  sections = storyboard scenes (82 s, music_v1, respect_sections_durations). The 14 cinematic SFX are generated
  (`audio/sfx/`). UI sounds = the app's own foley (`assets/audio/foley_*.wav`). Account: Starter, ~37k credits
  on 2026-10-02 (music ~900/min, SFX ~200 each).
- Security cleanup: removed a hardcoded (different, old) ElevenLabs key from the git-ignored
  `zykl.app/promo/scripts/generate_elevenlabs_sfx.py`. It was never committed.
- Next: owner approves the storyboard → `generate_audio.py music 2` → build `source_v4` (fork of
  zykl.app/promo/Video Motion 40s EN/source_v3: scene timeline per storyboard, phones load the new 3× clips,
  eased zoom keyframes per scene, crown counters) → render 4 masters one at a time, memory-capped → mix.

## 2026-10-02 (i) — Promo film v4: app footage rendered from the real widgets (no screen recording)  (status: PoC clip done)

- Owner wants the 40 s film remade with the current UI, including the new **crown-pull custom cycle**, and without
  screen recording (so auto-zoom stays sharp).
- **`film_capture/`** (outside `test/`, so the normal suite ignores it):
  - `capture_kit.dart`: loads real fonts (`monospace` = Noto Sans Mono, the Android system mono family; Roboto;
    MaterialIcons) instead of the test Ahem boxes; phone view 384×800 logical @3× = **1152×2400 PNG** frames;
    `FilmFinger` drives real pointer events frame by frame; `FilmRecorder` writes `NNNN.png` + `touches.json`
    (normalised finger position per frame, for auto-zoom).
  - `crown_clip_test.dart`: a scripted clip on the real `DeskCanvasScreen` under a fake clock (`withClock`,
    1 frame = 1/30 s): standby → pull crown → wind 40 → 8 → 20 → seat → press crown → countdown. It **asserts every
    stage** (a crown drag must exceed ~18 px slop + 8 px, so use ~48 px). `FILM_OUT` and `FILM_DARK` dart-defines.
  - `make_zoom_preview.py`: 4:5 preview with a camera that follows the finger.
- Run (≈1 frame/s, 360 frames ≈ 3 min), always memory-capped:
  `systemd-run --user --scope -p MemoryMax=4000M -p MemorySwapMax=512M -p CPUQuota=200% nice -n 19 flutter test film_capture/crown_clip_test.dart --dart-define=FILM_OUT=/tmp/zykl_film/crown`
- Output: `promo/Video Motion v4 (wip)/ZYKL_clip_crown_custom_preview_4x5.mp4` (promo/ is tracked in this repo; keep large renders out of commits).
- Film pipeline to reuse: `/home/tuneeca/RSQUARE/Android/zykl.app/promo/Video Motion 40s EN/source_v3`
  (`index.html` + `anim.js` + `render.mjs`, Playwright, 60 fps). Phones load `frames/<clip>/NNNN.jpg` at 30 fps,
  with clip lengths in `FR`. Clips needed: lock, pomo, disp, vinyl, anal (+L light variants), bauhaus, walnut,
  brass, titanium. Next: write the remaining clip scripts, add a crown scene to the storyboard, re-render the
  4 masters (dark/light × 16:9/9:16), one at a time, memory-capped.

## 2026-10-01 (h) — Console: fixed-width cycle track + quick sheets  (status: DONE in code, NOT built: owner reviews on Linux)

Owner decision: keep the Pomodoro Interval Engine in Settings (do not merge the steppers into the dial console:
it would shrink the dial), but make it reachable from the desk.
- **CYCLE capsule shrank with 5–8 cycles** (`chrono_profile_selector_widget.dart`): the capsule is inside a
  `FittedBox(scaleDown)` and drew one dot per cycle, so 8 cycles scaled the whole capsule, text included. New
  `_CycleTrack` is always 30 px wide: ≤ 4 cycles = round lamps (unchanged look), 5–8 = a segmented battery-style bar.
  Verified with a throwaway golden render: capsule width identical for 4 and 8.
- **Long-press CUSTOM** on the console now opens `showIntervalEngineSheet(context)` (before, it duplicated "tap
  active CUSTOM" = crown calibration). Calibration is still on tap-when-active and crown pull. Allowed while running
  (the steppers lock themselves).
- **Tap the TODAY tally** (right column of the desk plate, key `desk_spec_plate_goal`) opens
  `showDailyGoalSheet(context)`. The rest of the plate still opens the telemetry log. Note: the tally column is
  ~half the plate width.
- Sheets live in `lib/features/settings/presentation/settings_sections/quick_sheets.dart` (a part of the settings
  library) and reuse `_PomodoroIntervalEngineSection` and the new top-level `_stepperRow(...)` (was the instance
  method `_buildStepperRow`; it now takes `isDark`).
- Tests: the long-press test now expects the sheet; plate taps use the left side; new "TODAY tally opens the daily
  goal sheet" test. timer, desk and settings suites: 207 pass. analyze 0 issues.

## 2026-10-01 (g) — Focus Analytics: correct data + daily goal + streak  (status: DONE, universal APKs rebuilt, NOT committed)

**Bugs fixed (numbers were wrong):**
- **Double counting under Monastic Lockdown**: the timer recorded the cycle AND `FocusLockController.completeUnlock`
  recorded the lock duration as another "completed" session (25 min with lockdown showed 2 sessions / ~50 min).
  Now the lock records only when no timer ran during the lock (`noteTimerActivity()` from the chronometer on start
  and finish, plus the `isTimerRunning` probe wired in `chronoDialProvider`), only if ≥ 60 s, and flagged
  `isLockdownOnly = true`.
- **Completion rate was always 100%**: abandoned sessions were never stored. `ChronoDialController._discardSession()`
  (reset, profile/phase/target change, calibration) records a focus session abandoned after ≥ 60 s of focus as
  `isFinished = false` with the real focused seconds.
- **Daily average** divided by 7 / days-in-month even for the period in progress → now `_elapsedDays` (future period = 0).
- **Month chart**: 5 × 7-day buckets left an always-empty "W5" → 4 near-equal day ranges labelled `1–8`, `9–16`, …
- **Sessions lost when the app was closed**: `TimerForegroundService.onTimerFinished` stores finished focus sessions
  in SharedPreferences `zykl_pending_sessions` when `MainActivity.activeInstance == null` (Dart is dead).
  Flutter imports them via channel method `takePendingSessions` (`ChronoDialController.importPendingNativeSessions`,
  called in `DeskCanvasScreen.initState` and on resume). The completion PendingIntent now also carries the target minutes.
- Day view "BEST FOCUS" repeated the total → now the peak 4-hour bin (`08h · 50m`).

**Single rule set**: `lib/features/analytics/domain/focus_session_rules.dart`. `isCompletedCycle` = timer session and
finished. Minutes include lockdown-only. Completion rate = finished / timer sessions. Used by analytics, the desk
"TODAY" plate (`todayFocusStatsProvider`) and lifetime stats. **Use it for any new statistic.**

**DB schema v8** (migration `from < 8`): `timer_sessions.is_lockdown_only` (bool, default false) and
`desk_preferences.daily_goal_cycles` (int, default 4). Regenerated `app_database.g.dart` with build_runner.
Old rows stay as they were (old double counts can't be separated reliably).

**Features:**
- **Daily goal** (1–12, default 4): `DeskPreferencesController.setDailyGoalCycles`, a stepper "DAILY GOAL" in Settings →
  Pomodoro Interval Engine (editable while running). Desk plate: `TODAY: x / goal CYCLES`; the 4 LEDs are quarters of
  the goal (all lit when met, no longer modulo 4).
- **Focus streak**: `FocusStreak.compute` counts consecutive days with ≥ 1 completed cycle. The current streak survives
  until today ends; also tracks the best streak; DST-safe. Shown as `· 5D STREAK` on the plate and in a new
  `_GoalStreakPanel` in the analytics dialog (goal meter + streak + best).

**Tests**: new `test/features/analytics/focus_session_rules_test.dart` (8), `test/core/focus_lock_no_double_count_test.dart` (6),
plus plate goal/streak and goal clamp tests. Updated: month buckets, "4 CYCLES" ambiguity, `TimerSession(isLockdownOnly:)`
in the desk tests. Full suite `flutter test -j 1`: **447 pass**. Kotlin release compiles.

**Backlog (analytics, not done):** tasks stamped DONE per period, "most productive hours", CSV export (local),
tap a bar for detail, refresh the dialog at midnight.

## 2026-10-01 (f) — Cinematic opening + seated crown  (status: DONE, universal APKs rebuilt, NOT committed)

- Owner feedback after the device test: alarm preview audio is now instant (entry 1 confirmed working). Two more
  requests: the opening was too fast, and the crown looked like it was floating in light mode.
- **Opening** `takt_opening_screen.dart`: 1.8 s → 4.2 s (`_totalMs`, `_seatMs = 2900`). Same choreography with more
  breathing room, a 200 ms hold on the full lockup, and the hand-off to the desk now runs 900 ms (`easeInOutCubic`,
  scale 1.06 → 1). Tap-to-skip and the reduced-motion static lockup are unchanged. The prefs safety timeout stays 3 s.
  Timeline is documented in the class doc comment. Test updated (not navigated at 2 s, navigated after 4.2 + 0.9 s).
- **Crown** `crown_push_button.dart` + `chrono_dial_widget.dart`: it actually hovered. The crown box ended at y=28 but the
  bezel edge is at y=24+8=32 (painter `outerRadius = size/2 - 8`). Crown is now `Positioned(top: 6)` (collar seated
  2 px into the bezel), with a darker gradient collar, a radial contact shadow (`crown_socket_shadow`), dark knurl
  grooves and a slightly stronger shadow on light finishes (`isLightFinish` = first gradient colour luminance > 0.4).
  Crown box (36×28) and cap positions (12/16/4) are unchanged, so crown tests stay valid; the dial test now expects top 6.
  Verified visually with a throwaway golden render in light and dark.
- Verified: analyze 0 issues; timer and opening tests pass.

## 2026-10-01 (e) — Google Play Billing for Studio PRO + Gradle memory fix  (status: CODE DONE, NOT built, NOT committed)

**Business decision (owner, 2026-10-01; REVISED 2026-10-02, see entry (n): no paid packs, all future content free for PRO):** keep a one-time PRO, no "PRO Plus" or subscription. PRO = every core
edition and soundscape, including future core additions. Optional themed packs and a tip jar may come later as
separate one-time products. Launch price Rp 69.000, which may rise later (to Rp 89–99k) by changing the price in Play Console only.

- **Gradle froze the PC**: `android/gradle.properties` had `-Xmx8G` on a 7.6 GB machine. Now `-Xmx3g`,
  `workers.max=2`, `kotlin.daemon.jvmargs=-Xmx1g`. Still run with `nice -n 19 ./gradlew --no-daemon` and kill `java` afterwards.
- **Security bug fixed**: in release builds the PRO dialog's "UNLOCK NOW (SIMULATED)" button unlocked PRO for free
  until restart. Simulation is now only reachable when `AppSecurityConfig.isProSimulationEnabled`.
- **Billing**: `in_app_purchase` (Play Billing Library 8.0.0, auto-adds `com.android.vending.BILLING`; verified in the
  merged manifest).
  - `lib/core/billing/pro_store.dart`: `kStudioProProductId = 'studio_pro_lifetime'` (**must match Play Console; IDs
    can never be reused**), plus a `ProStore` seam and the `PlayProStore` implementation.
  - `lib/core/billing/pro_purchase_controller.dart`: `proPurchaseProvider`. States: unavailable / idle / purchasing /
    pending / owned. At launch it calls `restorePurchases()`; `purchased`/`restored` → `setProSimulated(true)` (after
    `prefs.ready`). Every purchase is acknowledged via `completePurchase`, otherwise Google auto-refunds after 3 days.
    Ownership is never trusted from the DB: release builds start locked each launch. Refunds simply stop restoring.
    Pending (Indomaret/Alfamart cash) is shown in the dialog and unlocks later via the stream.
  - Started eagerly in `DeskCanvasScreen.initState` (`ref.read(proPurchaseProvider)`). No-op in simulation/debug
    builds (`proStoreProvider` returns null), so tests and dev-pro APKs never touch Play.
  - Legacy name: `DeskPreferencesState.isProSimulated` now means "PRO unlocked" (simulated or purchased).
- **PRO dialog** (`studio_pro_dialog.dart`): real BUY (`UNLOCK · <Play price>`), RESTORE, pending/error messages.
  Removed the fake "47% OFF / Rp 129.000 / $9.99" (misleading-pricing policy risk). Benefits now accurate:
  8 more editions, 12 more soundscapes, future core additions. Widgets and focus lock are free, so they are no longer
  listed as PRO.
- **Website** (`/home/tuneeca/RSQUARE/Android/zykl.app`, edited locally, NOT committed/deployed): Terms, FAQ and
  HonestSpecs now say launch price + future core additions included + optional packs possible.
- Tests: `test/core/billing/pro_purchase_controller_test.dart` (7 cases); the dialog test now asserts there is no fake discount.
  Verified: analyze 0 issues; billing, settings, desk, opening, smoke tests pass; Kotlin compiles.

**Owner's Play Console steps (in order):** 1) Payments profile (category "Computer Software", support
support@zykl.app, statement name "ZYKL RSQUARE"). 2) Upload an AAB that contains this billing code to Internal testing.
3) Monetize with Play → One-time products → create `studio_pro_lifetime`, Rp 69.000, Activate. 4) Setup → License
testing → add tester emails. 5) Test buy / reinstall / restore on a device installed via the Internal testing link
(sideloaded APKs cannot buy).

## 2026-10-01 (d) — Reduce motion, contrast (WCAG AA), settings sheet split  (status: DONE, NOT built, NOT committed)

- **Reduce motion** (Android "Remove animations" → `MediaQuery.disableAnimations`):
  - `vinyl_player_widget.dart`: platter does not spin and the per-frame ticker never runs (`_syncPlatter`).
    Tonearm/strobe still show the playing state. Test: "platter stays still when the system removes animations".
  - `desk_canvas_screen.dart`: parallax sensors run only if `parallaxEnabled && !_reduceMotion` (`_syncSensors`).
    `parallaxProvider.reset()` is now deferred by a microtask because it can run in `didChangeDependencies`.
  - The opening screen already handled reduced motion (static lockup).
- **Contrast audit** (`test/app/theme/contrast_test.dart` now enforces 4.5:1 on all 12 editions × light/dark):
  - Primary chassis text was already fine (8.8–15.8:1).
  - Light-mode muted text `chassisMutedTextColor` went from 60% to 75% alpha (`0xBF1B1E23`): 3.5:1 → ≥4.99:1.
  - Amber used as TEXT on light panels was 1.0–2.3:1. New `TaktColors.amberInk` (#7A4A12) and
    `TaktColors.amberText(isDark)` (filament on dark, ink on light). Applied to 27 `TextStyle`s in the settings
    sheet, studio PRO dialog, feedback dialog, analytics dialog + bar chart and the vinyl disc drawer.
    Decorative amber (LEDs, borders, fills, icons) was intentionally left alone. **Use `amberText(isDark)` for any new
    amber text.** Always-dark displays (flip digits, VU meter) keep `filamentAmber`.
  - ⚠ Visual review on emulator (light mode): amber labels such as EQUIPPED, PRO, section titles, analytics totals
    are now dark amber/brown. If any of them sits on a dark inset in light mode, switch that one back to `filamentAmber`.
- **Settings sheet split** (pure move, no logic change, verified token-identical): `takt_settings_sheet.dart`
  2676 → 1404 lines. New `part` files in `lib/features/settings/presentation/settings_sections/`:
  `alarm_acoustics_section.dart`, `pomodoro_interval_section.dart`, `hardware_editions_section.dart`,
  `section_header.dart`. They are `part of` the sheet, so private names stay shared and imports live only in the
  main file. The card builders (`_build…Card`) remain in the State class (moving them would require extensions plus
  protected `setState`).
- Verified: analyze 0 issues; every test folder run with `-j 1` (app, core, features/*, smoke, tool): all pass.

## 2026-10-01 (c) — Notification permission + resume re-sync  (status: DONE, NOT built, NOT committed)

- **Bug: Android 13+ never asked for `POST_NOTIFICATIONS`** (targetSdk 35). The countdown notification, the
  "session done" alert and the vinyl media notification were silently blocked. Fix in `MainActivity.kt`:
  `requestNotificationPermissionOnce()` runs on the first `startService` (in context, not at launch), once per
  install (SharedPreferences `zykl_permissions/post_notifications_asked`). On grant mid-session,
  `TimerForegroundService.ACTION_REFRESH_NOTIFICATION` re-posts the ongoing notification. If the user denies,
  we don't ask again; they can enable it in system settings. The alarm sound still plays either way.
- **Resume re-sync (closes the "clock moved forward" gap)**:
  - Native: `TimerForegroundService.deadlineElapsed` / `isCountingDown` (companion, boot-clock). The deadline is
    kept after completion and cleared on stop. New `com.takt.desk/timer_service` method `getRemainingMillis` →
    `{remainingMillis, running}` or null (negative = finished).
  - Dart: `TimerBackgroundService.status()` → `NativeTimerStatus?`; `ChronoDialController.resyncWithNative()`
    catches up if Dart is behind, gives time back if Dart over-counted (forward jump), and if native already
    finished it advances the phase with `tick(..., ringAlarm: false)` (native already rang, so no double chime).
    Drift < 1 s is ignored. Triggered by an `AppLifecycleListener(onResume)` in `desk_canvas_screen.dart`.
  - Tests: `test/features/timer/chrono_dial_resync_test.dart` (4 cases).
- Verified: analyze 0 issues; `flutter test -j 1 test/features/timer test/features/desk` 152 pass; Kotlin compiles.
- To check on emulator (API 33+): first START → permission dialog appears; allow → countdown notification shows.
  Start 2 min, background the app, change the system time +10 min, reopen → time shown must still be about 2 min.

## 2026-10-01 (b) — "Other bugs & risks" pass  (status: DONE, NOT built, NOT committed)

- **Clock robustness (Dart)** `chrono_dial_controller.dart`: `_elapsedSeconds()` clamps negative wall-clock
  deltas to 0, so setting the clock back (manual or NTP) never adds time. Wall-clock is kept on purpose: Dart's
  `Stopwatch` uses CLOCK_MONOTONIC, which stops in Android deep sleep, so it could not catch up after suspension.
  A forward clock jump still shortens the session (can't be told apart from suspension in Dart). The native
  alarm below covers this case. Test: `test/features/timer/chrono_dial_clock_test.dart`.
- **Clock robustness (native)** `TimerForegroundService.scheduleExactCompletion()` now triggers on
  `ELAPSED_REALTIME_WAKEUP` (boot-time clock: immune to clock changes, counts through deep sleep). `endAt` (epoch)
  is still the session identity and drives widgets/notification chronometer.
- **Silent DB errors**: `recordTimerSession` and task writes in `receipt_runner_controller.dart` now
  `debugPrint` failures (`_logDbError`) instead of swallowing them. No retry; UI behaviour unchanged.
- **Foreground service type**: kept `specialUse`, which is the correct type for a user-started countdown
  (`shortService` = 3 min max, `mediaPlayback` would be a false declaration). Rewrote
  `PROPERTY_SPECIAL_USE_FGS_SUBTYPE` in the manifest as a clear justification for Play review. Paste the same text
  in Play Console → App content → Foreground service permissions.
- **Removed unused `rive`** dependency and the empty `assets/rive/` folder (no `package:rive` import anywhere).
  `pubspec.lock` updated via `flutter pub get`.
- Verified: `flutter analyze` 0 issues; `flutter test -j 1 test/features/timer test/features/tasks` pass (120);
  Kotlin compiles. The full suite was not re-run, to save the user's CPU.
- ⚠ Resource note: machine is 4 cores / 7.6 GB. Use `flutter test -j 1 <dir>` and `./gradlew --no-daemon`;
  kill leftover `java` daemons afterwards. Don't `pkill -f kotlin-daemon` from the same shell: the pattern matches
  the shell itself.

## 2026-10-01 — Audio alarm fix, exact alarm, audio compression, a11y  (status: DONE, NOT built, NOT committed)

### 1. Alarm-chime audition needed many taps  → fixed (native side was never done before)
- Root cause: Dart `previewAlarmChime()` already sent `preview:true`, but `MainActivity.kt` ignored it and ran
  every tap through `shouldPlayAlarm()` (3.5 s global de-dup shared with the real alarm), dropping taps.
- Fix: new `EffectSoundPlayer.kt` (SoundPool, USAGE_MEDIA). Samples are decoded once at engine start; a tap
  plays instantly, replaces the previous preview, honours `volume`, and a tap before the sample finished loading
  is queued and fired from the load callback. Foley (`playFoley`) uses the same pool (overlapping).
- `playAlarmChime` in `MainActivity.kt`: `preview == true` → SoundPool path, **skips** `shouldPlayAlarm()`.
  Real alarm path unchanged (MediaPlayer, USAGE_ALARM, 3.5 s de-dup vs `TimerForegroundService`).
- Asset→file maps now live in `MainActivity` companion (`FOLEY_ASSETS`, `ALARM_ASSETS`). Add new chimes there
  AND in `lib/features/timer/domain/alarm_chime.dart` AND `TimerForegroundService.getAlarmAssetPath`.
- Tests: `alarm_acoustics_settings_test.dart` now expects `previewedChimes` on tile tap (was stale).

### 2. End-of-session alarm now exact (works with screen off / Doze)
- Before: `Handler.postDelayed` (uptime clock, stalls while CPU sleeps) + only a 3.5 s wake lock at the end.
- Now: `TimerForegroundService.scheduleExactCompletion()` → `AlarmManager.setExactAndAllowWhileIdle(RTC_WAKEUP)`
  with a `PendingIntent.getService` (`ACTION_COMPLETE`, extras: end epoch, phase, chime id). Falls back to
  `setAndAllowWhileIdle` if exact alarms are denied (API 31–32 without grant). Handler stays as same-process fallback.
- `onTimerFinished(phase, endAt)` is idempotent via `lastCompletedEndAt`. Alarm cancelled in start/stop/finish
  (NOT in `onDestroy`, so it survives an unexpected service kill).
- Manifest: `SCHEDULE_EXACT_ALARM` (maxSdk 32) + `USE_EXACT_ALARM` (API 33+, timer/alarm app category).
  ⚠ Play Console: declare exact-alarm use (core function: timer) in App content → expect review questions.
- Removed unused `HIGH_SAMPLING_RATE_SENSORS` (parallax uses `SensorInterval.uiInterval`, paused on lifecycle).
- NOT verified on a real device/emulator: set a 1-min focus, lock screen, confirm bell fires on time.

### 3. Audio compression (37 MB → 5.7 MB)
- `assets/audio/vinyl_*.wav` (20 loops, 22.05 kHz mono, 40 s) → `vinyl_*.ogg` (Vorbis q4, ffmpeg). Alarm + foley
  stay WAV (tiny, latency-critical). Unused `binaural_alpha_432.wav` and `vinyl_surface_crackle.wav` were moved out.
- Lossless originals: `assets_src/audio_wav/` (NOT bundled; not in pubspec assets). Regenerate OGG with:
  `ffmpeg -i X.wav -c:a libvorbis -q:a 4 X.ogg`. The python generators in `scripts/` still write `.wav` into
  `assets/audio/` — re-encode after running them.
- Updated paths in `vinyl_track.dart`, `MainActivity.kt`, `MediaNotificationService.kt`, `vinyl_audio_assets_test.dart`.
- ⚠ To verify by ear on emulator: loops (MediaPlayer `isLooping`) must be gapless at the 40 s seam. If a click/gap
  is audible, try `-c:a libopus -b:a 96k` or encode with a longer crossfade; fall back to WAV only for that track.

### 4. Accessibility
- `Semantics` added: dial (label "Focus timer, M minutes S seconds remaining, running/paused", tap toggles),
  crown button, theme switch, settings rivet tooltip. Test: `chrono_dial_widget_test.dart` ("exposes the countdown").
- Painters already had RepaintBoundary / cached texture (earlier agent); nothing more done there.

### Backlog (not done, ordered by value)
1. Verify items above on emulator/device (gapless OGG loops, exact alarm with screen off, preview instant tap).
2. ~~FGS type~~ (kept specialUse + justification, see entry b). ~~Clock robustness~~ (entry b).
3. ~~Resume re-sync~~ done (entry c). ~~POST_NOTIFICATIONS~~ done (entry c).
4. ~~Swallowed DB errors~~ now logged (entry b); add retry/user-visible error if it shows up in practice.
5. ~~rive~~ removed (entry b).
6. ~~Settings split, contrast, reduce motion~~ done (entry d). Possible follow-up: move the `_build…Card` methods into widgets.
7. ~~Play Billing~~ code done (entry e). Remaining: owner's Play Console steps, real-device purchase test, website deploy.
8. Replace default `README.md`; commit work by topic; upgrade deps after release (`sqlite3_flutter_libs` is EOL).
9. Note: during this session `chrono_dial_widget.dart` was modified by something other than the agent
   (likely IDE format-on-save); re-run `flutter analyze` after pulling external edits.
