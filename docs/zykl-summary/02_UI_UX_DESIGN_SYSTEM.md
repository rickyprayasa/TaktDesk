# ZYKL // UI/UX Design System & Materiality Guide
**Braun / Dieter Rams Modernism in Modern Software**
*Design Direction: Atelier RSQUARE (Established 2023)*
*Core Tenet: "Weniger, aber besser" (Less, but better)*

---

## 1. Filosofi Desain: Modernisme Fungsionalis

Desain antarmuka ZYKL berakar pada tradisi **Sekolah Desain Bauhaus (Weimar, 1919)** dan **Braun Design Era (1955–1985)** yang dipimpin oleh Dieter Rams dan Dietrich Lubs.

```
       +-------------------------------------------------------------+
       |             10 PRINSIP DIETER RAMS DALAM ZYKL               |
       +-------------------------------------------------------------+
       | 1. Inovatif: Mengubah lempeng kaca smartphone jadi jam meja |
       | 2. Berguna: Mengoptimalkan fungsi fokus & waktu tanpa cela  |
       | 3. Estetis: Proporsi harmoni, tipografi monospace elegan    |
       | 4. Mudah Dipahami: Jarum analog & kertas sobek instuitif    |
       | 5. Rendah Hati: Tidak mencolok, netral sebagai latar kerja  |
       | 6. Jujur: Tidak memanipulasi perhatian dengan notifikasi    |
       | 7. Awet: Estetika abadi, tidak mengikuti tren musiman       |
       | 8. Teliti: Toleransi mikro, baut heksagonal, jarum presisi  |
       | 9. Ramah Lingkungan: Hemat baterai, siklus CPU minimal      |
       | 10. Sedikit Mungkin Desain: "Weniger, aber besser"          |
       +-------------------------------------------------------------+
```

### Penolakan Terhadap *AI-Slop* & Tren Murahan
ZYKL secara tegas menolak:
- **Gradien Ungu/Neon Generik**: Tidak ada warna neon menyilaukan yang melelahkan mata saat bekerja di ruangan gelap.
- **Ilustrasi Korporat Klise**: Tidak ada gambar karakter kartun beranggota badan melar (*corporate Memphis*).
- **Gamifikasi Palsu**: Tidak ada koin digital, confetti animasi meledak-ledak, atau sistem *streak* yang memicu kecemasan neurotik.

---

## 2. Palet Warna & Materialitas (*Color Palette & Materiality*)

Setiap warna dalam ZYKL dipilih berdasarkan analogi material fisik peralatan audio dan instrumen laboratorium Jerman:

```
[ WARM BONE #F4F2EC ]       [ OBSIDIAN #121316 ]       [ BASALT #24272C ]
Plat sasis Braun LE1        Bodi hitam matte anodized  Struktur sasis tebal

[ FILAMENT AMBER #FF9E00 ]  [ RAW BRASS #C89B3C ]      [ WET INK #A82B2B ]
Lampu filamen indikator     Pin poros & aksen kuningan Cap stempel selesai
```

### Spesifikasi Token Warna
| Token | Nilai Hex | Penggunaan & Materialitas |
|:---|:---|:---|
| `chassis-bg-light` | `#F4F2EC` | **Warm Bone**: Permukaan sasis terang, tekstur matte tanpa silau |
| `chassis-bg-dark` | `#121316` | **Obsidian**: Pelat sasis gelap, mengisolasi konsentrasi |
| `chassis-plate` | `#24272C` | **Basalt**: Pelat penutup komponen, pembatas modul instrumen |
| `accent-amber` | `#FF9E00` | **Filament Amber**: Jarum penunjuk waktu, status aktif, audio running |
| `accent-brass` | `#C89B3C` | **Raw Brass**: Baut heksagonal, label katalog frekuensi, knurling |
| `thermal-carbon` | `#1A1A1A` | **Carbon Black**: Teks termal pada cetakan kertas dispenser |
| `stamp-done` | `#A82B2B` | **Red Ink Stamp**: Tinta cap basah untuk tugas yang telah dituntaskan |
| `monastic-muted` | `#8F96A3` | **Subtle Telemetry**: Teks sekunder, pembagi frekuensi audio |

---

## 3. Tipografi & Skala Telemetri (*Industrial Typography*)

ZYKL menggunakan keluarga huruf **JetBrains Mono** dan **Space Mono** untuk memberikan kesan instrumen pengukuran ilmiah yang presisi:

> Catatan (2026-10-07): **website** zykl.app memakai JetBrains Mono. **Aplikasi Android** tidak membundel font; ia memakai keluarga sistem `monospace` (Noto Sans Mono) dan `sans-serif`. Skala `text-*` di bawah adalah kelas Tailwind website.

### Hirarki Tipografi
1. **Headline Instrumen (`text-3xl` s/d `text-5xl`)**:
   - `font-mono font-black uppercase tracking-tight`
   - Digunakan untuk nama modul: `ZYKL`, `CHRONOMETER`, `TURNTABLE`.
2. **Sub-Modul & Status Bar (`text-xs` s/d `text-sm`)**:
   - `font-mono font-bold tracking-widest text-[#C89B3C]`
   - Format: `[ UNIT 01 // ANALOG CHRONOMETER ]`, `[ STATUS: NOMINAL ]`.
3. **Telemetri & Catatan Kaki (`text-[10px]` s/d `text-xs`)**:
   - `font-mono tracking-wider text-monastic-muted`
   - Format: `OFFLINE SQLITE · 22.05kHz DSP · ZERO TRACKERS`.

---

## 4. Skeuomorfisme Taktil Terukur (*Tactile Skeuomorphism*)

Bukan skeuomorfisme berlebihan era 2010, melainkan **skeuomorfisme fungsional** yang memberikan *tactile affordance* (kejelasan fungsi fisik):

```
       +------------------------------------------------------+
       |         ANATOMI KOMPONEN TAKTIL ZYKL                 |
       +------------------------------------------------------+
       | (•) Baut Allen Hexagonal di setiap sudut plat modul  |
       |  |  Sasis bertekstur knurled chamfer 45 derajat      |
       | [M] Tombol rocker switch dengan micro-elevation      |
       |  ~  Gigi sobekan kertas dispenser termal (serrated)  |
       | / / Cap stempel tinta merah miring -12 derajat       |
       |  O  Poros piringan kuningan & tonearm vinyl Braun    |
       +------------------------------------------------------+
```

### Karakteristik Komponen
1. **Rivet Plaque (Pelat Baut Heksagonal)**:
   - Setiap modul dibingkai oleh garis tegas dengan 4 baut kecil di sudut-sudutnya.
   - Mengkomunikasikan bahwa instrumen ini dirakit secara modular dan kokoh.
2. **Serrated Paper Physics (Gigi Sobekan Dispenser)**:
   - Tepian kertas tugas memiliki potongan gerigi tajam ala struk kasir mekanis.
   - Saat tugas ditarik atau diselesaikan, animasi sobekan kertas memberikan rasa lega kognitif yang nyata.
3. **Mechanical Escapement Needle (Jarum Mekanik)**:
   - Jarum jam tidak bergerak linier tanpa nyawa, melainkan memiliki hentakan mikro (*quartic bounce and settle*) di setiap detik, meniru kerja roda jangkar jam Swiss/Jerman.

---

## 5. Ergonomi Kognitif & Jarak Pandang Meja Kerja (*Desk Stand Ergonomics*)

Aplikasi ZYKL dirancang khusus untuk diletakkan di atas meja kerja menggunakan penyangga ponsel (*phone stand*):
- **Jarak Baca Optimal**: Kontras warna dan ukuran font dioptimalkan agar dapat terbaca jelas dari jarak **60–90 cm** tanpa perlu mengangkat ponsel.
- **Pencegah *Screen Burn-In***: Elemen statis memiliki pergeseran mikro per sekian menit saat berada dalam mode fokus panjang.
- **Zero Interruption Interface**: Tidak ada banner promo, tidak ada *in-app notifications*, tidak ada interupsi modal saat sesi fokus sedang berjalan. Layar menjadi oasis ketenangan visual.
