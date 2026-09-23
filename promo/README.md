# ZYKL // Promotional Motion Graphic Studio

Suite motion graphic promosi mandiri (*standalone motion reel*) untuk ZYKL Monastic Focus Instrument (Android), dibangun sesuai standar **Bang Motion v1.19.0**.

Folder ini dikhususkan untuk **kebutuhan lokal / video generation** dan tidak dipublikasikan ke static website (`zykl.app`).

---

## 📱 Fitur Studio & Visual Rundown (18.0s // 1920x1080 Full HD 60 FPS)

Video ini menampilkan **mockup smartphone Android titanium nyata** lengkap dengan antarmuka (*UI*) otentik dari aplikasi ZYKL:

1. **00:00 – 04:00 // Analog Chronometer**
   - Layar smartphone menampilkan dial Bauhaus Heritage 1925 berotasi halus.
   - Jarum jam bergerak mekanis 1.0Hz escapement dengan sinkronisasi audio foley klik mekanis.
   - Transisi *crossfade* ke dial Forged Carbon gelap.
2. **04:00 – 08:00 // Thermal Receipt Tasks**
   - Kertas struk kasir fisik keluar secara bertahap dari layar smartphone.
   - Dilengkapi serrated teeth, foley robekan kertas (*paper tear*), dan stempel merah *wet ink* `[DONE]`.
3. **08:00 – 12:00 // Monastic Turntable (Braun TP-1)**
   - Layar smartphone menampilkan pemutar piringan hitam vinyl berputar pada 33⅓ RPM.
   - Jarum tonearm melakukan *tracking* di atas alur vinyl.
   - Animasi LED VU meter / spectrum analyzer mengapung di sisi perangkat disertai backsound *Lo-Fi Rain* otentik.
4. **12:00 – 15:00 // Cryptographic Enclave (100% Offline SQLite)**
   - Badge telemetry keamanan pada layar smartphone yang memverifikasi penyimpanan lokal tanpa akses internet/pelacak.
5. **15:00 – 18:00 // Monolithic Finale & Google Play CTA**
   - Mockup smartphone berdiri berdampingan dengan tipografi besar `ZYKL` serta badge resmi `GET ON GOOGLE PLAY`.

---

## 🚀 Cara Menjalankan Studio & Download Video

### Opsi 1: Melalui Browser (Direkomendasikan)
1. Buka file `promo/index.html` langsung di Google Chrome atau Chromium browser:
   ```bash
   ./promo/open-studio.sh
   # atau buka manual URL: file:///path/to/zykl.app/promo/index.html
   ```
2. Anda dapat melihat animasi secara interaktif atau mengontrol *timeline* dengan keyboard:
   - `Space`: Play / Pause.
   - `R`: Replay dari awal.
   - `0.5x / 1x / 2x`: Mengatur kecepatan playback.
   - Tombol slider untuk *scrubbing* ke detik mana pun.
3. **Mendownload format video (`.webm` / `.mp4`)**:
   - Klik tombol **`[ ⏺ EXPORT VIDEO (.WEBM) ]`** pada toolbar bawah.
   - Pada popup izin browser, pilih **"Tab ini" (This Tab)** dan pastikan opsi **"Bagikan audio sistem / tab"** tercentang.
   - Toolbar kontrol akan otomatis disembunyikan agar rekaman bersih.
   - Studio akan memutar video selama 18 detik dan otomatis mendownload file video berkualitas tinggi (16 Mbps) ke folder unduhan Anda (`zykl_promotional_motion_reel.webm`).

---

## 📸 Paket Aset Promosi Lainnya

### 1. 1:1 Social Carousel Suite (Instagram, Threads, Facebook)
- **Lokasi Folder**: `promo/Social Carousel 1x1/`
- **Interactive Preview & Studio**: `promo/Social Carousel 1x1/preview.html`
- **Format**: 1024 × 1024 px (Square 1:1)
- **7-Slide Narrative Sequence**:
  - `01_Carousel_Cover_Quiet_Intent_1x1.jpg` (Opening Hook & 3D Chronometer perspective)
  - `02_Carousel_Unit01_Chronometer_1x1.jpg` (Unit 01: 1.0 Hz Escapement Dial)
  - `03_Carousel_Unit02_Thermal_Dispenser_1x1.jpg` (Unit 02: Thermal Task Dispenser & `[DONE]` Stamp)
  - `04_Carousel_Unit03_Vinyl_Turntable_1x1.jpg` (Unit 03: 33⅓ RPM Monastic Turntable)
  - `05_Carousel_Materiality_Day_Night_1x1.jpg` (Obsidian & Warm Bone 1976 Dual Materiality)
  - `06_Carousel_Privacy_Local_SQLite_1x1.jpg` (Radical Privacy: 100% Local SQLite & Zero Trackers)
  - `07_Carousel_Closing_PlayStore_CTA_1x1.jpg` (Closing Call-to-Action with Google Play & QR Frame)
- **Fitur Tambahan**: Template caption siap pakai (Bahasa Indonesia & Bahasa Inggris) untuk Instagram, Threads, dan Facebook / LinkedIn.

### 2. Play Store Screenshots & Graphics (Vertical 9:16 & Feature Graphic 16:9)
- **Lokasi Folder**: `promo/PlayStore Promo/`
- **Interactive Comparison**: `promo/PlayStore Promo/preview.html`
- **Pilihan Desain**:
  - `Desain 3/` (Rekomendasi Utama: 3D Studio Mockup dengan lighting dramatis dan presisi tipografi)
  - `Desain 2/` (3D Mockup layout bervariasi)
  - `Desain 1/` (Flat High-Contrast Layout)
  - `01_Feature_Graphic_ZYKL_Revised.jpg` (Banner horizontal 1024 × 500 px rasio 16:9)

