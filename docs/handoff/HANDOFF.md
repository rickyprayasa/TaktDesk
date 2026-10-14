# ZYKL Flutter app — Agent Handoff Log

> Read this first when taking over. Newest entry on top. Any AI agent (Claude, Codex, Gemini, ...) should
> append an entry here after finishing work, keeping the same structure. Product context: `docs/zykl-summary/`.

## Project facts (stable)
- App: **ZYKL: Pomodoro Focus Timer**, Flutter, package `com.zykl.app`, folder name `Takt Desk` is legacy
  (Dart package `takt_desk`, MethodChannels `com.takt.desk/*` — do not rename casually).
- Website repo (separate): `/home/tuneeca/RSQUARE/Android/zykl.app` (Next.js on Cloudflare Worker).
- Native Android code: `android/app/src/main/kotlin/com/zykl/app/` (MainActivity = audio/focus/widget channels,
  TimerForegroundService = background countdown + completion, MediaNotificationService = vinyl notification).
- Verify with: `flutter analyze` → 0 issues; `flutter test -j 1` → all pass (544 at last full run);
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

## 2026-10-14 — Reverse-engineering hardening for 1.0.7  (status: committed `892a9e5`, `9d19568`; billing tests 20 green, Kotlin compiles; NOT built; version still 1.0.6+7)

Owner asked how safe ZYKL is from reverse engineering. Baseline was already sound: no secrets or API keys in the app,
Kotlin minified by R8, release builds ignore the stored PRO flag and ask Play on every launch (refunds lose PRO).
Play Console → Protected with Play → **Automatic protection is on** (1 of 1); Play Integrity API not used (needs a server).
- `892a9e5` purchases unlock PRO only when Google Play's signature checks out (`PlayPurchaseVerifier.kt`, channel
  `com.zykl.app/billing`, Licensing public key from Play Console, RSA 2048) and the signed JSON is `com.zykl.app` /
  `studio_pro_lifetime`. A failed check is still acknowledged (no refund of a real purchase), unlocks nothing, and
  says "Google Play could not confirm this purchase…". Algorithm verified with a JDK harness.
- `9d19568` `scripts/build_test_apks.sh` builds with `--obfuscate --split-debug-info=build_outputs/symbols/<version>-<target>`.
  Keep those folders: they are the only way to read Dart crash stack traces (`flutter symbolize`).
- **Device check before 1.0.7 ships**: the first obfuscated build must be tested end to end (dev APK), and on a Play
  build (internal testing / license tester) PRO must still restore after reinstall. If a real buyer reports "could not
  confirm", check the Licensing key in `PlayPurchaseVerifier.kt` first.
- Accepted risks: soundscape OGGs can be unzipped from the APK (some are public previews on the website anyway); a
  determined attacker can still patch the binary.

## 2026-10-13 (f) — v1.0.6 (versionCode 7) AAB built; website pushed  (status: built + tagged `v1.0.6`; owner uploads to Play; website `4901da5` live)

Owner approved the 1.0.6 dev APK. Built 11:06 with the standard 4.5 GB cap (3.6 GB free, Chrome open):
`build_outputs/zykl-playstore-release.aab` (66.1 MB), `com.zykl.app`, 1.0.6 / vc 7, jarsigner verified, upload key
`27:5B:8E:D7…` (CN=RSQUARE, OU=ZYKL), backup rules in the manifest, native debug symbols in BUNDLE-METADATA. The 1.0.5
AAB is archived in `build_outputs/previous/2026-10-12-v1.0.5/`. Includes (c), (d) and (e): first release with the
P1 chime fix. Schema 11 → 13 migrates on first launch.

Website `4901da5` pushed to production and verified live (Terms, Privacy dated 13 Oct; FAQ_05; specs rows).

Release notes (en-US):
> Focus analytics now has a YEAR view, with a day-by-day heatmap in Studio PRO, and TOP SLIPS shows which tasks took
> your time. Night owl? Let the day start as late as 6 am, and start weeks on Sunday. Exports now name the task of each
> session. Plus fixes: the finish chime plays to the end, music resumes after a call and pauses when headphones are
> unplugged, and a Studio PRO edition is kept after a restart.

## 2026-10-13 (e) — Play rating prompt, TOP SLIPS, website copy  (status: app committed `bbbcb41`, `b917fcb`, version 1.0.6+7 `7964859`, tests 544 green; dev-pro APK built 10:37 (67.2 MB); website `4901da5` pushed in (f); AAB in (f))

- `bbbcb41` **Play In-App Review** (`in_app_review` 2.0.12 → Play `review` 2.0.2 + `play-services-base`): requested once per
  install, 3 s after a focus phase runs to its end, once 10 cycles are done (`completedCycleCount()`), app on screen and
  not in lockdown (`lib/core/review/review_prompter.dart`, `reviewPromptSyncProvider` watched by the desk,
  `ChronoDialController.focusCompleted`). **Schema v13**: `desk_preferences.reviewAskedAt`. Sideloaded dev APKs: Play
  usually shows nothing (only Play-installed builds get the sheet; internal app sharing / internal testing to test).
- `b917fcb` **TOP SLIPS** in Focus Analytics (every period): top 3 slips by focus time with their share of the period;
  sessions of deleted slips pooled as "DELETED SLIPS"; titles reload when the dialog opens. `_periodRange()` now shared
  by day/week bounds and TOP SLIPS.
- Website (`zykl.app` `4901da5`, pushed and live, see (f)): Terms + FAQ say focus analytics is free and Studio
  PRO adds the year heatmap; new FAQ_05 (analytics); Privacy: the one-time rating card, backup exclusions, export;
  HonestSpecs rows Analytics + Your history; changelog highlights; Terms/Privacy dated 13 Oct 2026. `next build` OK.
- Build note: Flutter warns that `in_app_review` 2.0.12 applies the Kotlin Gradle Plugin; a future Flutter may refuse
  to build until the plugin moves to Built-in Kotlin (check its changelog before upgrading Flutter).
- About page "NO STREAKS, NO BADGES" → "NO BADGES, NO LEADERBOARDS" (owner, website `1eb373c`, live): the app shows a FOCUS STREAK.
  FAQ "download under 20 MB": re-check the Play download size after the 1.0.6 AAB (Play services base added).
  Play Console Data safety: no change expected (Play's own review flow), owner to confirm.

## 2026-10-13 (d) — P2 / P3 from review (b) + the suggestions  (status: committed `052e3ab`..`ef8adef`; analyze 0, tests 536 green, Kotlin compiles; NOT built; needs a device check)

**P2 / P3** (all of review (b) is now done):
- `052e3ab` audio: vinyl resumes after a call; refused focus lifts the needle; headphones unplugged pause it
  (`AUDIO_BECOMING_NOISY`); Android 7–11 back-exit stops the media service; MASTER VOLUME applies to foley; no
  foley/haptics while hidden (`core/app_visibility.dart`); record drawer reopens on the right drawer (10 per drawer).
- `637c82e` "today" rolls over at midnight (`currentDayProvider`); widget counters carry `KEY_STATS_DAY`; no phantom
  countdown in widgets / tile after a reboot or force-stop (`liveStatus()`).
- `0cef1f2` new slips go to the end (`nextTaskSortOrder()`); RESTORE reloads the dispenser.
- `5cafdc3` desk clock: any touch anywhere wakes it; no dimming while another route is on top.
- `45b9269` "Start focus" shortcut starts focus and doesn't re-fire from Recents; silent alert channel
  (`zykl_session_alerts`); "CYCLE n"; custom change while paused ends the session; dial shows the real paused value.
- `7f0ed25` analytics: calendar-day bounds (DST); bars round per bar so they add up to the total.
- `c993bea` readable accents on light editions (`TaktColors.readableAccent`), bigger targets + semantics, reduce motion
  everywhere (`app/motion.dart`), tear drag no longer rebuilds the dispenser, volume writes on drag end, no 0-byte backups.
- "PRO chime kept after refund": moot — no chime is PRO-only (`AlarmChimes.all` has none with `isPro`).

**Suggestions**
- Session token (P1, (c)); Dart clock 30 s while hidden `4e4c426`; RepaintBoundary under the tilt + platter rests
  while dimmed `145e49e`; billing "No Studio PRO purchase found…" + quiet recheck on resume `fcc29f1`.
- `74bf54d` **schema v12**: Settings → DAY STARTS AT (00:00–06:00, stepper keys `day_start_*`) and WEEK STARTS ON
  SUNDAY (`week_starts_sunday_switch`). `logicalDay()` / `dayStartOf()` in `core/time/current_day.dart` drive analytics,
  streaks, today's stats, the desk slip and the midnight ticker. `timer_sessions.taskId`: a focus session records its
  slip; CSV gains a quoted `task` column; the JSON backup carries `task: {title, createdAt}` per session and a restore
  inserts slips first, then links sessions to the new ids (backup `format` stays 1; older apps ignore the field).
- `4221a88` **YEAR view** in Focus Analytics: 12 month bars, totals, best day; **Studio PRO** month×day heatmap
  (`widgets/focus_year_heatmap.dart`, levels <25 / 25 / 50 / 100+ min, today ringed, tap a day → read-out). Without PRO:
  a dimmed made-up sample + UNLOCK → `showStudioProDialog(feature: 'year heatmap')`.
- `74a8304` explicit backup rules (`res/xml/data_extraction_rules.xml`, `backup_rules.xml`): Auto Backup / phone
  transfer no longer copy `takt_widget_prefs`, `zykl_lockdown`, `zykl_permissions` (the new phone never asked for the
  notification permission), `zykl_shortcuts`. The database still moves.
- `ef8adef` widgets roll "today" over at DAY STARTS AT too (`KEY_DAY_START_HOUR`, same rule as `logicalDay`).
- Not done: moving the soundscape player / focus / noisy receiver fully into `MediaNotificationService` — targeted fixes
  in `052e3ab` instead; a full move is a large native refactor with device-only testing.

**Owner decisions / follow-ups**
- Website copy (Terms, FAQ, HonestSpecs, Studio PRO dialog sync note) says PRO = editions + soundscapes. If the YEAR
  heatmap ships as PRO, the site should mention it — not changed (website push = production deploy, ask first).
- Release **1.0.6** recommended: P1-1 (chime cut off) is in the shipped 1.0.4/1.0.5. Schema 12 migrates from 11 on
  first launch (tested in `database_test`).
- **Device checks**: DAY STARTS AT 03:00 → a 01:30 session counts for yesterday (analytics, streak, desk slip, widget
  counter until 03:00); WEEK STARTS ON SUNDAY; YEAR tab with and without PRO (heatmap tap); export CSV → `task` column;
  backup → restore on a clean install keeps session↔slip links; vinyl + phone call; unplug headphones; desk clock in
  Settings; "Start focus" shortcut on a break.

## 2026-10-13 (c) — Priority 1 fixes from review (b)  (status: committed `2d349ed`, `324b4e6`, `60ac46c` + lockdown `83270ee`; analyze 0, tests 510; NOT built)

- **P1-1 chime cut off** (regression 7e2d320, in the 1.0.4/1.0.5 AABs): Dart no longer calls `stop()` when native
  ended the phase (`tick(ringAlarm:false)` with auto-start off); `stopCountdown()` skips `stopSelf()` while
  `bellPlayer` plays — the chime's completion / `COMPLETION_HOLD_MS` ends the service (`finishIfIdle`).
- **P1-4 auto-start race / stale completion**: session id. Dart `start()` sends `sessionId` (µs epoch);
  `TimerForegroundService.activeSessionId` (generated natively for widget/tile starts) is echoed by
  `getRemainingMillis` and carried by the completion alarm (`EXTRA_SESSION_ID`). `resyncWithNative` ignores a status
  of another session; `ACTION_COMPLETE` of an older session is ignored while a countdown runs.
- **P1-2 PRO edition reset**: `DeskPreferencesController._editionAwaitingPro` keeps the refused premium edition; applied
  by `setProSimulated(true)` (the Play restore), so it is no longer overwritten with Braun Classic.
- **P1-3 billing stuck**: productless results (cancel / error / `itemAlreadyOwned`) return to idle; already-owned
  triggers `restore()`.
- **P1-5 DND left on**: lockdown keeps `dnd_applied` + previous filter in prefs `zykl_lockdown`; `restoreLockdownDnd()`
  on unlock, `onDestroy` and `onCreate`; only reverts if DND is still "Alarms only" (user changes are respected).
- Tests: productless purchase (3), PRO edition restore, chime/no-stop + stale-status race, session id round trip.
- **Device checks**: lock the phone in a focus session (auto-start off) → full chime at the end; auto-start on with
  the screen on → focus → break → focus with no skipped break; Play build with a PRO edition → relaunch keeps it;
  cancel the Play sheet → BUY usable again; lockdown with DND access → unpin + swipe away → reopen: DND back to before.
- Next: release 1.0.6 (P1-1 is in shipped builds), then P2 from review (b).

## 2026-10-13 (b) — Second app review (4 parallel read-only audits)  (status: review; P1 fixed in (c), P2/P3 + suggestions in (d))

Verified by hand: P1-1, P1-2, P1-3, P2 vinyl-resume, P2 drawer index, P2 sortOrder. The rest are traced by the audits.

**P1 (fix first; P1-1 is in the shipped 1.0.4/1.0.5 AABs)**
1. Finish chime cut off when the app is alive in the background and auto-start is off: `TimerForegroundService`
   always sends `nativePhaseFinished` (added in 7e2d320) → Dart `resyncWithNative` → `tick(ringAlarm:false)` →
   `_backgroundService.stop()` → `stopCountdown()` → `stopSelf()` → `onDestroy` releases `bellPlayer` mid-ring.
2. Release builds: a PRO user's edition resets to Braun Classic on every cold start, and the reset is saved
   (`settings_controller.init` refuses the premium edition while PRO is still false; `setProSimulated(true)` then
   saves the theme's current edition).
3. Cancelling the Play sheet leaves billing stuck in `purchasing` (BUY/RESTORE disabled): the plugin reports cancel /
   error / already-owned with `productID: ''`, and `_onPurchases` skips it.
4. Auto-start race: `resyncWithNative` trusts the kept `deadlineElapsed` of the previous phase → a phase can be
   skipped or a phantom focus session recorded. Related: a stale `ACTION_COMPLETE` can cancel the next phase's alarm.
5. Lockdown DND stays on ("Alarms only") if the app is unpinned and swiped away (`previousInterruptionFilter` in memory).

**P2**
- Vinyl never resumes after a call (`resumeOnFocusGain` cleared by the echoed pause); soundscape plays even if audio
  focus is refused; no `AUDIO_BECOMING_NOISY` (unplugging headphones); Android 7–11 back-exit leaves a dead "playing"
  media notification; master volume not applied to foley; record drawer assumes 6 discs per drawer (there are 10).
- "Today" stats and widgets go stale after midnight (streams fixed at creation; widgets store no date).
- Restore doesn't reload the dispenser (new slip can be lost); new slips get `sortOrder = active count` so focus credit
  can go to a slip other than the one marked NOW.
- Desk clock dims while the user is in Settings / task sheet / dialogs (wake listener only on the desk route).
- After a reboot / force-stop mid-session, widgets and the tile show a phantom countdown (stale `KEY_END_ELAPSED`).

**P3**: "Start focus" shortcut can start a break and can re-fire after the process is recreated from Recents;
"CYCLE 5/4" with a custom interval; double sound + vibration on native finish (alert channel has default sound);
paused custom-duration change keeps the old session; dial shows 25:00 when touched while paused; DST day/week ranges;
totals vs bars rounding; SAF picker result lost after process death (empty file); PRO chime kept after refund;
low-contrast labels on light editions; small/unlabelled touch targets; tear-drag rebuilds the whole dispenser per frame;
volume slider writes the DB on every step; a few animations ignore reduce-motion.

**Suggestions**: session token between Dart and native; native owns the phase end while hidden (pause the Dart clock);
`MediaNotificationService` owns the soundscape player/focus/noisy receiver; midnight ticker + "day starts at" + week
start; `task_id` on sessions; retry PRO restore on resume and "No purchase found"; RepaintBoundary under the tilt
Transform; stop the platter while the desk clock is dimmed; 48 dp targets and semantics; explicit backup rules.

## 2026-10-13 — Lockdown muted the vinyl  (status: committed; Kotlin compiles; NOT built; needs a device check)

Owner: with Monastic Lockdown on, the vinyl soundscape is silent. Cause: `enableFocusLock` set DND to
`INTERRUPTION_FILTER_NONE` ("Total silence"), which mutes media too (also the foley and the end-of-session alarm
chime). Now `INTERRUPTION_FILTER_ALARMS` ("Alarms only"): calls and notifications stay blocked, media and alarms play.
Only applies when DND access is granted (without it there was no DND, so audio already played). Restore on unlock is
unchanged (previous filter). Device check: grant DND access, play a record, start lockdown → music keeps playing, a
test call is silenced, the session-end chime rings.

## 2026-10-12 (e) — Website: Search Console "Duplicate without user-selected canonical" / "Page with redirect"  (status: website pushed `b823196`, verified live)

Search Console mail (Oct 12): Duplicate without user-selected canonical (2), Page with redirect (2), Crawled – not
indexed (1). All sitemap pages are fine (200, own canonical, index). Causes found: the static export serves Next.js RSC
payloads (`/about.txt`, `/index.txt` …, 200 text/plain, no canonical); `/coming-soon` was indexable; `/get` → `/coming-soon/`
→ 307 `/coming-soon` (two hops). Redirects of `http://` and `www.` are expected.
Fix (zykl.app repo): `public/_headers` `/*.txt` → `X-Robots-Tag: noindex`; `/coming-soon` `robots: noindex, follow`;
worker `/get` targets `/coming-soon`. Verified live ~70 s after the push. Owner: open the "Duplicate…" row to see the
example URLs and press "Validate fix"; redirect rows need no action. Remove the coming-soon noindex is not needed when
Play goes live (/get then points to Play).
Follow-up: the example URLs were /about and /privacy (crawled Oct 10). Their canonical has been correct since 09-29;
they still inherited og:url = home. `9edcd22` adds `src/lib/seo.ts` `pageOpenGraph()` on privacy, terms, changelog,
coming-soon (verified live). Owner: URL Inspection → Test live URL → Request indexing for /about and /privacy, then
Validate fix.

## 2026-10-12 (d) — v1.0.5 (versionCode 6) AAB built  (status: built + tagged `v1.0.5`; owner uploads to Play)

Owner approved the dev APK with the crown sounds and the status LED. `pubspec.yaml` 1.0.5+6. Built 11:06 with a 3.5 GB
cap (2.9 GB free): `build_outputs/zykl-playstore-release.aab` (65.8 MB), `com.zykl.app`, 1.0.5 / vc 6, jarsigner
verified, upload key `27:5B:8E:D7…` (CN=RSQUARE, OU=ZYKL). Adds (b) and (c) on top of v1.0.4.

Release notes (en-US):
> A more mechanical dial: winding the hand now clicks like a real watch crown, and pulling and pressing the crown
> sound like a Swiss stopwatch. The LED beside ZYKL now shows the timer state: amber while you focus, green on a
> break, dark on standby.

## 2026-10-12 (c) — Custom-set crown sound; status LED  (status: committed `8c7dce9`, LED commit; tests green (503); NOT built)

- Owner on the dev APK (b): crown taps in the custom set (focus → short → long) still played the dial tick; now every
  step plays the crown push (`advanceCalibrationStage`).
- Owner: the dot beside "ZYKL" looked decorative, and the opening had one above the dial. New
  `widgets/timer_status_led.dart` (portrait + landscape): off on standby, amber while focus runs or lockdown holds,
  green during a break. Opening power LED removed (`opening_micro_led` gone; the chassis warm-up glow stays).
- Device check: start → LED amber, break → green, stop/pause → dark; opening shows no dot.

## 2026-10-12 (b) — Crown sounds v2: real CC0 recordings, crown pull  (status: committed `b0e1677`; tests green (501); NOT built)

Owner: v1 (entry below) too loud and unnatural; wants a pull-crown sound too. Owner chose CC0 recordings from
Freesound and approved downloading two HQ previews (sources and cut points in `assets/audio/CREDITS.md`):
475185 "Stopwatch start - stop" (mycompasstv, Meylan Type 200A) and 847217 "Antique Pocket Watch Ticking and Winding"
(apintofmild). Only trimmed, high-passed 120 Hz, levelled; no pitch shift.
- `foley_crown_press.wav` (springButton) = stopwatch press incl. finger touch, peak −5 dB, 190 ms.
- `foley_crown_pull.wav` (new `SoundEffect.crownPull`, played by `enterCustomCalibration`, was `drawerLatch`) = the
  stopwatch's crown release, peak −8 dB.
- `foley_crown_wind_[abc].wav` = three pocket-watch winding clicks, peaks −16…−17 dB (v1 was −5 dB); native
  `MainActivity.FOLEY_VARIANTS` plays a random take per step (preloaded with the rest). `foley_crown_wind.wav` removed.
- The CC0 previews are 192 kbps MP3 (Freesound originals need a login); fine for these short clicks.
- Device check: pull crown → soft click out; wind → quiet, varied ratchet; push / start / pause → stopwatch press.

## 2026-10-12 — Crown sounds: winding ratchet and crown push  (status: committed `709336d`; analyze 0, tests green (500); NOT built)

Owner asked for a sound while winding the hand by hand and when pressing the crown to start, for a more mechanical
dial. Found: `SoundEffect.springButton` (crown start/pause/set, lockdown lever) had no entry in
`MainActivity.FOLEY_ASSETS`, so the crown push was silent; winding (`setTargetMinutes`) only buzzed.
- New `assets/audio/foley_crown_wind.wav` (40 ms) and `foley_crown_press.wav` (170 ms), cut with ffmpeg from the
  app's own original field recordings recovered from git: escapement tick `1bd8534:foley_dial_click.wav`, tactile
  switch `1bd8534:foley_switch_click.wav`, latch `e3b3316:foley_drawer_latch.wav`. Wind = tick pitched ×1.35 + pawl
  echo at 11 ms (−10 dB), peak −5 dB. Press = switch ×0.9 + latch ×0.7 low-passed (−8 dB) + spring return ×1.2 at
  92 ms (−9 dB). Not AI-generated. 
- `SoundEffect.crownWind` (new) plays once per minute the hand moves (`_windTick`; also stops the haptic firing on
  every pan event in calibration). `springButton` → `foley_crown_press.wav`.
- Spotted, NOT changed: since `711a2c9` `foley_dial_click.wav`, `foley_switch_click.wav` and `foley_drawer_latch.wav`
  are byte-identical (the latch sound); the original tick and switch recordings exist in `1bd8534`. `stepperPrint`
  (printing a slip) also has no native asset, so it is silent. Ask the owner before changing either.
- Device check: wind the dial (preset and calibration) → fine ratchet per minute; crown tap → press + spring return.

## 2026-10-09 (j) — v1.0.4 (versionCode 5) AAB built  (status: built + tagged `v1.0.4`; owner uploads to Play)

Owner approved the dev APK (island now expands with the progress bar and shows the minutes) and asked for the Play
update. `pubspec.yaml` 1.0.4+5 (`d2bfb44`). Built 16:11 with `scripts/build_test_apks.sh aab` (3.8 GB free):
`build_outputs/zykl-playstore-release.aab` (65.8 MB), `com.zykl.app`, 1.0.4 / versionCode 5, jarsigner verified,
signed with the upload key `27:5B:8E:D7…` (CN=RSQUARE, OU=ZYKL). Contains groups B, C, D and (i). Drift schema v11
migrates from any earlier install. Play Console: Android 16 Live Updates need no declaration
(POST_PROMOTED_NOTIFICATIONS is a normal permission); no new sensitive permission.

Release notes (en-US):
> Your timer now lives on the lock screen: on Android 16 it shows as a Live Update in the status bar, with the
> minutes left and a progress bar. Pause, resume or stop from the notification. New: auto-start the next phase,
> a Quick Settings tile, app shortcuts, desk clock mode, focus time per task slip, CSV export and backup/restore of
> your history. Widgets follow your theme and edition, and can be resized. Smoother dial and vinyl, and better battery
> life.

## 2026-10-09 (i) — Live Update chip shows minutes; owner feedback on the dev APK  (status: committed; NOT built)

Owner tested the dev APK (h): everything works, the Live Update shows in the phone's status island. Feedback:
- **No number in the island** → fixed: on Android 16 the countdown notification now sets `setShortCriticalText("24m")`
  (minutes left, ≤ 7 chars) and a `Notification.ProgressStyle` bar of the session for the expanded card. Built with
  `Notification.Builder.recoverBuilder` over the compat notification (androidx.core 1.13 has neither); re-posted on
  the existing minute tick in `startWidgetTick` (`refreshRunningNotification`). On a Pixel this replaces the live
  seconds chronometer in the chip by minutes; the notification itself keeps the chronometer.
- **Tap on the island should expand, not open the app**: not controllable by an app. The system / launcher decides
  what a tap on the chip does (screen record is a system chip). On most skins a long-press or a swipe down on the
  island expands it; the expanded card now has the progress bar and PAUSE / STOP.
- **Nothing on the AOD**: apps cannot draw on the AOD. Android 16 shows Live Updates there only where the OEM
  supports it (Pixel); other skins show at most the notification icon, depending on the AOD notification settings.
- **Dev APK rebuilt 15:58** (`build_outputs/zykl-developer-pro-universal.apk`, "ZYKL Dev", 66.8 MB; dex checked for
  setShortCriticalText/ProgressStyle). Built with a 3.5 GB cap while one Chrome window was still open (3.1 GB free).
- Device check after the next dev build: island shows "25m" → "24m" each minute; expanded card shows the bar.

## 2026-10-09 (h) — Group D: auto-start, QS tile, shortcuts, history files, focus per slip, English, widgets  (status: committed `7e2d320`..`0968694`; analyze 0, tests green; NOT built; needs a device check)

Review (d) section D, in the owner's order, with two changes from the owner: auto-start is a setting, and the app is
English only (no localization). Kotlin compiles; `flutter analyze` 0; full `flutter test -j 1` green (497 passed,
1 skipped). No APK/AAB built. Drift schema is now **v11** (v9 desk clock, v10 auto-start, v11 focus per slip).
- **D1 auto-start** (`7e2d320`): setting AUTO-START NEXT PHASE (Pomodoro Interval Engine; `auto_start_next_phase`,
  default off). At the end of a phase `start(auto: true)` (no button sound, the chime plays) restarts the native
  countdown in place, no stop. The native alarm now always tells a living Flutter `nativePhaseFinished` (→
  `resyncWithNative`), and with auto-start on (`EXTRA_AUTO_START_NEXT`) the service stays in the foreground until
  Flutter's START arrives (`finishIfIdle` after the chime / 6.5 s otherwise) — a backgrounded app may not restart a
  stopped FGS. App process gone: the phase ends in standby as before.
- **D2 Quick Settings tile** (`775cf94`): `ZyklTileService` "ZYKL Focus" = the widget toggle
  (`WidgetActionReceiver.toggleTimer`). Not an active tile: state + "FOCUS · N MIN" subtitle (API 29+) read from the
  widget prefs when the shade opens.
- **D3 launcher shortcuts** (`799ffd8`): dynamic (follow the dev-pro id): Start focus, Tasks, Analytics. Start focus
  carries a per-install token (`AppShortcuts`, prefs `zykl_shortcuts`) because the launcher activity is exported and
  external intents must not control the timer; Tasks/Analytics use `open_feature` ("analytics" added).
- **D4 history files** (`4c64ac8`): Settings → Telemetry → HISTORY FILES: EXPORT CSV, BACKUP (JSON format 1:
  sessions + slips incl. focusSeconds), RESTORE (merge: duplicates skipped, malformed ignored, foreign/newer files
  refused, never more than 5 active slips). System file picker via `com.zykl.app/backup` (SAF, no permission).
- **D7 focus per slip** (`3e9fe5b`): `tasks.focus_seconds`; each focus session counts for the top open slip when it
  started (finish, or abandon ≥ 1 min), even if stamped/torn meanwhile. Slip header "#01 // NOW · 50 MIN", minutes in
  the archive drawer. The dispenser refreshes on `AppDatabase.taskFocusChanges` (plain stream — drift `watch()` left
  timers that hung widget tests).
- **D5 English** (`7843c04`): a scan of every string in lib/, android/ and assets/ found one Indonesian string (the
  5-task limit exception); now English. Nothing else was Indonesian.
- **D6 widgets** (`0968694`): Material You corners (`@android:dimen/system_app_widget_background_radius` on 12+);
  Console / Focus Strip / Analog Dial follow the app's light/dark mode and edition (`widgetThemeSyncProvider` →
  `com.zykl.app/widget_theme` → `WidgetTheme` prefs; 12+ tints the chassis, older picks dark/light drawable);
  dispenser stays paper. All widgets resizable (min 110 dp; strip/dispenser 180 dp wide); dial bitmap drawn at the
  widget size (240–640 px) with the edition needle. Picker previews: `previewLayout` (12+) was already the live
  layout; no `previewImage` for ≤ 11 (would need rendered PNGs).
- Testing lesson: widget tests that touch a drift DB must end with `pumpWidget(SizedBox())` +
  `pump(100 ms)`, or `db.close()` waits forever (cost two 10-min hangs today). Run new test files with `timeout`.
- **Dev APK built 2026-10-09 15:21** for the owner's phone check (no AAB): `build_outputs/zykl-developer-pro-universal.apk`
  (66.8 MB, `com.zykl.app.devpro`, 1.0.3 / versionCode 4, debug key). Home-screen label is now **"ZYKL Dev"** (was
  "ZYKL DEV PRO", cut off by launchers; build.gradle.kts). Built after the owner closed Chrome (3.8 GB free).
- **Device checks**: auto-start on → focus ends, chime, break starts by itself (also with the screen off / app in
  background); QS tile toggles and shows minutes; long-press icon → 3 shortcuts work (Start focus from cold start);
  export CSV/backup to Downloads, restore on a clean install; run a focus with slips → "NOW · 25 MIN"; widgets in light
  mode + another edition, resize Console/Dial bigger and smaller, corners match other widgets on Android 12+.

## 2026-10-09 (g) — Group C: Live Update on the lock screen, paused card, desk clock mode  (status: committed `916028d`, `9920ef5`; analyze 0, tests green; NOT built; needs a device check, ideally an Android 16 phone)

Review (d) section C, options 1 and 2. Kotlin compiles; `flutter analyze` 0; full `flutter test -j 1` green (473 passed,
1 skipped). No APK/AAB built. No dependency bump: compileSdk is already 36.
- **C1 Live Update** (`TimerNotifications.kt`, `TimerForegroundService.kt`, manifest): the running countdown requests
  promotion with the extra `android.requestPromotedOngoing` (what NotificationCompat 1.17's `setRequestPromotedOngoing`
  writes; the SDK constant is only public from 36.1) + `POST_PROMOTED_NOTIFICATIONS` (normal permission, no prompt).
  It already met the rules (ongoing, title, standard style, not colorized, channel DEFAULT, no custom view), so on
  Android 16 it shows as a status-bar chip with the countdown and an expanded card on the lock screen / AOD. No
  `setShortCriticalText` on purpose: it would replace the live chronometer in the chip. The user can switch Live
  Updates off per app; then it is the normal notification. Older Android: unchanged.
- **Buttons**: running = PAUSE / STOP, paused card = RESUME / STOP (`WidgetActionReceiver.ACTION_NOTIF_*`). App alive →
  forwarded to Flutter as `pauseTimer` / `resumeTimer` / `stopTimer` (`appWidgetSyncProvider` routes them to
  pause/start/reset). App gone → the service pauses natively (`ACTION_PAUSE`, remaining from the boot-clock deadline),
  RESUME restarts it from the extras on the button, STOP stops it.
- **Paused card** (fixes A6 "nothing on the lock screen while paused"): `pausedTimerNotificationSyncProvider`
  (watched by the desk) posts it whenever the timer is stopped part-way (`pausedCardOf`) and clears it on start, reset,
  phase change and app start (a card from a session the app no longer knows). Not ongoing (swipeable), PUBLIC, id 1003.
  `ACTION_STOP` does not touch it (Dart pause = stop service + card); `ACTION_START` clears it.
- **C2 Desk clock mode**: setting "DESK CLOCK WHILE RUNNING" (System clearance card; Drift schema **v9**, column
  `desk_clock_mode`, default off; `.g.dart` regenerated). `DeskClockHost` (wraps the desk route in
  `takt_opening_screen.dart`): mode on + timer running → `FLAG_KEEP_SCREEN_ON`; 60 s without a touch → window brightness
  0.04 + 40 % black veil, desk shifts 3 px every minute (9 positions) against burn-in; the first touch only wakes (veil
  swallows it); app resume wakes too. Pause/finish/mode off → flag cleared, brightness back. `MainActivity` keeps
  separate claims for lockdown and desk clock on the keep-screen-on flag (`applyKeepScreenOn`).
- Not done: C3 DreamService (screen saver), C4 full-screen intent (Play restricts it). A settings shortcut to the
  system "Live Updates" toggle (`canPostPromotedNotifications`) could come later.
- Known, pre-existing: a session started natively while the app was closed (widget, or RESUME on a stale card) is not
  adopted by Flutter when the app opens later (Flutter only re-syncs a session it started itself).
- **Device checks**: Android 16 (Pixel / One UI 8): start focus → chip with countdown in the status bar, card on the lock
  screen and AOD; PAUSE from the lock screen → paused card "PAUSED · mm:ss LEFT", app shows paused; RESUME → counts on
  from the same time; STOP → card gone, app reset. Swipe the app away, then PAUSE / RESUME / STOP from the notification
  still work. Android ≤15: same buttons, normal notification. Desk clock: on, start a timer, don't touch → dims after
  1 min and moves slightly each minute, first tap only wakes; pause → screen times out normally; lockdown + desk clock
  → releasing lockdown keeps the screen on while the timer still runs.

## 2026-10-09 (f) — Group B: battery / performance fixes  (status: committed `391a5b4`..`6a9721c`; analyze 0, tests green; NOT built; needs a device check)

Fixes for review (d) section B. Kotlin compiles (`compileDebugKotlin --offline`); `flutter analyze` 0; full `flutter test -j 1`
green (461 passed, 1 skipped). No APK/AAB built.
- **B1 dial needle** (`chrono_dial_widget.dart`): the per-frame Ticker is gone; the needle notifier follows the
  controller's `remainingSeconds` (`ref.listen` + select), i.e. it repaints with the 250 ms clock instead of every frame.
- **B2 sensors** (`desk_canvas_screen.dart`, `parallax_controller.dart`): device gyro/accelerometer subscriptions are
  CANCELLED on `onHide` (pausing a sensors_plus stream keeps the hardware sensor on) and re-listened on `onShow`;
  injected test streams keep pause/resume. Touch/hover parallax respects the paused/opt-out state. Smoothing steps below
  `stepDeadband = 0.00008` no longer emit state (0.0002 broke the clamp convergence test).
- **B3 rebuilds**: dial tilt moved into `_DialTilt` / `_DialTiltShadow` (select on tilt only); `MaterialChassisBox`
  selects tilt only when `enablePerspective`, and light only when texture/glass rim is shown, quantised to 1/50
  (`_quantize`; the GlassRimPainter test uses `closeTo(.., 0.01)`); `IsometricDeskLayout` selects tilt only.
- **B4 vinyl** (`vinyl_deck_painter.dart`, `vinyl_player_widget.dart`): `VinylDeckLayer { all, base, disc, arm }`. The
  widget stacks base (static), disc (painted once in a RepaintBoundary, spun by `Transform.rotate` keyed
  `vinyl_disc_spin`, pivot `Alignment(-0.12, 0)`) and arm (repaints only while it moves). `layer: all` stays for stills.
  Tests read the spin angle from the Transform matrix.
- **B5 media telemetry**: the media notification shows "N MIN" (minutes left, rounded up) and `_syncMediaTelemetry` only
  pushes when phase, cycle or the minute changes (was every second). NOT done: stopping the Dart 250 ms clock while
  backgrounded (too risky for the phase-end logic; the foreground service owns the real deadline anyway).
- **B6 widgets** (`TimerForegroundService.kt`, widget providers, `takt_appwidget_focus_strip_4x1.xml`): the widget tick
  runs on minute boundaries of the remaining time (+20 ms) instead of every second, plus once on `SCREEN_ON` (receiver
  registered only while ticking). New pref `KEY_END_ELAPSED` (elapsedRealtime of the phase end, 0 when stopped, cleared in
  `stopWidgetTick`). Focus Strip: "FOCUS // " + a count-down `Chronometer` (`widget_status_chrono`) the launcher ticks by
  itself; falls back to static mm:ss if no end time is known (state pushed by the app). Analog dial: "N MIN", redrawn per
  minute. Console widget: only on start/stop (it has no countdown).
- **B7** plaques decode at display size (`cacheWidth = size × devicePixelRatio`; rsquare_logo 2000 px, zykl_icon 512 px).
  Tests unwrap `ResizeImage` via `_assetName`.
- **B8** (5 s opening) left as is: product decision.
- **Device checks**: run a 25-min session: dial needle moves smoothly, tilt still works, no jank; leave the app (home) →
  sensors stop (battery stats / no parallax drift on return); vinyl spins smoothly, arm drops/lifts; Focus Strip widget
  counts down every second, Analog dial widget shows "25 MIN" → "24 MIN" at the right time, screen off/on refreshes it;
  stop/finish → strip shows "STANDBY // READY" and the Chronometer stops; media notification shows "N MIN".

## 2026-10-09 (e) — Bug group A fixed (alarm, widgets, tear line, reduce motion)  (status: code done, analyze 0, tests green; NOT built; needs a device check)

Fixes for review (d) section A. Kotlin compiles (`compileDebugKotlin --offline`); `flutter analyze` 0; full `flutter test -j 1`
green (461 passed, 1 skipped). No APK/AAB built.
- **A1 alarm cut off** (`TimerForegroundService.kt`): one `COMPLETION_HOLD_MS = 6500` for the teardown safety net and the
  completion wakelock (was 3500 ms < zen gong 4.2 s / tibetan bowl 3.6 s); the chime `MediaPlayer` now has
  `setWakeMode(PARTIAL_WAKE_LOCK)`. The completion listener still stops the service as soon as a chime ends.
- **A2 widget check-off**: `WidgetActionReceiver` writes `completed_at` in Unix seconds (`/ 1000`, Drift's default).
  `AppWidgetService.onWidgetTaskToggle` (new stream with `taskId` + `isCompleted`) → `appWidgetSyncProvider` →
  `ReceiptRunnerController.applyExternalCompletion(id, isDone)`: mirrors the check-off into the in-memory list (no stamp
  sound) and rewrites it through Drift, so the active-task stream and the next widget sync agree instead of reverting.
- **A3 widget timer**: with the app process alive (also backgrounded), the toggle only forwards `toggleTimer` to Flutter,
  which starts with the real profile/chime/cycle and truly PAUSES (no more double toggle / reset). With the app gone, the
  native start uses the app's last `profile_name` / `alarm_chime_id` / `cycle_count` (new widget prefs keys written by
  `updateAllWidgetData`) instead of "CLASSIC 25/5" + braunBell + cycle 1; there it still stops (no Flutter state to pause
  into) — the label still says PAUSE. Widgets get today's real cycle count + `dailyGoalCycles` as target; the 4 LEDs show
  the share (`TaktAppWidgetProvider.litLeds`, goal 4 = one LED per cycle).
- **A4 tear line**: `AnimatedReceiptStrip` paints only its own drag (`currentTearProgress` param removed); the provider
  still receives the progress (tested), its per-frame cost is in group B.
- **A5 reduce motion**: opening→desk route (900 ms → 0), instrument `AnimatedSwitcher`, flip digits, receipt extrusion
  (decided in `didChangeDependencies`), crown press/pull and ink stamp durations → 0 when animations are disabled.
- **A6**: manifest FGS subtype text now says "home-screen widgets" (if the Play Console special-use declaration quotes the
  old text, update it there too). `isLockTaskPermitted` returning true is correct (plain screen pinning) → comment only.
  The "paused" lock-screen notification is part of the C1 Live Updates work, not done here.
- Tests: new `applyExternalCompletion` (state + no sound; persisted with a sane `completedAt`), `onWidgetTaskToggle`
  parsing; payload tests updated for `profileName`/`alarmChimeId`/`cycleCount`; the old "quadrant" test now asserts the
  real count (7 → 7) and the goal as target.
- **Device checks**: background the app, finish a session with Zen Gong → full ring; check a slip on the Task Dispenser
  widget with the app open and closed → stays checked, archive order sane; widget START/PAUSE with the app backgrounded
  → real pause, correct preset; daily goal 6 → LEDs fill by share; Reduce motion on (Settings → Accessibility) → no
  entry/switch/roll animations.

## 2026-10-09 (d) — App review: bugs, battery, lock screen / AOD plan  (status: review; group A fixed in (e), group B in (f), group C (1, 2) in (g), group D in (h))

Read-only review (3 parallel code audits + spot checks by the agent). Verified items are marked (✓ checked in code).

**A. Bugs (small, fix first)**
1. ✓ Alarm cut off when the app is in the background: `TimerForegroundService.onTimerFinished` posts a 3500 ms
   `stopSelf()` teardown (line ~364) and a 3500 ms wakelock; `onDestroy` releases the MediaPlayer. zen_gong 4.2 s and
   tibetan_bowl 3.6 s get cut (tubular_chime 3.2 s is borderline). Fix: teardown/wakelock = chime length + ~1.5 s,
   `MediaPlayer.setWakeMode(PARTIAL_WAKE_LOCK)`.
2. ✓ Widget task check-off writes `completed_at = System.currentTimeMillis()` (`WidgetActionReceiver.kt:137`) but Drift
   (default, no build.yaml) stores DateTime as Unix SECONDS → far-future dates, archive order broken. Also the
   `toggleTask` message to Flutter has no Dart handler, so the in-app list stays stale and the next widget sync can undo
   the check-off.
3. Widget timer: "⏸ PAUSE" actually stops and resets (`WidgetActionReceiver.kt:401-416`); start hard-codes
   "CLASSIC 25/5" + braunBell + cycle 1 (`:383-385`); possible double toggle with Flutter `toggleTimer`; cycle LEDs fixed
   at 4 instead of `dailyGoalCycles`.
4. Tear drag: every receipt strip paints the shared `currentTearProgress` (`animated_receipt_strip.dart:128-131`), so all
   slips show the tear line while one is dragged.
5. Reduce-motion gaps: desk entry transition, instrument AnimatedSwitcher, flip digits, receipt extrusion, crown/stamp.
6. Pausing removes the countdown notification (nothing on the lock screen while paused); `isLockTaskPermitted` always
   returns true; manifest FGS subtype text mentions "lock-screen widgets" (widgets are home_screen only).
   Checked, NOT a bug: `isProSimulated` defaults to true in the DB, but release builds force PRO false
   (`settings_controller.dart:167`).

**B. Battery / performance**
1. ✓ Dial hand Ticker repaints every frame while running (`chrono_dial_widget.dart:46-56` → painter `repaint:`), for a hand
   that moves ~0.17 px/s (≈90k–180k frames per 25 min, 3 blurred strokes each). Repaint at 1 Hz instead.
2. ✓ Gyro + accelerometer (~30 events/s, parallax on by default) never pause in the background (AppLifecycleListener has
   only onResume, `desk_canvas_screen.dart:79-85`); deadband 0.0001 before the low-pass; touch-move parallax ignores the
   opt-out (`:349-370`).
3. Parallax watches the whole provider in `isometric_desk_layout`, `chrono_dial_widget`, every `MaterialChassisBox` →
   desk transform + dial rebuild ~30×/s. Use `select`/listenables on small subtrees.
4. Vinyl deck repaints the whole static scene (blurred shadows, gradients) every frame; only the disc rotates. Split
   static painter + rotating cached disc layer.
5. A media notification is re-posted every second while the timer runs, even without vinyl (`_syncMediaTelemetry` →
   `MediaNotificationService ACTION_UPDATE_TIMER`); Dart 250 ms clock keeps running in the background.
6. Widgets: 1 Hz Handler redraws a 320×320 bitmap + writes SharedPreferences every second, no screen-state check; use
   `RemoteViews.setChronometer` (count-down) and minute-level dial updates. Console widget updated for nothing.
7. `rsquare_logo.png` 2000×2000 decoded for a 22–36 px plaque (≈16 MB); add `cacheWidth` or ship a small asset.
8. Opening ≈5.1 s on every cold start (product decision from 10-01 (f); could shorten after first launch).

**C. Lock screen / "AOD" (owner question)** — third-party apps cannot draw on the system AOD itself. Realistic options:
1. **Android 16 Live Updates** (recommended): promote the existing countdown notification (already ongoing, PUBLIC,
   chronometer countdown, no custom view). Needs `POST_PROMOTED_NOTIFICATIONS`, `setRequestPromotedOngoing(true)`
   (androidx.core ≥1.17; project has 1.13.1 → bump, or platform `Notification.Builder` behind SDK 36),
   `setShortCriticalText`, channel not MIN. Shows as a status-bar chip and expanded on the lock screen (AOD on supported
   devices). Add Pause/Stop actions and keep a "paused" notification. Older Android keeps today's notification.
2. **Desk clock mode** (all Android versions): optional "keep screen on while running" with an OLED-dark, dimmed dial,
   pixel shift against burn-in; best while charging. `setShowWhenLocked` only if the owner wants it over the keyguard.
3. Optional: a `DreamService` (screen saver while charging/docked) showing the dial.
4. Full-screen intent at the end of a session: Play restricts `USE_FULL_SCREEN_INTENT` to alarm/calling apps (Android
   14+); treat as risky, not planned.

**D. Feature gaps (nice to have)**: auto-start next phase; Quick Settings tile; launcher shortcuts; file export/backup of
history (only clipboard today); Indonesian localization (strings hard-coded, mixed EN/ID); widgets: Material You
corners/colors, light/dark + edition theming, real picker previews, `minResize*`; per-task time tracking.

Suggested order: A1–A4 → B1–B3, B5–B6 → C1 + C2 → rest. Every fix needs `flutter analyze`, `flutter test -j 1` and a
device check; no APK/AAB unless the owner asks.

## 2026-10-09 (c) — HD feature videos (Dispenser, Vinyl, Dial, Editions+Analytics) + Konten baru captions  (status: videos done; captions revised; film_capture + compose committed `463e858`, `7ce1c1a`, `624ffbe`)

- **Editions v2 (owner: show that the whole chassis changes, with a light pass):** gallery (Bauhaus) → dial montage
  Brass / Walnut / Indigo → Walnut (dark) on Dial, Tasks, Vinyl → real tap on the DARK/LIGHT pill → Bauhaus Heritage
  (light) on Vinyl, Tasks, Dial. Three slips are added in code before the first frame (`runner.addTask` via runAsync +
  `settle`) so the dispenser isn't empty. 31.7 s; shots EDITIONS, DIAL, then one steady `TOUR` (0.16–0.82) frame for both
  tours so the dispenser and turntable read large without the camera moving per tab. B11 caption updated (364 chars,
  "restyles the whole instrument"). Committed `624ffbe`.
  **Exception to the no-music rule (owner, 2026-10-09): the Editions video only** gets a bed of ZYKL's own recording
  "Warm Tape & Felt Piano" (`assets/audio/vinyl_warm_tape.ogg`, -7 dB, 2 s fade in, 3 s fade out before the bell,
  loudnorm -16 LUFS), because that clip is almost silent otherwise. Muxed after compose with ffmpeg (no re-render);
  the silent cut is kept as `Konten baru/feature_videos/ZYKL_Feature_Editions_4x5_no_music.mp4`. All other demo/feature
  videos stay without music; never add a bed to a clip that already plays a vinyl soundscape. B11 tip names the track.
- **Lockdown feature video done** (owner go-ahead): the Claude-chat `feat_lockdown` test passed unchanged (DND pre-flight
  does not get in the way under FilmFocusLockService; 5.25 s hold releases). `ZYKL_Feature_Lockdown_4x5.mp4` 17.1 s, one
  LOCK shot 3.0–11.9. In Konten baru it posts as **B8 (Mon 19 Oct, "Meet Monastic Lockdown.")**: same caption (it already
  described the 5-second hold), format Video, `08_Oct19_feature_lockdown.mp4`; the old PNG is in `_replaced_by_feature_videos/`.
  Konten baru now has 6 HD feature videos: B4 Dial, B8 Lockdown, B11 Editions, B12 Analytics, B18 Vinyl, B25 Dispenser.
- **Sound decision (owner A/B, 2026-10-09): no background music/bed in demo or feature videos**, only the app's own
  sounds. Test files: `Konten baru/AB_test_backsound/` (A = as is, B = quiet piano bed from 0 s); A won.
- **Owner follow-up (same day): Editions and Analytics split into two videos.** `feat_editions` now = equip Bauhaus
  Heritage once through the gallery (how), then a dial montage while it runs: Raw Brass → Walnut → Titanium → British
  Racing Green → Indigo, swapped in code via `deskPreferencesControllerProvider.notifier.setHardwareEdition` every 2.2 s
  (26.0 s video; shots EDITIONS + one long DIAL hold). The first attempt (4× `_equip`) spent most of 31 s in the settings
  sheet. New `feat_analytics`: desk plate → telemetry slip → Focus Analytics DAY / WEEK / MONTH (15.5 s; shots TELEMETRY +
  STATS). In Konten baru: B11 = editions-only caption (366 chars); **B12 (Fri 23 Oct, Principle) now posts the analytics
  video** with a privacy caption (331 chars; the old text said "No analytics", which clashed with the feature: now "no
  tracking"); `12_Oct23_data_stays_here.png` moved to `_replaced_by_feature_videos/`.
- **Videos** (all captured from the real Flutter widgets at 3× = 1152×2400, composed 1080×1350 @60 fps with the app's own
  sounds on the exact frames): `promo/Konten/Konten 3/feature_videos/ZYKL_Feature_{Dispenser,Vinyl,Dial,Editions}_4x5.mp4`
  (20.3 / 17.2 / 19.6 / 20.3 s). Lockdown is on hold (owner: not yet).
- Capture recipe used (owner keeps Chrome open, so a tighter cap than run_content.sh's 4 GB; peak RSS was only ~0.7 GB):
  `systemd-run --user --scope -p MemoryMax=3000M -p MemorySwapMax=256M -p CPUQuota=200% nice -n 19 flutter test
  film_capture/content_clips_test.dart --plain-name "content feat_<x>" --dart-define=FILM_DIR=$HOME/.cache/zykl-film/content
  --dart-define=FILM_PR=3 --dart-define=FILM_HIDE_DEV_TOOLS=true` (smoke first with FILM_PR=1 and content_smoke), ~3 min
  each; then `compose.py feat_<x> --cues` → SHOTS → `--still` check → `--out`.
- `content_clips_test.dart`: new `feat_dial` (presets 50/10 → 15/3 → 25/5, CUSTOM + crown 40/8, start) and
  `feat_editions` (settings gallery → equip Mid-Century Walnut, desk plate → telemetry slip → analytics WEEK, MONTH).
  `_seedWeek` dates history from the REAL `DateTime.now()`: the DB/analytics use `DateTime.now()` while FilmScene freezes
  package:clock at 2 Oct 2026, so a clock-based seed showed an empty week on 9 Oct. `_period()` helper for the tabs.
  The Claude-chat `feat_dispenser` / `feat_vinyl` tests ran unchanged and pass (tear swipe really archives the slip).
- `compose.py`: SHOTS for all four (calm camera: few long holds) and regions `PLATTER` (turntable card) and `EDITIONS`
  (settings carousel). Note: the mockup status bar draws "9:41" (iPhone-style) in every demo; left as is for consistency.
- **Konten baru** (owner: base = the OLD 8 Oct docs, not Konten 3):
  - `ZYKL/media/`: `04_Oct15_feature_dial.mp4`, `11_Oct22_feature_editions.mp4`, `18_Oct29_feature_vinyl.mp4`,
    `25_Nov05_feature_dispenser.mp4`; replaced PNGs moved to `ZYKL/media/_replaced_by_feature_videos/`. Copies of the four
    masters in `Konten baru/feature_videos/`.
  - `Founder/images/`: 11 images replaced by the Konten 3 versions (ZYKL mark + @zykl.app, no personal name, owner's
    earlier request); old ones in `Founder/images/_old_with_personal_name/`. f29–f35 (Konten 3 only) not added: the old
    founder doc ends on 8 Nov.
  - `ZYKL/zykl-threads-pack-3-ZYKL.docx`: Thursdays B4/B11/B18/B25 are now "Feature video" posts (captions 262/406/278/315
    chars), calendar + weekly rhythm + intro updated, B19 "Android 7.0 and newer". `Founder/...FOUNDER.docx`: F17 (Wed
    28 Oct) is now a behind-the-build post about the HD clips that teases B18 (387 chars). Originals in
    `Konten baru/_arsip_sebelum_revisi_09okt/`. Edited by unzipping and rewriting run texts (script in the agent
    scratchpad; docs were docx-js output, one run per paragraph). The old founder doc still has 5 yellow placeholder
    lines (e.g. "[Day 14 done / Day N of 14]") the owner must fill; the root `zykl-threads-pack-3-brand-founder-en.docx` is
    the even older combined draft and was not edited.

## 2026-10-09 (b) — Website film updated to the 44 s remaster  (status: pushed `43dbc1e` + `158d8f2`, verified live)

- Web cuts from the four remaster masters with `promo/Video Motion Remaster/source/web_cuts.sh` (same recipe as the v3
  `composite.sh` web(): 720p/30 fps, CRF 27 ≈ 400 kbps, AAC 96k, poster at 00:14 = the "Pull the crown" scene) →
  `zykl.app/public/video/zykl-promo-{dark,light}[-portrait].{mp4,-poster.jpg}`, 2.6–2.8 MB each, 44.01 s.
- `FilmSection.tsx`: "40" → "44" in the header label, play button, aria labels and doc comment. `FILM_VERSION =
  "?v=2026-10-09"` appended to the 8 video/poster URLs, because `/video/*` is cached 30 days under fixed names (returning
  visitors would keep the 40 s cut and the dark/light twins could differ in length). **Bump it on every re-cut.**
- Verified live: the four mp4s served by Cloudflare are byte-identical to the local cuts (44.01 s); the version string is
  in the live page chunk (the poster is client-rendered, so it is not in the HTML).
- **Range requests fixed (website `27f517a`, live).** Cause: Workers Static Assets ignore `Range` and always send the whole
  file with 200 (on zykl.app and on workers.dev alike); iOS Safari needs 206 to play <video>. `wrangler.jsonc`
  `run_worker_first` now also has `/video/*` and `/audio/*`; `worker/index.js` `serveMedia()` fetches the asset without
  Range and slices one byte range (206 + Content-Range, 416 + `bytes */size`, multi-range → whole 200, HEAD/full 200 with
  Content-Length + Accept-Ranges; 304/404 pass through). Do NOT `export` helpers from the Worker module (named exports are
  read as entrypoints). Tested: 10 Node cases with a fake ASSETS binding; live curl 206/416 with bytes identical to the
  local file, audio 206, `/` 200, `/get` 302; Chromium plays and seeks to 30 s in 0.8 s (206 in the network log).
  Not tested on a real iPhone/Safari yet (owner).

## 2026-10-09 — Threads Content Pack 3 (both accounts) + feature videos; HD Flutter feature capture prepared  (status: content delivered to `promo/Konten/Konten 3/`; capture scripts written but NEVER RUN, nothing committed)

Done in a Claude cloud session (Cowork). It had no Flutter and no shell on this PC, so the agent only wrote files. Next agent: run, fix and commit.

**Content pack (`promo/Konten/Konten 3/`, untracked like the other renders in `promo/Konten`; keep mp4/png out of git):**
- `ZYKL/zykl-threads-pack-3-ZYKL.docx`: @zykl.app, 35 posts, 12 Oct–15 Nov 2026 (5 weeks, one a day). `ZYKL/media/` has
  22 PNG (1080×1350), the 8 Konten 1 demo videos and 2 feature videos, all named in posting order `NN_MonDD_slug`.
- `Founder/zykl-threads-pack-3-FOUNDER.docx`: @rickyprayasa, 35 posts, 12 Oct–15 Nov. `Founder/images/` has 18 PNG.
  F29–F35 (9–15 Nov) are a Gen Z "My setup" week (studying, coding, admin, languages, writing, creative, reading).
  Founder images carry the ZYKL mark and @zykl.app only, no personal name (owner request).
- Every caption placeholder is filled from this log. Guesses the owner must check: tester/day counts (F8, F15, F22, F28),
  morning routine (F5), RSQUARE one-liner (F12).
- Price everywhere: "US$4.99, or Rp 69.000 in Indonesia". Old "BRAUN" labels in recordings were replaced by the current
  "ZYKL TP-01" / "MODERNIST CLASSIC".
- Sources to rebuild docx/images: `Konten 3/_source/` (see its README: `posts.js`, `brand5.js`, `build.js`, `img/gen.py`).
- Stale files the owner should delete: `Konten 3/ZYKL/media/18_Oct29_record_spins.png`, `25_Nov05_torn_edge.png`,
  `Konten 3/ZYKL/images/`, `Konten 3/images/`, `Konten 3/zykl-threads-pack-3-brand-founder-en.docx`.

**Feature videos (new series: one feature per video, same look as the Konten 1 demos, Thursday slot on @zykl.app):**
- Done from device screen recordings (lower quality, owner wants HD instead): B18 Thu 29 Oct `18_Oct29_feature_vinyl.mp4`
  (`New Vinyl Dark.mp4`), B25 Thu 5 Nov `25_Nov05_feature_dispenser.mp4` (`Dispenser Light.mp4`). compose.py keys
  `rec_vinyl` / `rec_dispenser`; frame prep in `Konten 3/_source/feature_video/`.
- **HD from Flutter (NOT RUN YET):**
  - `film_capture/content_clips_test.dart`: new tests `content feat_lockdown` (crown → LOCKDOWN → hold unlatch 5.25 s →
    released), `content feat_dispenser` (light: print 3 tasks → stamp first → swipe tear), and `content feat_vinyl`
    (Kyoto Bamboo → needle → Debussy, then platter).
  - `film_capture/run_features.sh [lockdown dispenser vinyl]` runs `run_content.sh feat_<x>` (3×, cgroup) and then
    `promo/Konten/demo/compose.py feat_<x>`. Output goes to `promo/Konten/Konten 3/feature_videos/ZYKL_Feature_<X>_4x5.mp4`.
  - `compose.py`: `feat_*` entries have `shots=[]` (whole phone, no zoom). After the first capture, run
    `compose.py feat_<x> --cues` and add SHOTS like the demos (regions DIAL / DIAL_LOCK / LOCK / SLIP / DISP / DECK).
  - Untested guesses to check first: `find.bySemanticsLabel('Lift tonearm')` after the needle drop (vinyl), whether a
    swipe on `AnimatedReceiptStrip` tears in the test (dispenser), and the Lockdown hold time.
- `film_capture/film_scene.dart`: added `FilmScene.settle(seconds, {step})` (advance without recording) and
  `FilmScene.still(path)`. `film_capture/stills_test.dart` + `run_stills.sh`: 22 HD stills (dial in all 12 editions,
  dispenser, vinyl, lockdown) plus a JSON of component rects, for social images. Not run yet either.

**Next steps:**
1. `bash film_capture/run_features.sh lockdown` → fix any test failure → time SHOTS from `--cues` → re-compose.
2. Then `dispenser` and `vinyl`. Replace the B18/B25 videos (same filenames) and put Lockdown in a Thursday slot
   (`Konten 3/_source/brand5.js` → `FEATURES`, rebuild the ZYKL docx with `build.js`).
3. `flutter analyze` and commit the `film_capture/` + `compose.py` changes (owner OK first).

## 2026-10-08 (f) — Pricing: USD 4.99 base + Rp 69.000 Indonesia; website copy fixed  (status: owner set Play prices; website pushed `2ad3501`, verified live)

- Problem (owner): with IDR 69,000 as the Play base price every other country was converted from rupiah (e.g. USD 3.86),
  so the dollar price drifted down. Fix (owner did in Play Console → `studio_pro_lifetime` → Set prices): all regions
  from **USD 4.99**, then **Indonesia overridden to IDR 69,000**. Prices only change again if someone presses "update
  exchange rates".
- Website (`zykl.app`, commit `2ad3501`, auto-deployed): every "Rp 69.000, about $4.99" → "US$4.99, or Rp 69.000 in
  Indonesia" (HonestSpecs, FAQ, Terms, OwnershipFaq, changelog); JSON-LD has a USD 4.99 offer plus the IDR one
  (`eligibleRegion: ID`). Android support corrected to **7.0–16** (app `minSdk` = 24 via `coerceAtLeast(24)`, target 36;
  Play shows "API levels 24+"): HonestSpecs, FAQ, SpecsMatrix, PlayStoreCta, JSON-LD `operatingSystem`. The SpecsMatrix
  note no longer claims testing on specific Android versions. "under 20 MB" kept: Play download is ~13 MB.
- Not built locally (a promo render was using the RAM; files were parse-checked with the TypeScript parser instead);
  Cloudflare built it fine, live HTML checked with curl. The site still shows `V1.0.0` on purpose until the public release.

## 2026-10-08 (e) — Promo Remaster: 8 s Dial scene fixed, polish pass, new 44 s music  (status: 540p full preview + music c/d/e awaiting owner review; masters NOT rendered)

Owner decision (2026-10-08): keep the film at **44 s** (not 40 s, so it isn't rushed); regenerate the music so nothing
repeats. Supersedes the 10-05 "4 s Dial scene / 40 s" plan. All files are in `zykl.app/promo/` (git-ignored).
- Found: `anim.js` had been edited on 10-05 (8 s `dialScene`, 12–20 s) but was never rendered and was broken: `#s4c` stayed
  `display:none`, so the crown phone + copy were invisible for 12–17 s, and the analog phone sat LEFT (Lockdown is RIGHT →
  jump). Backup of that state: `source/anim_2026-10-05_dial8s.backup.js`. No backup exists of the anim.js behind the
  approved 10-02 Dark 16:9 (its MP4 is safe).
- Rewrote `dialScene()`: crown phone LEFT (starts in a 1.42× macro on the crown, one ease-back 0.6–2.6 s), copy +
  counters RIGHT; 4.25–5.65 s the phone glides LEFT → RIGHT with a sheen while crown → analog clips crossfade; analog =
  the v3 S4 layout (phone x=134, ry −13, copy LEFT), which is exactly where Lockdown starts at 20 s. Portrait keeps the
  phone in place (crossfade only) — 9:16 NOT checked yet.
- Music: `promo/scripts/generate_zykl_promo_audio_v3_44s.py` (ElevenLabs `/music`, composition plan 11 × 4 s @ 120 BPM; the
  Dial scene gets two distinct sections "Groove A Crown" / "Groove A Analog"). Output `scripts/zykl_promo_audio_v3_44s/
  music_{a,b}.mp3` (take b fell back to the plain prompt after a timeout, so it is less grid-locked). Mix:
  `source/mix3_44s.py SFX_DIR MUSIC.mp3 OUT.wav` = mix2 cues, +4 s after 15.9 s, plus a soft glide whoosh (16.25 s) and three
  1 Hz escapement ticks (17.6/18.6/19.6 s) → `source/audio_remaster_44s_v3{a,b}.wav`. The old `audio_remaster_44s.wav`
  (with the duplicated bars) is untouched.
- Preview: `Video Motion Remaster/PREVIEW_Dial_10-22s_Dark_16x9_music_{a,b}.mp4`.
- **Polish pass (owner: "masterpiece", 2026-10-08 afternoon)** after reviewing stills of the whole film:
  zooms shrunk so the phone body never leaves the frame (lockdown 1.3 → 1.14, vinyl 1.25 → 1.12 in `sceneZooms`);
  UNIT numbering now Dial 01 / Lockdown 02 / Dispenser 03 / Turntable 04 (`index.html` labels + `.numeral`);
  small copy ≈1.4× for phone viewing (`.lab` 2.5rem, `.row` 2.6rem, `.rows`/`.ticker` 70rem wide, `.ename`, `.badgeM span`,
  `.counter span`, `.slots span`). Backup: `source/index_2026-10-08_pre-polish.backup.html`. Verified with stills in
  16:9 and 9:16 (portrait Dial scene = crossfade in place, looks fine).
- **Music, round 2.** Owner picked take b for its audible clock tick, but b (loose prompt) had the hit at 4 s instead of
  8 s and went silent at 40 s. The plan now asks for a clock tick on every beat for the whole piece, a quiet Lockdown
  breakdown and "no silence before the end"; the generator retries the plan 3× and never falls back (`python3
  generate_zykl_promo_audio_v3_44s.py c d e`). Measured (4 s RMS): **c** = cleanest arc (silent chaos, hit at 8 s, level
  to 42 s); **e** = same with a louder second half; **d** = quiet until 12 s. Mixes: `source/audio_remaster_44s_v3{c,d,e}.wav`.
  Agent recommendation: c.
- Preview for the owner: `Video Motion Remaster/PREVIEW_Full_44s_540p_music_{c,d,e}.mp4` (960×540 render of the full
  film, same layout as 1080p since everything scales with `R`).
- Next after the owner picks a take: set that wav in `render_chunks.sh` (currently still `audio_remaster_44s.wav`!) →
  Dark 16:9 → Light 16:9 → Dark 9:16 → Light 9:16, one at a time.
- **Owner picked music take b** (`audio_remaster_44s_v3b.wav`; `render_chunks.sh` now muxes it). Owner flagged 3 clicks in
  the Analog half with nothing being tapped: those were my 1 Hz `tick` cues → removed.
- **Analog half now demos the presets** (owner idea): new capture `clip presets {dark,light}` in
  `film_capture/clips_test.dart` (timer idle so the cassette keys are live: 25/5 → 50/10 → 15/3 → back to 25/5 for the
  Lockdown hand-off), 156 frames, taps at frames 31/67/103; frames converted with `Video Motion v4/source/prep_frames.py`
  (manifest backup `frames/manifest_2026-10-08.backup.js`). `anim.js`: `ph4` uses `presets`, `KN.presets` lands the taps at
  17.45 / 18.25 / 19.05 s, and the DEEP FOCUS / SHORT REST / LONG RECOVERY rows switch with each press (short accent glow).
  The mix has a soft `ui_click` (−13) on each of those three presses instead. (`anal` = analytics, not analog; unused.)
- Preview: `PREVIEW_Dial_10-22s_Dark_16x9_v3b.mp4`. Masters still NOT rendered.
- **Polish round 3 (owner OK'd all four suggestions, 2026-10-08; English only; keep the Google Play badge):**
  1. Preset copy: label `UNIT 01 // PRESET CASSETTE`, headline "Classic. Monastic. / Sprint." (was "Analog hands. A calmer
     rhythm.", which repeated "rhythm" after the crown line), first row `PRESET CLASSIC→MONASTIC→SPRINT→CLASSIC`
     switching with the other rows (`PRESET_VALS`).
  2. Hook: `chipT0()` lands six notifications in the first 0.3 s (film opens mid-chaos); the mix uses the same curve +
     a buzz at 0.02 s.
  3. ~~Vinyl sound moment~~ (music duck + app stylus + `vinyl_warm_tape.ogg` at the 26.27 s needle drop) was tried and
     **rejected by the owner** ("breaks the promo mood"). Vinyl keeps the v2 `needle` cue at the scene start (24.18 s).
  4. **Session order:** Dial 12–20 → Dispenser 20–24 → Vinyl 24–28 → Lockdown 28–32 → Editions → Ownership → Outro.
     Done in `SEGS` (slot 4/5/6 = s5/s6/s4b) + the GRID visibility rule in `renderOld`; hero dial behind Lockdown now
     fades in (`.16 * seg(t, 40, 40.8)`); UNIT numbers Dial 01 / Dispenser 02 / Turntable 03 / Lockdown 04; lockdown zoom
     1.14 → 1.06 (the scene-out scale stacks on it and cropped the phone top).
  New mix script `source/mix4_44s.py SFX_DIR APP_AUDIO_DIR MUSIC OUT` (explicit per-scene cues; mix3 is obsolete) →
  `audio_remaster_44s_v4b.wav` (music b); `render_chunks.sh` muxes v4b. Backups of the pre-round-3 state:
  `source/*_2026-10-08_presets.backup.*`. Verified with stills 16:9 + 9:16. Preview: `PREVIEW_Full_44s_540p_v4.mp4`.
- **Owner approved the 540p preview (2026-10-08).** Old 10-02 masters moved to `Video Motion Remaster/previous_2026-10-02/`.
  **Dark 16:9 master rendered 11:40** → `ZYKL_Promo_Remaster_44s_EN_Dark_16x9.mp4` (1920×1080, 60 fps, 2640 frames, 44.0 s,
  12.7 Mbps, AAC from `audio_remaster_44s_v4b.wav`; seams at 11/22/33 s checked with a tblend frame-difference pass, no
  freeze/jump). Awaiting owner review; then Light 16:9 → Dark 9:16 → Light 9:16, one at a time (`./render_chunks.sh <variant>`).
  Note: the 540p preview looks soft on the phone UI; that is the preview resolution only (1080p is sharp).
- **Owner approved Dark 16:9 ("Masterpiece!!", 2026-10-08) and asked for the rest.** Light stills checked first (the dim
  phone in Ownership is the app's own modal scrim behind the light analytics dialog: correct). Old 10-02 chunk caches
  were deleted (otherwise `render_chunks.sh` skips `.done` parts and reuses old picture), then Light 16:9 → Dark 9:16 →
  Light 9:16 rendered back to back in one sequential loop (logs `~/.cache/zykl-film/render_remaster_<variant>.log`).
  If interrupted: re-run `./render_chunks.sh <variant>` (resumes per chunk). Light masters are large (~140 Mbps at
  crf 14 because of the grain on a light background); make a lighter delivery encode if needed.
- **Owner review of the new masters found 3 bugs → ALL FOUR masters re-rendered** (Light 9:16 run was stopped; old
  Light 16:9 / Dark 9:16 from this morning are superseded):
  1. Portrait crown too small: `growPhone` caps portrait zoom at 1.18; it now takes a per-call cap and the crown macro is
     2.1× in portrait (v=.28, eases back .9–2.6 s). 16:9 unchanged (1.42×).
  2. Glitch at 27–28 s (all variants, incl. the approved Dark 16:9): Editions (`s7`) still crossfaded in at the end of
     Vinyl, as in the v3 order. GRID rule now hides `s7` while `NT < 27.8`.
  3. Portrait Editions labels overlapped the lower phones (labels were enlarged 1.4×) and then the footer HUD: phones 29 →
     24 wide, rows y 81/146 → 77/143. Checked dark + light stills.
  Queue: dark_16x9 → dark_9x16 → light_16x9 → light_9x16 (sequential).
  4. Tear SFX (owner): it played at 21.95 s (the v3 overlay timing) but the slip only leaves the phone's dispenser at
     ~23.1 s (clip frames 169–183 → 23.03–23.27 s; checked frame by frame). `mix4_44s.py` tear cue → 23.08 s; wav rebuilt
     before the re-render queue reached its mux step, so all four masters carry it. Audio-only fixes never need a video
     re-render: re-mux the chunk list in `~/.cache/zykl-film/render_remaster/<variant>/list.txt` with the new wav.
  5. **My regression:** the portrait-editions edit appended a `//` comment mid-line and commented out the 16:9 `else`
     branch, so in 16:9 all four Editions phones sat at (0,0). Fixed (comment on its own line); every changed line with a
     trailing comment re-checked. Lesson: verify stills in BOTH orientations after any layout edit.
  6. Boom (`hit`): owner wants it ON the white flash of the ZYKL reveal. Measured frame luma: flash peaks at **8.367 s**
     (rises from 8.28); hit.mp3 peaks 0.015 s in → cue at **8.35 s** (onset measured at 8.36 s in the muxed master).
     `riser` 4.85 s so it ends on it. (A first try at 8.8 s, aligned to the letters, was wrong.)
  **Owner rule (2026-10-08): do NOT queue all renders; send review material first, render one variant on approval.**
  State: Dark 9:16 master = final picture + current audio (remuxed). **Dark 16:9 re-rendered (chunks 22–44) 16:06**,
  verified (2640 frames, seams, editions row, no bleed at 27.7–27.95, boom onset 8.36, tear 23.03–23.1); the PC hung once
  mid-render (RAM: owner's Chrome + LibreOffice) and the orphaned chunk was killed and redone. Light 16:9 has chunks 0 and 11
  done (correct), 22/33 pending. Light 9:16 not started. Review sheets: 14 stills per variant.
  7. Owner: the big background dial was frozen during the Dial scene (12–20 s). `dialScene` lays the background out from
     one frozen v3 time (`renderOld(warp(15.5))`), so the hero needle stopped. It now overrides `#dneedle` with the same
     escapement (2 steps/s) continuing from v3 time 11.2: measured 404° at 11.9 and 12.0 s (no jump at the cut), 500° at
     19.98 s, identical in 16:9 and 9:16. **Chunk 11–22 is stale in every variant**: `part_011` deleted from the caches of
     dark_16x9, dark_9x16 and light_16x9 (Dark masters on disk still have the frozen needle until re-rendered).
     **Both Dark masters re-rendered (chunk 11–22 only, ~4 min each, 16:18–16:27)** and verified: 2640 frames, seams,
     needle visibly advancing at 12.2/15/17 s in both. Dark 16:9 + Dark 9:16 are now final pending owner review.
     Remaining: Light 16:9 (chunks 11–44) and Light 9:16 (full), one at a time on the owner's OK.
  8. **PAUSED 2026-10-08 16:50 at the owner's request (resume tomorrow).** Light 16:9 chunks 0, 11 and 22 are done
     (`.done` markers; part_022 was finished after the queue was stopped, verified 660 frames, marker written by hand).
     Resume, one variant at a time, after checking `free -m` (owner closes browsers first):
     ```
     cd "/home/tuneeca/RSQUARE/Android/zykl.app/promo/Video Motion Remaster/source"
     ./render_chunks.sh light_16x9   # only chunk 33–44 left (~10 min), then it muxes the master
     ./render_chunks.sh light_9x16   # full render
     ```
     Speed-up used with the browsers closed: raise the running chunk's cgroup with
     `systemctl --user set-property --runtime <run-…scope> CPUQuota=380%` (find it with
     `systemctl --user list-units --type=scope | grep run-`); render.mjs now encodes with 3 x264 threads
     (`FF_THREADS` env overrides). Light renders ~1 fps at the default 150% quota vs ~2.7 fps for Dark.
  9. **2026-10-09: all four masters DONE.** Owner found the mirror of bug 2: at 32 s (Lockdown → Editions) Vinyl (`s6`)
     faded back in, because v3 time jumps back to 24.4 s where Vinyl's scene-out still runs. GRID rule now hides `s6`
     while `NT >= 24`. To stop whack-a-mole, a **scene-bleed scan** renders t = 0…44 s every 0.05 s and flags any `.scene`
     visible outside its slot ±0.45 s (session order s1,s2,s3,s4c|s4,s5,s6,s4b,s7,s8,s9): 960×540 and 540×960 both
     **CLEAN** (script: `source/scan_scene_bleed.mjs DIR W H QUERY`; run it after ANY timeline/order change). Chunk 22–33 re-rendered for Dark
     16:9, Dark 9:16, Light 16:9; Light 9:16 rendered fully after the fix. All four: 2640 frames, 44.0 s, 0 render
     errors, 31.9/32.1/32.3 s frames checked. Gotcha: a `pgrep -f "<pattern>"` wait loop matches its own bash command
     line and never ends; wait on a PID or a log line instead.
- Next after owner OK: pick take a/b → point `render_chunks.sh` at that wav → render Dark 16:9 (≈30 min) → then the other
  three variants one at a time (old Light 16:9 / Dark 9:16 from 10-02 are obsolete; Light 16:9 was 140 Mbps, check bitrate).

## 2026-10-08 (d) — v1.0.3 (versionCode 4) built and verified  (status: built + pushed with tag; owner uploads the AAB)

- Commits `448fbf6` (countdown notification channel), `328f9ae` (deps), `c072e56` (`version: 1.0.3+4`), tag
  **`v1.0.3`**. Built 2026-10-08 08:04–08:08 with `scripts/build_test_apks.sh aab developer-pro` (AAB + dev-pro only,
  as the owner asked). v1.0.2 outputs archived in `build_outputs/previous/2026-10-08-v1.0.2/`.
- Verified (next session, read-only): `zykl-playstore-release.aab` (65.5 MB) base module → aapt2 badging
  `com.zykl.app`, versionCode 4, 1.0.3; signed with the upload key `27:5B:8E:D7…` (CN=RSQUARE, OU=ZYKL).
  `zykl-developer-pro-universal.apk` (66.4 MB) → `com.zykl.app.devpro`, versionCode 4, 1.0.3.
  Tip: to badge an AAB, unzip `base/`, move `manifest/AndroidManifest.xml` to the root, zip with `resources.pb` + `res`,
  `aapt2 convert --output-format binary`.
- Next (owner): Play Console → Closed testing → Tester → Create new release → upload the AAB. Device checks after
  install over 1.0.2: countdown notification sits with normal notifications and stays silent; existing SQLite data still
  opens (sqlite3_flutter_libs removed); parallax still works.
- Don't commit `promo/Konten/Konten 1/.~lock.*.docx#` (LibreOffice lock file while the docx is open).

## 2026-10-08 (c) — Website: Google Search Console "Blocked by robots.txt"  (status: FIXED and verified live; owner validates in Search Console)

- **Root cause:** `www.zykl.app` was a proxied CNAME to `zykl.app`, but the `zykl-app` Worker is bound only to the apex,
  so www had no origin → HTTP 522 → Google treats a 5xx robots.txt as "disallow all" for that host.
- **Owner did in Cloudflare (2026-10-08):** Redirect Rule "Redirect from WWW to root" (`https://www.*` →
  `https://${1}`, 301, preserve query string; the "DNS may not be proxied" warning was a false alarm, the www CNAME is
  proxied) and SSL/TLS → Always Use HTTPS = On.
- **Verified with curl:** `http://zykl.app/` → 301 https; `http://www.zykl.app/terms` → 2 redirects → 200
  `https://zykl.app/terms`; `https://www.zykl.app/robots.txt` → 301 apex; live `/changelog` canonical is its own URL.
- Remaining (owner, Search Console): Validate fix on each issue, resubmit `sitemap.xml`, Request indexing for /changelog.
  Optional: disable the `zykl-app.ricky-yusar-40b.workers.dev` route (duplicate host; canonicals already point to zykl.app).
- **Done (website `c90cca2`, auto-deployed):** `src/app/changelog/layout.tsx` gives /changelog its own canonical (verified
  in the export: `out/changelog.html` → `https://zykl.app/changelog`); `public/sitemap.xml` lastmod per page's last
  commit. `/coming-soon`'s relative canonical already resolves via `metadataBase` (export shows the absolute URL).

Original diagnosis (kept for reference). Owner request 2026-10-08. Search Console (domain property `sc-domain:zykl.app`) reports: Blocked by robots.txt (1),
Indexed though blocked by robots.txt (1), Alternate page with proper canonical tag (1), Discovered – currently not
indexed (4). Findings so far (read-only checks):
- `zykl.app/public/robots.txt` and the live `https://zykl.app/robots.txt` (and `http://`) both say `Allow: /` with the
  sitemap. So the apex host is NOT blocking.
- **`https://www.zykl.app/robots.txt` returns HTTP 522** (Cloudflare: origin connection timed out). Google treats a 5xx
  robots.txt as "disallow all" for that host, so any `www.` URL shows as blocked. Most likely cause of both robots.txt
  rows. Fix in Cloudflare (owner dashboard): either add `www.zykl.app` as a custom domain / route on the `zykl`
  Worker, or add a Redirect Rule `www.zykl.app/*` → `https://zykl.app/${1}` (301), or delete the dangling proxied `www`
  DNS record. Then in Search Console: URL Inspection on the affected URL → "Validate fix".
- `/changelog` has no own canonical, so it inherits `alternates.canonical: "https://zykl.app"` from
  `src/app/layout.tsx:52` → "Alternate page with proper canonical tag". Add `alternates: { canonical:
  "https://zykl.app/changelog" }` (as `terms`, `privacy`, `about` do). `/coming-soon` uses a relative canonical
  (`/coming-soon`); make it absolute or set `robots: { index: false }` if it should not rank.
- `http://zykl.app` serves 200 instead of redirecting to https (enable "Always Use HTTPS" in Cloudflare).
- `public/sitemap.xml`: all `lastmod` are 2026-09-22; update when pages change. "Discovered – currently not indexed"
  (4) is normal for a new site; resubmit the sitemap after the fixes.
- First confirm in Search Console which exact URL is blocked (Pages → Blocked by robots.txt → example URL) before
  changing anything. Website deploys automatically on push (Cloudflare); DNS/rules are dashboard-only.

## 2026-10-08 (b) — Timer notification no longer "Silent"; dependency upgrade  (status: committed `448fbf6`, `328f9ae`; shipped in v1.0.3, see entry (d))

- `TimerForegroundService.kt`: countdown channel was `IMPORTANCE_LOW` (folded into Android's "Silent" section). New
  channel `zykl_timer_countdown` with `IMPORTANCE_DEFAULT`, no sound/vibration/badge; the legacy
  `takt_desk_timer_channel` is deleted on start (Android never lets an app raise an existing channel's importance).
  The notification is `setSilent(true)` + `setOnlyAlertOnce(true)` so per-second updates never alert. Kotlin compiles.
  Device check: start a timer → the countdown appears with normal notifications, silently.
- Dependencies: `sensors_plus` 5.0.1 → **7.1.1** (supports Flutter's built-in Kotlin; the "plugins that apply KGP will
  fail" warning came from it; needs AGP ≥ 8.12.1 / Gradle ≥ 8.13 / Kotlin 2.2, project has AGP 9.0.1 / Gradle 9.1 /
  Kotlin 2.3.20). Sensor events now carry a `timestamp` (tests updated). **Removed `sqlite3_flutter_libs`** (EOL: only
  for `package:sqlite3` v2; we already use sqlite3 3.5.2, which bundles SQLite via build hooks). `drift` 2.35.2 /
  `drift_dev` 2.35.1; regenerated `app_database.g.dart` is byte-identical. Not upgraded on purpose: riverpod 3 (app-wide
  migration), flutter_lints 6. `android.builtInKotlin=false` / `android.newDsl=false` in `gradle.properties` come from
  the Flutter template; leave them to Flutter's own migration.
- Verified: analyze 0, `flutter test -j 1` **458 pass**. Release build not run yet: build the next AAB as **1.0.3+4**
  and check on device that SQLite still opens (existing data intact) and parallax still works.

## 2026-10-08 — v1.0.2: real version label + live DND status, AAB + dev-pro built  (status: built; owner uploads the AAB)

- Owner spotted Settings still said `v1.0.0 (BUILD 1)` on 1.0.1. It was hardcoded in the creed card and the licence
  page (`v1.0.0 (Build 2026.09)`). Now `appVersionLabelProvider` / `UrlService.appVersionLabel()`
  (`lib/core/services/url_service.dart`) reads `versionName` / `versionCode` from the installed package via the existing
  native `getDeviceInfo`; off-device the line shows no version. **Never hardcode the version again**: bump only
  `pubspec.yaml`.
- The Lockdown badge in Settings always said `STATUS: VERIFIED (ANDROID DND / APP PINNING)`. It now reports the real
  DND access: `GRANTED · APP PINNING READY` (olive LED) or `NEEDED · CALLS WILL STILL RING` (ochre LED), rechecked on
  resume (`_DndAccess` builder, shared with the GRANTED / NOT GRANTED label).
- Tests: `test/core/services/app_version_label_test.dart` (2), settings sheet tests mock the
  `com.takt.desk/focus_lock` channel explicitly (an unmocked channel call is timing-dependent in a full file run).
  Full suite **458 pass**, analyze 0.
- Release: `version: 1.0.2+3`, tag **`v1.0.2`** on the fix commit (moved before it was ever pushed). 1.0.1
  (versionCode 2) is live on Closed testing; 1.0.2 is the update. Owner asked for **AAB + developer-pro APK only** (no
  user-testing APK). v1.0.1 outputs archived in `build_outputs/previous/2026-10-07-v1.0.1/`.
- **Built 2026-10-08 07:19–07:27** (`scripts/build_test_apks.sh aab developer-pro`, exit 0):
  `build_outputs/zykl-playstore-release.aab` (65.4 MB; verified by converting the base module with aapt2:
  `com.zykl.app`, versionCode 3, 1.0.2; signed with the upload key `27:5B:8E:D7…`) and
  `zykl-developer-pro-universal.apk` (66.4 MB; `com.zykl.app.devpro`, label ZYKL DEV PRO, debug key `5c83ace3…`).
  Next: owner uploads the AAB to Closed testing → Tester → Create new release.
- Gotcha: `pkill -f` with broad patterns killed the agent's own shell (exit 144) while stopping a build; kill build
  processes by PID instead.

## 2026-10-07 (e) — YouTube channel assets  (status: done; owner uploads)

- `promo/YouTube/`: `ZYKL_YouTube_Banner_2560x1440.png` (1.8 MB; logo, clock avatar and copy inside the 1546×423
  all-devices safe area; dial scales only on the desktop-only sides), `ZYKL_YouTube_Watermark_150.png` (owner choice:
  the ZYKL wordmark from `ZYKL_Wordmark_OnDark_transparent.png`, transparent, soft shadow for light frames, 9 KB) and `ZYKL_YouTube_Watermark_150_Tagline.png`
  (wordmark + "QUIET TIME. PHYSICAL INTENT."; tagline is ~5 px tall at 150 px, unreadable as a player watermark;
  `make_watermark.py tagline`), `DESCRIPTIONS.md` (channel description, links, promo video title/description/
  tags, Play Console video requirements). Regenerate with `make_banner.py [--guides]` and `make_watermark.py`
  (sources: `promo/Logo ZYKL/`). `banner_guides_preview.png` is only a crop-box check.
- `ZYKL_YouTube_Thumbnail_1280x720.jpg` (90 KB) for the promo upload (youtu.be/NiKlyjlACEI, uploaded by the owner):
  phone from the remaster's Lockdown scene at 21.5 s + "Quiet Time. / Physical / Intent.". `make_thumbnail.py [VIDEO] [SECONDS]`.
- YouTube "AI use" for the promo: the music and SFX are ElevenLabs-generated (`zykl.app/promo/scripts/
  generate_zykl_promo_audio_v2.py`); visuals are real app captures + motion graphics. Owner advised: answer "Yes" to be
  transparent (music is AI-created). App soundscapes are separate (real recordings).
- Security: `zykl.app/promo/scripts/generate_zykl_promo_audio{,_v2}.py` had an old ElevenLabs key hardcoded as a
  fallback (git-ignored, never in either repo's history; different from the current key in `11labs.md`). Now
  `os.environ["ELEVENLABS_API_KEY"]` only. Owner: revoke that old key in the ElevenLabs dashboard if still active.
- Channel: handle @zyklnow. Suggested Play promo video: `zykl.app/promo/Video Motion Remaster/
  ZYKL_Promo_Remaster_44s_EN_Dark_16x9.mp4` (public/unlisted, embeddable, no ads, normal watch URL, not Shorts).

## 2026-10-07 (d) — Lockdown: Do Not Disturb pre-flight  (status: committed in v1.0.2)

- Problem (owner): during Monastic Lockdown phone calls still rang. Lockdown = screen pinning (`startLockTask`, no
  device owner, so the user can always leave) + DND `INTERRUPTION_FILTER_NONE`, but DND is applied **only if the user
  granted Notification Policy (DND) access**, and the only way to grant it was a button buried in Settings. Most users
  locked without DND, so calls rang through.
- `lib/features/desk/presentation/widgets/monastic_switch_widget.dart` (now stateful): tapping LOCKDOWN checks
  `isNotificationPolicyAccessGranted`. Granted → lock as before. Not granted → dialog "SILENCE CALLS TOO?" with
  **GRANT ACCESS** (opens Android DND access settings; when the app resumes and access is granted, it locks
  automatically) or **LOCK WITHOUT SILENCE**. Dismiss = no lock. Keys: `lockdown_silence_preflight`,
  `lockdown_grant_dnd`, `lockdown_without_silence`.
- Settings → DND button shows `GRANTED` / `NOT GRANTED` (`_DndAccessStatus`, rechecked on resume; key
  `dnd_access_status`).
- `film_capture/film_scene.dart` `FilmFocusLockService` reports DND granted so demo captures show no dialog.
- Tests: 5 new in `test/features/desk/monastic_switch_test.dart` (granted, without silence, grant → resume locks,
  resume without grant, dismiss). Full suite **455 pass**, analyze 0.
- Device check: with DND access granted, start Lockdown and call the phone: it must not ring. Limits told to the owner:
  pinning cannot fully block other apps without device-owner (kiosk) provisioning; a stronger opt-in "Strict Lockdown"
  would need an AccessibilityService (Play declaration + prominent disclosure). Rejecting calls outright is only
  possible via `CallScreeningService` for numbers NOT in contacts. Not started; owner chose the DND fix first.

## 2026-10-07 (c) — Audit hardening  (status: committed + pushed; website auto-deployed by Cloudflare)

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
8. Replace default `README.md`; commit work by topic; ~~upgrade deps~~ done in v1.0.3 (riverpod 3 and flutter_lints 6 still pending).
9. Note: during this session `chrono_dial_widget.dart` was modified by something other than the agent
   (likely IDE format-on-save); re-run `flutter analyze` after pulling external edits.
