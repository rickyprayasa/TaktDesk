# ZYKL // MOTION GRAPHIC PRODUCTION CANVAS
**Project:** Cinematic Product Launch Film (40s)  
**Client / Studio:** RSQUARE Atelier  
**Philosophy:** Dieter Rams & Braun Modernism (*"Weniger, aber besser"*)  
**Deliverables:** Master 4K UHD (16:9, 3840×2160, 24fps) & Vertical Cutdown (9:16, 1080×1920)

---

## 1. ART DIRECTION & CINEMATOGRAPHY CANVAS

```
+---------------------------------------------------------------------------------------------------+
| PALET WARNA UTAMA                                                                                 |
| [ #E6E1D8 ] Warm Bone 1976        | Dasar sasis, dial instrumen, tekstur kertas mati              |
| [ #1A1A1A ] Obsidian Anodized     | Kontras bodi sasis, tipografi monospace, bayangan terkontrol  |
| [ #E05338 ] Braun Red / Stamp     | Jarum aksen, stempel tinta basah [DONE], status rekaman       |
| [ #C5A059 ] Raw Brass / Filament  | Refleksi rim light, tonearm turntable, aksen logam hangat     |
+---------------------------------------------------------------------------------------------------+
| OPTIK & KAMERA 3D                                                                                 |
| - Focal Length: 85mm (Hero shots & UI Macro), 50mm (Desk setup environment)                       |
| - Depth of Field: f/2.0 – f/2.8 (Ultra-shallow, focal distance terkunci pada bevel aset)         |
| - Shutter Angle: 180° (Standar gerak sinema natural untuk motion blur terkontrol)                 |
| - Lensa Tambahan: 1.5% Barrel Distortion subtil + 0.8% Edge Chromatic Aberration                 |
+---------------------------------------------------------------------------------------------------+
| PENCAHAYAAN (LIGHTING RIG)                                                                        |
| - Key Light: Large Octabox lembut 45° atas-kiri (Color Temp: 4500K Neutral Warm)                  |
| - Fill Light: Negative fill di sisi kanan untuk mempertahankan bayangan tegas material            |
| - Rim / Kicker: High-specular strip light dari belakang (Color Temp: 3200K Brass Amber)           |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. PRODUCTION CANVAS MATRIX (DETIK DEMI DETIK)

### SCENE 01: THE DISTRACTION TRAP (00:00 – 00:06)
*Metafora kekacauan digital modern sebelum masuk ke ketenangan ZYKL.*

* **Framing & Kamera:**
  * *Shot:* Extreme Close-Up (ECU) makro miring 30°.
  * *Lensa:* 85mm Macro, DoF sangat tipis (f/1.8).
  * *Gerakan Kamera:* *Push-in* agresif menuju permukaan kaca smartphone yang memantulkan tumpukan badge notifikasi merah.
* **Aset & Lapisan Visual:**
  * Lempengan kaca ponsel dengan pantulan kotor, lapisan grafis tumpukan list tugas dan pop-up merah bergetar mikro (shake ekspresi 12 Hz).
  * Pada detik 00:03.12, terjadi *sudden power cut*: seluruh notifikasi tersedot ke satu garis horizontal dan padam total menjadi hitam pekat.
* **Kurva Gerak (Graph Editor):**
  * Getaran: `wiggle(14, 6)` pada posisi UI.
  * *Blackout Transition:* Linear drop ke 0 opacity dalam rentang 2 frame.
* **Tipografi On-Screen:**
  * Teks: *"Taming the glass slab."*
  * Posisi: Tengah layar bawah.
  * Style: Akzidenz-Grotesk / Helvetica Neue Medium, Kerning +120, Warna: `#8C8C8C`.
* **Voiceover:**
  * *(00:00 – 00:03)*: *"Ponsel Anda dirancang untuk mencuri perhatian."*
  * *(00:03 – 00:06)*: *(Jeda hening)* *"Kini saatnya mengembalikannya."*
* **Desain Suara & Musik:**
  * Layer 1: Dengung frekuensi tinggi (7 kHz digital whine) bercampur puluhan getaran haptik ponsel simultan.
  * Layer 2 (00:03.12): **Sub-bass vacuum implosion drop** (-18 dB RMS drop instan), menyisakan ruang hening total.

---

### SCENE 02: UNIT 01 // MONASTIC CHRONOMETER (00:06 – 00:13)
*Pengenalan instrumen mekanis pertama: siklus fokus berdetak presisi.*

* **Framing & Kamera:**
  * *Shot:* Medium Close-Up (MCU), sudut isometrik 45°.
  * *Lensa:* 85mm Cinema Prime.
  * *Gerakan Kamera:* *Slow orbit sweep* 15° mengelilingi dial sasis *Warm Bone 1976*, rim light menyapu bevel jarum logam.
* **Aset & Lapisan Visual:**
  * Sasis tekstur matte berpori halus.
  * Dial analog putih krem dengan indeks menit tercetak timbul (*engraved deboss*).
  * Jarum detik merah khas Braun dengan bobot counterweight di pangkalnya.
  * Telemetri monospace industri: `25:00 // FOCUS RUNNING`.
* **Kurva Gerak (Graph Editor):**
  * *Escapement Motion 1.0 Hz:* Pergerakan jarum berputar 6° per detik.
  * Profil: 0 – 3 frame (Akselerasi tajam, Speed Peak 450°/s) $\rightarrow$ 3 – 5 frame (Overshoot +0.4°) $\rightarrow$ 5 – 7 frame (Damped recoil settling ke titik presisi).
* **Tipografi On-Screen:**
  * Teks: `UNIT 01 // ANALOG CHRONOMETER`  
    `SPRING-DAMPED ESCAPEMENT // 1.0 HZ`
  * Style: IBM Plex Mono Bold, Upper-case, tracking +80.
* **Voiceover:**
  * *(00:06 – 00:12)*: *"ZYKL. Mengubah lempengan kaca menjadi instrumen meja yang tenang."*
* **Desain Suara & Musik:**
  * Detak escapement mekanik berat (*solid mechanical escapement tick*) berulang tiap 1.000 detik.
  * Musik latar: Akor awal synth bass analog hangat (warm Moog sub-pad) masuk sangat perlahan pada volume -24 dB.

---

### SCENE 03: UNIT 02 // THERMAL TASK DISPENSER (00:13 – 00:21)
*Demonstrasi batas Miller's Law 5 tugas fisik dan kepuasan stempel penyelesaian.*

* **Framing & Kamera:**
  * *Shot:* Top-Down Orthographic View (sudut pandang 90° tegak lurus meja kerja).
  * *Lensa:* 50mm Standard.
  * *Gerakan Kamera:* Bertahan stabil (*locked-off shot*), dengan sedikit getaran mikroskopis saat stempel menghantam.
* **Aset & Lapisan Visual:**
  * Celah dispenser logam perak nikel.
  * Kertas termal putih pudar dengan pinggiran gerigi (*perforated zigzag edges*) keluar secara vertikal.
  * Tertulis 5 slot tugas dalam tipografi typewriter monokrom.
  * Stempel balok kayu dengan karet stempel merah tua `[DONE]` menghantam tepat di atas task slot 01 dengan rotasi miring -12°.
* **Kurva Gerak (Graph Editor):**
  * *Kertas Meluncur:* Kurva deselerasi eksponensial (Speed graph: 90% influence out, durasi 18 frame).
  * *Hantaman Stempel:* Skala 140% $\rightarrow$ 100% dalam 4 frame (Fast drop), tanpa bantalan *ease-in*, menciptakan benturan kaku (*hard stop contact*).
* **Tipografi On-Screen:**
  * Teks: `UNIT 02 // PHYSICAL DISPENSER`  
    `MILLER'S LAW: MAX 5 TASKS // ZERO GUILT`
  * Style: Monospace dengan kotak bounding box teknis tipis.
* **Voiceover:**
  * *(00:13 – 00:17)*: *"Batas tegas lima tugas esensial."*
  * *(00:17 – 00:21)*: *"Saring yang penting, selesaikan tanpa kecemasan."*
* **Desain Suara & Musik:**
  * Suara gesekan kertas keluar: *Zzzzrt-clack* bertekstur kasar.
  * Suara stempel: Hantaman ganda—benturan kayu berbobot (*dense wood clunk*) disusul basahnya lapisan tinta mikro.

---

### SCENE 04: UNIT 03 // 33⅓ RPM TURNTABLE (00:21 – 00:29)
*Atmosfer audio akustik offline berbasis pemutar vinyl minimalis Braun TP-1.*

* **Framing & Kamera:**
  * *Shot:* Low-angle 20° mengarah ke tonearm dan piringan hitam.
  * *Lensa:* 85mm Prime, pencahayaan moody warm amber.
  * *Gerakan Kamera:* *Camera pan* horizontal halus dari tonearm menuju alur piringan yang sedang berputar.
* **Aset & Lapisan Visual:**
  * Piringan vinyl mini 7-inci dengan alur mikro memantulkan cahaya specular melingkar (*anisotropic reflection*).
  * Jarum dan tonearm logam kuningan turun perlahan menyentuh alur vinyl.
  * Laci modular di bawah turntable bergeser keluar (*drawer slide*), memperlihatkan kepingan master: Bach, Chopin, Satie.
* **Kurva Gerak (Graph Editor):**
  * *Tonearm Lowering:* Kurva sinusoidal sangat lembut (durasi 32 frame, ease-in dan ease-out simetris 65%).
  * *Vinyl Spin:* Rotasi konstan murni `time * 200` (tanpa easing, kecepatan sudut terkunci).
* **Tipografi On-Screen:**
  * Teks: `UNIT 03 // 33⅓ RPM MONASTIC TURNTABLE`  
    `20 ACOUSTIC MASTERS // 100% OFFLINE DSP`
* **Voiceover:**
  * *(00:21 – 00:25)*: *"Dua puluh lanskap audio akustik."*
  * *(00:25 – 00:29)*: *"Berputar hening langsung dari mesin lokal."*
* **Desain Suara & Musik:**
  * *Tone drop & needle crackle:* Klik halus, desau noise permukaan piringan hitam analog (*vintage 33 RPM rumble*).
  * Musik: Aransemen solo piano *Gymnopédie No. 1* (Satie) langsung menyatu mengisi frekuensi mid-range secara elegan.

---

### SCENE 05: 12 HARDWARE EDITIONS MORPH (00:29 – 00:35)
*Transisi material tanpa henti (match-cut seamless) menunjukkan koleksi sasis industri.*

* **Framing & Kamera:**
  * *Shot:* Medium Shot (MS), smartphone berada tegak di atas dock kayu walnut di meja arsitek.
  * *Lensa:* 50mm, pencahayaan studio berganti secara ritmis seiring pergantian material.
  * *Gerakan Kamera:* Kamera mundur perlahan (*slow continuous dolly zoom out*).
* **Aset & Lapisan Visual:**
  * Sasis smartphone bertransformasi material secara berurutan tiap 18 frame:
    1. *Warm Bone 1976* (Putih krem matte)
    2. *Obsidian Atelier* (Hitam anodized)
    3. *Raw Brass Instrument* (Kuningan mengilap dengan patina)
    4. *Bauhaus 1928* (Garis fungsional tegas)
* **Teknik Transisi:**
  * *Wipe by Light:* Bayangan bilah jendela melintasi bodi instrumen; area yang terkena sapuan cahaya langsung berganti tekstur material secara sinkron.
* **Tipografi On-Screen:**
  * Teks dinamis berganti:
    * `EDITION 01: WARM BONE`
    * `EDITION 05: RAW BRASS`
    * `EDITION 08: DARK ALUMINUM`
* **Voiceover:**
  * *(00:29 – 00:35)*: *"Dua belas edisi material industri. Seratus persen offline. Tanpa pelacak, tanpa langganan."*
* **Desain Suara & Musik:**
  * Klik rotary switch mekanik instrumen Jerman (*heavy industrial rotary latch*) tepat pada tiap pergantian material sasis.

---

### SCENE 06: HONEST OWNERSHIP & OUTRO (00:35 – 00:40)
*Klimaks pernyataan kepemilikan jujur dan identitas studio RSQUARE.*

* **Framing & Kamera:**
  * *Shot:* Wide Shot (WS) simetris presisi ala Stanley Kubrick / Dieter Rams.
  * *Lensa:* 50mm, bidang pandang terkunci mati di tengah (*dead center*).
* **Aset & Lapisan Visual:**
  * Seluruh instrumen ZYKL berdiri anggun di atas meja kerja yang bersih dan sunyi.
  * UI memudar halus menyisakan siluet perangkat keras fisik.
  * Muncul tipografi logo ZYKL, sub-brand RSQUARE, dan pilar manifesto kepemilikan.
* **Kurva Gerak (Graph Editor):**
  * Teks CTA muncul dari bawah dengan `Y Position Offset +40px`, Opacity 0 ke 100% menggunakan kurva Apple: Speed peak di frame ke-3, deceleration tail panjang (Influence 88%).
* **Tipografi On-Screen:**
  * **ZYKL** (Font: Helvetica Bold / Akzidenz-Grotesk, Kerning +200)
  * `HONEST OWNERSHIP // RP 69.000 LIFETIME`
  * `0 SUBSCRIPTIONS. 0 ADS. 0 TRACKING.`
  * `AVAILABLE ON GOOGLE PLAY // zykl.app`
* **Voiceover:**
  * *(00:35 – 00:40)*: *"Fokus murni. Miliki selamanya."*
* **Desain Suara & Musik:**
  * Akor piano penutup dengan *reverb hall* panjang yang memudar perlahan (*fade-out natural*).
  * Pada detik 00:39.12: Satu detak mekanik final (*one final heavy chronometer escapement tick*) tepat saat layar padam total.

---

## 3. ARSITEKTUR KOMPOSISI AFTER EFFECTS & ELEMEN 3D

```
MASTER_RENDER_4K_24FPS (Comp Utama)
│
├── 01_ADJUSTMENT_POST_FINISH (Lensa, Grain 35mm 1.5%, Vignette optik 8%)
├── 02_AUDIO_VO_MASTER_STEM (Stem Voiceover, SFX Haptik, Musik Piano)
│
├── [PRECOMP] SCENE_06_OUTRO_LOCKUP
│   ├── Logo_ZYKL_Vector_Paths
│   ├── Typography_Manifesto_Monospace
│   └── Background_Vignette_Clean
│
├── [PRECOMP] SCENE_05_EDITIONS_MORPH
│   ├── 3D_Model_Passes (Diffuse, Specular, Normal, Roughness)
│   └── Light_Sweep_Controller (Matte Masker Pergantian Material)
│
├── [PRECOMP] SCENE_04_UNIT03_TURNTABLE
│   ├── Tonearm_Rig (Rotational Null with Spring-damping)
│   ├── Vinyl_Disc_Anisotropic_Loop (Pre-rendered 33.33 RPM)
│   └── Modular_Drawers_Slide_Comp
│
├── [PRECOMP] SCENE_03_UNIT02_DISPENSER
│   ├── Serrated_Paper_Mesh (CC Page Turn + Wave Warp Micro)
│   ├── Stamp_Haptic_Strike (Null Impact with Camera Shake trigger)
│   └── Thermal_Text_Deboss_Pass
│
├── [PRECOMP] SCENE_02_UNIT01_CHRONOMETER
│   ├── Dial_Backplate_Textures
│   ├── Escapement_Needle_Expression_Rig (Rotasi per 1.0 detik)
│   └── Telemetry_HUD_Monospace
│
└── [PRECOMP] SCENE_01_DISTRACTION_HOOK
    ├── Notification_Particles_Chaos
    ├── Screen_Glass_Smudge_NormalMap
    └── Glitch_Blackout_Controller
```

---

## 4. FORMULA SPESIFIK EXPRESSION AFTER EFFECTS

### Rig Escapement 1.0 Hz Jarum Chronometer (Unit 01)
Terapkan kode ini pada properti `Rotation` jarum detik untuk menghasilkan detak mekanik berbobot fisik tanpa membuat ratusan keyframe manual:

```javascript
// Escapement Stepping Motor Rig (1.0 Hz with mechanical recoil)
fps = 1.0; // 1 Detak per detik
t = time * fps;
step = Math.floor(t);
prog = t - step;

// Durasi gerak jarum adalah 0.15 detik pertama tiap detik
motionDuration = 0.15;

if (prog < motionDuration) {
    p = prog / motionDuration;
    // Kurva akselerasi cepat dengan recoil mekanik (overshoot 4%)
    v = Math.sin(p * Math.PI / 2);
    overshoot = Math.sin(p * Math.PI) * 0.04;
    curStep = (step + v + overshoot) * 6; // 6 derajat per detik
} else {
    curStep = (step + 1) * 6;
}

value + curStep;
```

---

## 5. CHECKLIST QUALITY CONTROL (THE DIETER RAMS STANDARD)

* [ ] **Bebas Gerakan Mengambang (No Floatiness):** Tidak ada elemen UI yang berhenti menggunakan kurva simetris generik. Semua perpindahan memiliki bobot gravitasi atau gesekan mekanis.
* [ ] **Ketepatan Skala Tipografi:** Tipografi monospace terbaca tajam pada jarak pandang layar ponsel tanpa mendominasi estetika dial sasis.
* [ ] **Sinkronisasi SFX Sub-Frame:** Setiap suara benturan stempel, gesekan kertas, dan klik knob terjadi maksimal 1 frame sebelum kontak visual (*audio anticipation*).
* [ ] **Akurasi Refleksi Material:** Tidak ada permukaan logam atau kaca yang tampak seperti plastik datar; micro-roughness dan specular highlights terkontrol sesuai spesifikasi edisi perangkat keras ZYKL.