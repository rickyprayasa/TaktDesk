# Product Requirement Document & Technical Architecture: Takt Desk

## 1. Metadata Proyek
* **Nama Proyek**: Takt Desk (The Spatial Pocket Desk)
* **Tipe Aplikasi**: Android Native Utility / Productivity Tool
* **Target Arsitektur**: Flutter (Engine: Impeller) + Rive Runtime
* **Target Minimum SDK**: Android 7.0 (API Level 24)
* **Target Target SDK**: Android 14+ (API Level 34+)
* **Filosofi Desain**: *Industrial Minimalist Tactility* (Analog Braun / Dieter Rams era)

---

## 2. Sistem Desain & Arah Visual

### 2.1 Palet Warna
* **Chassis Obsidian (`#141517`)**: Warna dasar kanvas meja kerja. Mengurangi ketegangan mata dan menghemat konsumsi daya pada layar OLED.
* **Basalt Slate (`#24272C`)**: Warna sasis dan housing perangkat keras instrumen (stopwatch, printer, pemutar piringan).
* **Warm Bone / Raw Paper (`#EFECE6`)**: Kertas struk fisik dengan serat mikro untuk visualisasi daftar tugas.
* **Thermal Carbon (`#1F2226`)**: Warna teks monospaced pada struk kasir, menyerupai hasil cetak termal mekanik.
* **Muted Ochre / Terracotta (`#C85A32`)**: Warna aksen utama untuk elemen interaksi aktif (jarum penunjuk, tombol toggle, status berjalan).
* **Filament Amber (`#D99B59`)**: Indikator lampu status hangat dan efek pencahayaan meja kerja.
* **Patina Olive (`#4D5D4B`)**: Aksen status verifikasi, stempel tugas selesai, dan penyelesaian siklus.

### 2.2 Tipografi
* **UI Utama & Kontrol**: *Space Grotesk* atau *Plus Jakarta Sans* (Weight: 500, 600) — Tipografi proporsional dengan sudut tegas dan keterbacaan tinggi.
* **Teks Data & Mesin Analog**: *JetBrains Mono* atau *Space Mono* (Weight: 400, 700) — Tipografi monospaced untuk counter waktu, teks struk kasir, dan status instrumen.

### 2.3 Umpan Balik Taktil (Haptics & Audio)
* **Rotasi Dial**: `HapticFeedback.selectionClick()` dipicu pada setiap kelipatan 1 menit saat kenop diputar.
* **Sobekan Kertas**: `HapticFeedback.heavyImpact()` saat sobekan struk terlepas dari badan mesin.
* **Audio SFX**: Menggunakan sample suara foley analog nyata (klik pegas pegas mekanik, desis motor stepper termal, sentuhan jarum vinil).

---

## 3. Product Requirement Document (PRD)

### 3.1 Ringkasan Produk
Takt Desk adalah aplikasi fokus dan eksekusi tugas yang memproyeksikan sesi kerja ke dalam meja kerja isometrik 3D minimalis. Tujuannya adalah menghilangkan friksi mental akibat antarmuka daftar teks konvensional melalui interaksi analog digital yang taktil.

### 3.2 Modul Fungsional

#### Modul A: The Chrono Dial (Timer Pomodoro Isometrik)
* **Deskripsi**: Stopwatch mekanis berbentuk dial putar analog.
* **Kebutuhan Fungsional**:
  * Pengguna dapat memutar dial searah jarum jam untuk menentukan durasi kerja (1 hingga 90 menit).
  * Menampilkan hitungan mundur dengan pergerakan jarum kontinu (*smooth sweep motion*, bukan lompatan kaku per detik).
  * Tombol samping mekanis untuk menjeda (*pause*) atau melanjutkan (*resume*) sesi.
  * Ring pencahayaan amber di sekeliling dial menyala redup saat sesi aktif.

#### Modul B: The Thermal Task Runner (Struk Tugas Harian)
* **Deskripsi**: Dispenser mesin cetak struk kasir untuk antrean eksekusi tugas.
* **Kebutuhan Fungsional**:
  * Maksimal 5 tugas aktif per batch kerja untuk mencegah *overwhelmed*.
  * Ketika tugas ditambahkan, struk kertas keluar dari slot mesin disertai animasi bergetar halus dan suara cetak mikro.
  * Fitur *Double Tap* pada tugas untuk mencap stempel tinta basah `[DONE]`.
  * Fitur *Swipe-to-Tear*: Pengguna menggeser jari secara horizontal pada kertas. Begitu threshold 75% robekan tercapai, kertas terlepas dengan partikel serat mikro dan keluar dari layar.

#### Modul C: The Analog Vinyl Deck (Pembangkit Suara Ambience)
* **Deskripsi**: Pemutar piringan hitam sudut meja untuk fokus audio.
* **Kebutuhan Fungsional**:
  * Menyediakan 4 preset audio offline: *Lo-fi Rain*, *Deep Brown Noise*, *Library Atmosphere*, *Cafe Echo*.
  * Tonearm interaktif: Menyeret jarum ke atas piringan hitam akan memicu animasi putaran piringan dan memulai *fade-in* audio.
  * Mengangkat tonearm memicu efek audio *scratch stop* dan menghentikan putaran piringan hitam secara natural.

#### Modul D: Spatial Lighting & Parallax Canvas
* **Deskripsi**: Perspektif isometrik responsif berbasis pergerakan perangkat.
* **Kebutuhan Fungsional**:
  * Menggunakan data giroskop perangkat untuk menggeser sudut pandang kamera sebesar 1–3 derajat secara halus saat perangkat digerakkan.
  * Sumber pencahayaan menyesuaikan waktu lokal perangkat (terang natural pagi/siang, bayangan memanjang sore, lampu pijar meja menyala malam).

### 3.3 Persyaratan Non-Fungsional
* **Frame Rate**: Terkunci 60 FPS pada perangkat kelas menengah (Snapdragon seri 6 / Helio G99) dan 120 FPS pada perangkat dengan refresh rate tinggi.
* **Latensi Audio**: Waktu respons pemutaran audio di bawah 25ms.
* **Efisiensi Daya**: Konsumsi baterai di bawah 4% per 1 jam sesi fokus aktif dengan layar menyala (layar OLED memanfaatkan latar belakang `#141517`).
* **Ukuran Bundle**: Ukuran unduhan APK rilis tidak melebihi 25 MB.

---

## 4. Arsitektur Teknis (Flutter + Rive)

### 4.1 Dependency Stack
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  rive: ^0.13.0
  flutter_soloud: ^2.0.0
  sensors_plus: ^5.0.1
  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1
  path_provider: ^2.1.3

dev_dependencies:
  build_runner: ^2.4.9
  riverpod_generator: ^2.4.0
  isar_generator: ^3.1.0+1