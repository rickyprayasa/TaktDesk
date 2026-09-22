# ZYKL // Android Application Architecture Blueprint
**Codebase: Takt Desk // Android 10 - 15 (API 29 - 35)**
*Engineering Studio: RSQUARE (Established 2023)*
*Package: com.zykl.app*

---

## 1. Ikhtisar Arsitektur (*Architectural Overview*)

ZYKL dibangun menggunakan standar rekayasa modern Android dengan paradigma **Offline-First**, **Unidirectional Data Flow (UDF)**, dan **Clean Architecture**.

```
+-------------------------------------------------------------------------+
|                           PRESENTATION LAYER                            |
|  - Jetpack Compose UI (Material 3 + Custom Industrial Design Tokens)     |
|  - ViewModels (StateFlow, SharedFlow, MVI/UDF Pattern)                 |
|  - Android Home Screen Widgets (AppWidgetProvider + RemoteViews/Glance) |
+------------------------------------+------------------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
|                              DOMAIN LAYER                               |
|  - Pomodoro State Machine (Focus, Break, LongBreak transitions)         |
|  - Task Dispenser Interactors (5-slot cap, archive, ink stamp)         |
|  - Audio Focus & Playback Controller UseCases                           |
|  - License & Purchase Entitlement Validator                             |
+------------------------------------+------------------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
|                               DATA LAYER                                |
|  - Local SQLite Database (Drift / Room Engine)                          |
|  - DataStore Preferences (Theme, Escapement Ticking, Volume Calibration)|
|  - Audio DSP Engine (Android MediaPlayer / SoundPool Foley Engine)      |
|  - Google Play Billing Client v7 (In-App Purchase Security)            |
+------------------------------------+------------------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
|                           BACKGROUND SERVICES                           |
|  - ForegroundService with Ongoing Notification & MediaSessionCompat     |
|  - AlarmManager / Exact Timing WakeLocks for Precise Chronometer       |
+-------------------------------------------------------------------------+
```

---

## 2. Lapisan Presentasi (*Presentation Layer & UI Engine*)

### 2.1 Deklaratif Murni Jetpack Compose
Seluruh antarmuka visual dibangun 100% menggunakan **Jetpack Compose** tanpa XML view layout warisan (kecuali RemoteViews untuk widget layar utama):
- **Custom Design Tokens**: Palet warna (`ChassisTheme`), bentuk geometris (`ChamferCornerShape`, `RivetBorder`), dan tipografi (`JetBrainsMonoFontFamily`) diinjeksi via `CompositionLocalProvider`.
- **Canvas-Driven Analog Dial**: Dial jam dan jarum chronometer dirender langsung pada `androidx.compose.ui.graphics.drawscope.DrawScope`, meminimalkan alokasi objek pada *composition pass* dan menjamin animasi 60–120 FPS tanpa *jank*.
- **State Hoisting & Immobility**: State UI diikat dalam *immutable data class* (`ChronometerUiState`, `TaskDispenserUiState`, `TurntableUiState`), menjamin perilaku deterministik saat rotasi layar atau perubahan konfigurasi.

---

## 3. Mesin Waktu & Chronometer State Machine

### 3.1 Presisi Escapement 1.0 Hz
Aplikasi ini tidak bergantung pada `Thread.sleep` atau `Handler` sederhana yang rentan meleset akibat *CPU throttling* Android:
- Menggunakan `kotlinx.coroutines.flow` dengan basis interval `SystemClock.elapsedRealtime()`.
- Menghitung delta waktu riil (*real elapsed time*) terhadap target *timestamp* akhir, sehingga timer tetap akurat 100% bahkan jika aplikasi masuk ke mode *Doze* atau latar belakang.

### 3.2 Diagram Transisi State Pomodoro
```
       +------------------+
       |       IDLE       |
       +--------+---------+
                | [START_FOCUS]
                v
       +------------------+     [TICK / 25 MIN]     +-------------------+
       |   FOCUS_RUNNING  +------------------------>|  FOCUS_COMPLETED  |
       +--------+---------+                         +---------+---------+
                |                                             |
                | [PAUSE]                                     | [AUTO / MANUAL]
                v                                             v
       +------------------+                         +-------------------+
       |   FOCUS_PAUSED   |                         |   BREAK_RUNNING   |
       +------------------+                         +---------+---------+
                                                              |
                                           [4th CYCLE?]-------+
                                           |                  |
                                     (YES) |                  | (NO)
                                           v                  v
                                  +-----------------+  +----------------+
                                  |   LONG_BREAK    |  |  SHORT_BREAK   |
                                  |    (15 MIN)     |  |    (5 MIN)     |
                                  +-----------------+  +----------------+
```

---

## 4. Mesin Audio DSP & Background Playback Service

### 4.1 Arsitektur Latar Belakang (*Foreground Service & MediaSessionCompat*)
Audio soundscape piringan hitam harus terus berputar tenang saat layar mati atau pengguna membuka aplikasi lain:
- **`AudioService` (Android Foreground Service)**: Menggunakan tipe layanan `android:foregroundServiceType="mediaPlayback"`.
- **`MediaSessionCompat`**: Menghubungkan kontrol audio dengan sistem Android (layar kunci, *notification drawer*, smartwatch, dan headset Bluetooth).
- **Penanganan Audio Focus**: Mengimplementasikan `AudioManager.OnAudioFocusChangeListener`. Saat menerima panggilan telepon atau navigasi GPS, audio soundscape meredup (*ducking*) atau menjeda secara anggun (*graceful pause*).

### 4.2 Mesin Suara Ganda (*Dual Audio Architecture*)
1. **Looping Ambient Master Player**:
   - Memutar file audio master stereo/mono 22.05 kHz / 44.1 kHz.
   - Menggunakan teknik *sinusoidal crossfade* di ujung file untuk menghilangkan bunyi *click/pop* saat loop berulang.
2. **Low-Latency Foley Sound Engine (`SoundPool`)**:
   - Khusus memproses efek suara taktil instrumen:
     - `foley_switch_click.wav`: Suara sakelar fisik *toggle switch*.
     - `foley_dial_click.wav`: Suara putaran knop *crown dial*.
     - `foley_paper_tear.wav`: Suara sobekan kertas dispenser thermal.
   - Diproses langsung di RAM untuk latensi mendekati 0 milidetik.

---

## 5. Subsistem Basis Data Lokal (*Offline SQLite*)

### 5.1 Filosofi Zero-Cloud & Privasi Total
ZYKL tidak memiliki server backend untuk menyimpan data pengguna. Tidak ada API endpoint, tidak ada Firebase Database, dan tidak ada analitik pihak ketiga:
- Semua data disimpan secara lokal pada file basis data SQLite perangkat pengguna.
- Enkripsi dan perlindungan file sistem Android menjamin privasi absolut.

### 5.2 Skema Tabel Utama
1. **`tasks`**:
   - `id` (UUID, Primary Key)
   - `title` (String, Max 120 chars)
   - `is_completed` (Boolean)
   - `created_at` (Timestamp)
   - `completed_at` (Nullable Timestamp)
   - `order_index` (Integer, 0 - 4: membatasi 5 slot aktif)
2. **`pomodoro_sessions`**:
   - `id` (UUID, Primary Key)
   - `session_type` (FOCUS / SHORT_BREAK / LONG_BREAK)
   - `duration_seconds` (Integer)
   - `completed_at` (Timestamp)
3. **`preferences`**:
   - `hardware_edition` (String ID tema)
   - `is_pro_unlocked` (Boolean)
   - `chronometer_ticking_enabled` (Boolean)
   - `master_volume` (Float 0.0 - 1.0)

---

## 6. Subsistem Widget Layar Utama (*Android Home Screen Widgets*)

ZYKL menyediakan widget meja kerja interaktif yang membawa nuansa instrumen langsung ke layar depan ponsel:
1. **Chronometer Widget**:
   - Menampilkan dial jam mekanik.
   - Jarum jam terhubung dengan service timer via broadcast terenkripsi.
   - Update presisi 1.0 Hz saat timer aktif.
2. **Task Dispenser Widget**:
   - Menampilkan daftar 5 tugas aktif dengan tekstur kertas thermal.
   - Mendukung interaksi ceklis langsung dari widget.
   - **Safety Guard Terverifikasi**: Terlindungi dari *intent leak* saat modal upgrade PRO terbuka (mencegah pembuatan task bayangan).

---

## 7. Subsistem Keamanan & Google Play In-App Billing v7

### 7.1 Monetisasi Jujur (*Studio PRO In-App Purchase*)
- **SKU Produk**: `zykl_studio_pro` (Tipe: In-App Product / One-Time Purchase).
- **Protokol Verifikasi**: Menggunakan Google Play Billing Library v7 terbaru.
- **Cache Terenkripsi Lokal**: Status kepemilikan lisensi diverifikasi melalui Google Play Store API saat terhubung ke jaringan, lalu disimpan dalam *EncryptedSharedPreferences* (AES-256 GCM) sehingga pengguna tetap memiliki akses PRO penuh saat perangkat berada dalam mode offline / pesawat (*airplane mode*).
- **Zero Ads SDK**: Seluruh kode sumber bebas dari SDK jaringan periklanan (AdMob, Unity Ads, dll.).

---

## 8. Optimasi Performa & Jejak Memori (*Memory & Battery Footprint*)

- **Kompilasi R8 / ProGuard**: Obfuscation penuh dengan penghapusan metadata yang tidak perlu, menghasilkan ukuran APK yang sangat ramping.
- **Konsumsi Baterai**: Tidak ada wakelock berlebih; saat timer selesai, CPU segera diistirahatkan (*deep sleep*).
- **Zero Leak Canaries**: Siklus hidup objek *disposable* (audio track, bitmap textures, compose state listeners) dibersihkan tuntas saat composable masuk ke `onDispose`.
