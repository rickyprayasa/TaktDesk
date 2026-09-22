# ZYKL // Web Architecture & Interactive Design Blueprint
**Official Web Domain: https://zykl.app**
*Repository: Android/zykl.app // Next.js 15 SSG*
*Engineering Studio: RSQUARE (Established 2023)*

---

## 1. Ikhtisar Arsitektur Web (*Web Architecture Overview*)

Website `zykl.app` bukan sekadar *landing page* promosi biasa, melainkan **etalase instrumen digital interaktif** (*interactive hardware exhibition*) yang memungkinkan calon pengguna menguji langsung rasa fisik instrumen ZYKL di browser mereka.

```
+-------------------------------------------------------------------------+
|                        ZYKL.APP STATIC RUNTIME                          |
|  - Next.js 15 (App Router) with Full Static Site Generation (SSG)       |
|  - Zero Node.js Server Overhead (output: 'export' -> pure static out/)  |
|  - Global Edge CDN Deployment (Cloudflare Pages / Vercel Edge)          |
+------------------------------------+------------------------------------+
                                     |
    +--------------------------------+--------------------------------+
    |                                |                                |
    v                                v                                v
+-----------------------+  +-----------------------+  +-----------------------+
|  3D WEBGL INSTRUMENTS |  |  IN-BROWSER AUDIO DSP |  |  FEEDBACK TERMINAL    |
|  - React Three Fiber  |  |  - HTML5 Audio Engine |  |  - Thermal Paper Form |
|  - Procedural Dial    |  |  - 16-Band VU Meter   |  |  - Foley Paper Tear   |
|  - Braun TP-1 Platter |  |  - 8 Free Auditions   |  |  - Google Apps Script |
+-----------------------+  +-----------------------+  +-----------------------+
```

---

## 2. Model 3D WebGL Prosedural (*Interactive 3D Hardware Canvas*)

### 2.1 Chronometer Dial 3D (`ChronometerMesh.tsx` & `ChronometerCanvas.tsx`)
- **Geometri Prosedural Murni**: Tanpa mengunduh file `.gltf` / `.obj` berat yang memperlambat *First Contentful Paint* (FCP). Semua bodi, cincin sasis, dan jarum jam dibuat dengan geometri matematika murni Three.js:
  - Bodi silinder aluminium gelap berusuk halus (`metalness: 0.85, roughness: 0.25`).
  - 60 penanda skala radial (12 penanda kuadran tebal kuningan, 48 penanda minor baja).
  - Poros tengah kuningan poles *Raw Brass* (`#C89B3C`).
- **Kinematika Jarum Detik**:
  - Berdetik 1 kali per detik dengan fungsi pelemasan quartic (*bounce and settle*), mensimulasikan mekanisme *escapement* jam mekanis kelas atas.
- **Parallax Mengikuti Kursor**:
  - Menggunakan interpolasi `MathUtils.lerp` pada koordinat pointer mouse untuk memberikan efek kemiringan 3D yang halus dan berbobot saat kursor digerakkan di atas dial.

### 2.2 Braun TP-1 Monastic Turntable 3D (`VinylMesh.tsx` & `VinylCanvas.tsx`)
- **Piringan Hitam Beralur**: Piringan vinil hitam gelap dengan alur mikroskopis konsentris yang membiaskan cahaya studio.
- **Dinamika Putaran 33⅓ RPM**:
  - Saat tombol *Play* ditekan, piringan berakselerasi mulus hingga mencapai kecepatan konstan 33⅓ putaran per menit (`delta * (33.333 / 60) * Math.PI * 2`).
  - Saat dihentikan, piringan mengalami deselerasi fisik bertahap hingga berhenti total.
- **Gerakan Tonearm**:
  - Jarum pemutar turun perlahan ke atas piringan saat musik berputar dan terangkat ke posisi parkir saat audio dihentikan.

---

## 3. Mesin Audio Browser & Spectrum Analyzer Terisolasi

### 3.1 Proteksi Track Audio PRO
- **8 Track Free Audition**: Pengunjung web dapat mendengarkan 8 rekaman sampel berkualitas tinggi secara gratis langsung di browser.
- **12 Master PRO Terproteksi**: File audio dari 12 track edisi Studio PRO tidak diunggah ke server web untuk menjaga rasa penasaran dan nilai eksklusivitas pengguna yang membeli aplikasi ZYKL di Android.

### 3.2 Isolasi Loop Animasi VU Meter (`SpectrumAnalyzer.tsx`)
- Untuk mencegah render ulang 60 FPS pada komponen utama yang membebani CPU, visualisator spektrum frekuensi 16-band diekstrak ke dalam subkomponen terisolasi.
- Menggunakan `requestAnimationFrame` mandiri dengan *ref time-progression* tanpa memicu *re-render* pada pohon DOM kontainer 3D.

---

## 4. Terminal Umpan Balik Kertas Termal (*Feedback Terminal*)

Bagian kontak dan saran pengguna tidak menggunakan form kontak web biasa, melainkan dirancang menyerupai **mesin cetak thermal receipt**:
- **Tepian Gerigi Tajam**: Desain atas kertas memiliki gerigi sobekan mekanis (*serrated zigzag teeth*).
- **Efek Cetak & Suara Taktil**:
  - Saat formulir dikirim, audio sobekan kertas (`foley_paper_tear.wav`) diputar.
  - Cap stempel tinta merah `[TRANSMITTED]` muncul miring di atas struk.
- **Integrasi Serverless Google Apps Script**:
  - Data saran pengguna dikirim langsung ke Google Sheets pemilik studio via Webhook Apps Script gratis tanpa memerlukan database server berbayar.
  - Jika koneksi offline, sistem secara otomatis menyimpan draf ke `localStorage` browser (*offline spooling fallback*).

---

## 5. Halaman Provenance & Colophon (`/about`)

Halaman `/about` ("The Atelier // Colophon & Genesis") menyajikan esai mendalam mengenai latar belakang ZYKL:
- **Chapter 01 // The Distraction Trap**: Analisis tentang bahaya kecanduan gadget dan hilangnya kemampuan fokus mendalam.
- **Chapter 02 // Crafted by RSQUARE (Est. 2023)**: Profil studio RSQUARE sebagai atelier digital independen yang memegang teguh integritas pengerjaan software tanpa investor spekulatif.
- **Chapter 03 // The Anti-Anxiety Hard Cap**: Penjelasan ilmiah di balik pembatasan maksimal 5 tugas (Miller's Law) untuk memangkas kecemasan to-do list.
- **Chapter 04 // Dieter Rams & The Braun Lineage**: Penghormatan terhadap sejarah desain modernis Jerman.

---

## 6. Optimasi SEO & Performa (*Core Web Vitals*)

1. **Static Site Generation (SSG)**: Seluruh rute (`/`, `/about`, `/changelog`, `/privacy`, `/terms`) dikompilasi menjadi berkas HTML statis murni di folder `out/`.
2. **Metadata & OpenGraph**: Mendukung kartu pratinjau sosial lengkap di WhatsApp, Twitter/X, LinkedIn, dan Telegram.
3. **Structured Data (JSON-LD)**: Menyertakan skema resmi Google untuk `SoftwareApplication`, `Offer` (Free Core & Studio PRO Rp 69.000), `AggregateRating`, dan profil organisasi `RSQUARE`.
4. **Sitemap & Robots**: `sitemap.xml` dinamis dan `robots.txt` ramah mesin perayap (Googlebot, Bingbot).
