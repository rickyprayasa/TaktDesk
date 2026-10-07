# ZYKL // Arsitektur Aplikasi Android
**Codebase: `Takt Desk` (nama folder lama) · Package `com.zykl.app` · v1.0.0 (versionCode 1)**
*Studio: RSQUARE*

> Ditulis ulang 2026-10-07 dari kode yang sebenarnya. Versi sebelumnya menyebut Kotlin Jetpack Compose,
> Room, Billing v7, EncryptedSharedPreferences dan SKU `zykl_studio_pro`; **semua itu tidak pernah ada di kode.**
> Kalau dokumen ini bertentangan dengan kode, kode yang benar. Riwayat kerja terbaru: `docs/handoff/HANDOFF.md`.

---

## 1. Stack

| Lapisan | Teknologi |
|:---|:---|
| UI & logika | **Flutter / Dart** (SDK ≥ 3.2; dibangun dengan Flutter 3.44), Material + `CustomPainter` |
| State | **Riverpod 2** (`StateNotifierProvider`, `StreamProvider`) |
| Database | **Drift** (SQLite lokal, `sqlite3_flutter_libs`), schema **v8** |
| Pembelian | **`in_app_purchase`** (Google Play Billing Library 8.0.0), produk `studio_pro_lifetime` |
| Sensor | `sensors_plus` (efek parallax meja) |
| Waktu | `clock` (bisa dipalsukan di test dan film capture) |
| Native Android | **Kotlin** di `android/app/src/main/kotlin/com/zykl/app/` (service, notifikasi, widget, audio) |
| Target | minSdk **24** (Android 7.0), targetSdk **36** |

Nama paket Dart masih `takt_desk` dan MethodChannel masih `com.takt.desk/*`. **Jangan di-rename**: ini
dipakai bersama oleh Dart dan Kotlin.

---

## 2. Struktur folder `lib/`

```
lib/
├─ main.dart                      ProviderScope + opening screen
├─ app/theme/                     12 HardwareEdition, TaktColors (amberText untuk kontras), tekstur, plakat
├─ core/
│  ├─ audio/                      AudioService (Dart → MethodChannel audio), SoundEffect (foley)
│  ├─ billing/                    ProStore (seam) + PlayProStore, proPurchaseProvider
│  ├─ config/                     AppSecurityConfig (flag PRO simulation / dev tools)
│  ├─ database/                   AppDatabase (Drift) + tables/
│  ├─ focus/                      Monastic Lockdown (DND + screen pinning)
│  ├─ haptics/, sensors/          haptic + parallax
│  └─ services/                   timer_background, app_widget, media_notification, url
└─ features/
   ├─ opening/                    animasi pembuka 4,2 s (reduced-motion = statis)
   ├─ desk/                       DeskCanvasScreen (layar utama), spec plate, telemetry, layout landscape
   ├─ timer/                      ChronoDialController (state machine), dial painter, crown, split-flap
   ├─ chrono/                     re-export lama dari timer (1 baris)
   ├─ tasks/                      thermal dispenser (maks. 5 task), stempel DONE, laci arsip
   ├─ vinyl/                      20 soundscape, turntable, laci record
   ├─ vumeter/                    VU meter analog
   ├─ analytics/                  FocusAnalyticsDialog, focus_session_rules.dart (aturan tunggal statistik)
   └─ settings/                   settings sheet (+ part files settings_sections/), Studio PRO dialog
```

Pola umum: `domain/` = model murni, `presentation/` = controller (StateNotifier) + widget + painter.
Tidak ada lapisan repository terpisah; controller membaca/menulis `AppDatabase` langsung.

---

## 3. Timer (Unit 01)

- **`ChronoDialController`** (`features/timer/presentation/chrono_dial_controller.dart`) memegang fase
  (focus / short break / long break), siklus, dan sisa waktu. Profil: CLASSIC 25/5/15, MONASTIC 50/10/30,
  SPRINT 15/3/10, plus CUSTOM (fokus 1–90 menit, diatur lewat tarik crown atau Pomodoro Interval Engine).
- Waktu dihitung dari **wall-clock** (`clock.now()`), bukan stopwatch, supaya bisa mengejar setelah deep
  sleep. Delta negatif (jam mundur) di-clamp ke 0.
- Saat app kembali ke foreground, `resyncWithNative()` mencocokkan sisa waktu dengan service native
  (`getRemainingMillis`), termasuk kasus native sudah selesai (fase dimajukan tanpa bunyi ganda).
- Sesi yang dibatalkan setelah ≥ 60 detik fokus dicatat sebagai `isFinished = false`.

### Native: `TimerForegroundService.kt`
- Foreground service tipe **`specialUse`** dengan notifikasi countdown (channel `IMPORTANCE_LOW`) dan channel
  alert terpisah (`IMPORTANCE_HIGH`).
- Akhir sesi dijadwalkan dengan **`AlarmManager.setExactAndAllowWhileIdle(ELAPSED_REALTIME_WAKEUP)`**
  (kebal perubahan jam, jalan saat Doze); fallback `setAndAllowWhileIdle` bila exact alarm ditolak.
  Permission: `USE_EXACT_ALARM` (API 33+), `SCHEDULE_EXACT_ALARM` (≤ 32).
- Penyelesaian idempotent (`lastCompletedEndAt`). Kalau Dart sudah mati, sesi selesai disimpan di
  SharedPreferences `zykl_pending_sessions` lalu diimpor Dart lewat `takePendingSessions`.
- `POST_NOTIFICATIONS` diminta sekali, saat START pertama (bukan saat launch).

---

## 4. Task dispenser (Unit 02)

- `ReceiptRunnerController` + `receipt_runner_widget.dart`: maksimal **5 task aktif**, judul 1–140 karakter.
- Selesai = stempel DONE; task selesai bisa diarsipkan (`isArchived`), tidak dihapus.
- Error DB dicatat lewat `debugPrint` (`_logDbError`), tanpa retry.

---

## 5. Audio (Unit 03 + foley)

| Jenis | Format | Pemutar native |
|:---|:---|:---|
| 20 soundscape vinyl (`assets/audio/vinyl_*.ogg`, 22,05 kHz mono, loop 40 s) | Ogg Vorbis q4 | `MediaPlayer` (looping) di `MediaNotificationService` |
| Alarm chime (5: Twin-Hammer Bell, Brass Desk Bell, Tibetan Singing Bowl, Zen Temple Gong, Tubular Chime) | WAV | Alarm nyata: `MediaPlayer` `USAGE_ALARM`; preview: `SoundPool` |
| Foley UI (`foley_*.wav`) | WAV | `EffectSoundPlayer` (`SoundPool`, latensi rendah) |

- `MediaNotificationService.kt`: foreground service **`mediaPlayback`**, MediaSession + notifikasi media
  (prev / play-pause / next), audio focus listener.
- Sumber lossless ada di `assets_src/audio_wav/` (tidak di-bundle). Script generator di `scripts/`.
- **Menambah chime baru** harus di tiga tempat: `MainActivity` (`ALARM_ASSETS`),
  `lib/features/timer/domain/alarm_chime.dart`, dan `TimerForegroundService.getAlarmAssetPath`.

---

## 6. Database (Drift, schema v8)

| Tabel | Kolom penting |
|:---|:---|
| `tasks` | `id` (int auto), `title` (1–140), `isCompleted`, `isArchived`, `sortOrder`, `createdAt`, `completedAt?` |
| `timer_sessions` | `id`, `targetMinutes`, `elapsedSeconds`, `isFinished`, `startedAt`, `finishedAt?`, `isLockdownOnly` (v8) |
| `desk_preferences` | `soundVolume`, `parallaxEnabled`, `activeAmbientTrackIndex`, `foleyEnabled`, `hapticsEnabled`, `selectedEdition`, `isProSimulated`, `alarmChimeId`, `autoUnlockMonastic`, `isDarkMode`, `dailyGoalCycles` (v8) |

- Semua statistik (analytics, plate TODAY, lifetime) memakai satu aturan:
  `features/analytics/domain/focus_session_rules.dart`. **Pakai file ini untuk statistik baru.**
- Setelah mengubah tabel: naikkan `schemaVersion`, tambah migrasi `from < N`, jalankan `build_runner`.
- ID tersimpan seperti `braunClassic` dan `braunBell` ada di data pengguna; jangan di-rename.

---

## 7. Studio PRO & billing

- Produk Play: **`studio_pro_lifetime`** (one-time, Rp 69.000 harga peluncuran). ID tidak boleh diganti.
- `proPurchaseProvider` (`core/billing/pro_purchase_controller.dart`): state unavailable / idle / purchasing /
  pending / owned. Saat start memanggil `restorePurchases()`; `purchased`/`restored` → PRO terbuka; setiap
  pembelian di-acknowledge (`completePurchase`), kalau tidak Google refund otomatis dalam 3 hari.
- **Kepemilikan tidak pernah dibaca dari DB di build release**: `settings_controller.dart` memaksa
  `effectivePro = false` saat load kecuali simulation aktif, lalu Play restore yang membukanya.
  (Nama `isProSimulated` adalah nama lama untuk "PRO terbuka".)
- `AppSecurityConfig`: `isProSimulationEnabled` hanya untuk APK developer-pro
  (`--dart-define=ENABLE_PRO_SIMULATION=true`). Di build debug/simulation, `proStoreProvider` = null
  sehingga test tidak pernah menyentuh Play. `FILM_HIDE_DEV_TOOLS` menyembunyikan dev tools saat film capture.
- Gratis: 4 edisi, 8 soundscape, semua widget, Monastic Lockdown. PRO: 8 edisi + 12 soundscape lainnya,
  plus semua tambahan di update berikutnya tanpa biaya.

---

## 8. Monastic Lockdown

`core/focus/`: `FocusLockController` + `FocusLockService` → MethodChannel `com.takt.desk/focus_lock` →
`MainActivity` menyalakan DND (`INTERRUPTION_FILTER_NONE`, perlu `ACCESS_NOTIFICATION_POLICY`) dan
`startLockTask()` (screen pinning). Lock hanya mencatat sesi sendiri bila tidak ada timer yang berjalan,
durasinya ≥ 60 s, dan diberi `isLockdownOnly = true` (mencegah hitungan ganda).

---

## 9. Widget layar utama

Empat `AppWidgetProvider` (RemoteViews), info XML di `res/xml/`:
`TaktAppWidgetProvider`, `TaktAnalogDialWidgetProvider`, `TaktFocusStripWidgetProvider`,
`TaktTaskDispenserWidgetProvider`. Aksi dari widget (toggle timer, centang task) lewat
`WidgetActionReceiver`; Dart menyinkronkan data lewat `com.takt.desk/app_widget` (`appWidgetSyncProvider`).

---

## 10. MethodChannel

| Channel | Arah / fungsi |
|:---|:---|
| `com.takt.desk/timer_service` | start/stop service, `getRemainingMillis`, `takePendingSessions` |
| `com.takt.desk/audio` | soundscape, foley, alarm/preview chime, volume |
| `com.takt.desk/focus_lock` | DND + screen pinning |
| `com.takt.desk/app_widget` | sinkronisasi data widget |
| `com.zykl.app/media_notification` | notifikasi media vinyl |

---

## 11. Aksesibilitas & tema

- Reduce motion (`MediaQuery.disableAnimations`): platter tidak berputar, parallax mati, opening statis.
- Kontras WCAG AA dipaksa oleh `test/app/theme/contrast_test.dart` untuk 12 edisi × terang/gelap.
  Teks amber memakai `TaktColors.amberText(isDark)`.
- Font: keluarga sistem `monospace` (Noto Sans Mono di Android) dan `sans-serif`; tidak ada font bundel.

---

## 12. Verifikasi & build

- `flutter analyze` → 0 issues; `flutter test -j 1` (jalankan per folder di mesin 7,6 GB).
- Kotlin: `cd android && ./gradlew :app:compileDebugKotlin --offline -q`.
- Build hanya atas permintaan owner, selalu lewat `scripts/build_test_apks.sh [developer-pro] [user-testing] [aab]`
  (cgroup, satu per satu). Test APK = universal, jangan `--split-per-abi`. Detail di `HANDOFF.md`.
- Setiap upload ke Play wajib menaikkan `version:` di `pubspec.yaml` (mis. `1.0.1+2`).
- Film/promo capture dari widget asli: `film_capture/` (di luar `test/`).
