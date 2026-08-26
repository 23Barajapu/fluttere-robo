# RADAR: Rice Anomaly Detection and Assessment Recognition

Aplikasi mobile cerdas berbasis Flutter dan TensorFlow Lite (100% On-Device Edge AI) yang dirancang untuk mendeteksi lesi bercak daun padi, mengklasifikasikan jenis penyakit secara presisi, dan mengevaluasi tingkat keparahan petak sawah menggunakan Pure Rule Engine deterministik sesuai protokol penelitian Hibah BIMA 2026.

---

## Fitur Utama Sistem

- **Inferensi On-Device 100% Offline:** Seluruh komputasi visi komputer (deteksi lesi & klasifikasi) serta evaluasi mesin aturan berjalan lokal di perangkat Android tanpa memerlukan koneksi internet.
- **Pilihan Arsitektur AI Fleksibel:**
  - **YOLOv11 Nano (Float16 ~5.3 MB):** Deteksi neural bounding box dan penghitungan jumlah lesi bercak daun dengan input tensor $640 \times 640$.
  - **RF-DETR / ViT (Float16 ~1.5 MB):** Klasifikasi berbasis Vision Transformer dengan input tensor $224 \times 224$.
- **Protokol Sampling 5 Titik (Pola Diagonal X):** Pengambilan sampel pada 5 titik rumpun per petak sawah dengan 3 strata kanopi daun per rumpun (Daun Bawah $N_b$, Daun Tengah $N_t$, Daun Atas $N_a$) menghasilkan 15 sampel data.
- **Mesin Aturan Deterministik (Pure Rule Engine):** Algoritma 5 langkah berbasis parameter $A, B, C, D \rightarrow$ Matriks Kepadatan $\times$ Sebaran ($K \times S$) $\rightarrow$ Keputusan Level 0 hingga 4, dilengkapi deteksi peringatan titik kritis (*Hotspot Alert*).
- **Simulasi Cepat (Demo Mode):** Fitur pengisian instan 15 sampel dengan 4 skenario lapangan realistis (Level 0 Sehat, Level 1 Ringan, Level 2 Waspada, Level 3 Kritis) untuk kemudahan pengujian dan demonstrasi.
- **Sesi Survei Lapangan Persisten:** Data 15 sampel tetap tersimpan aman di sesi aktif saat navigasi keluar-masuk layar survei dan hanya di-reset bila tombol Reset (🔄) ditekan.
- **Unduh Laporan Langsung ke Perangkat:** Menyimpan laporan diagnosis formal (`.txt`) dan dataset riset terstruktur (`.json`) langsung ke folder *Download* memori HP.
- **Animasi Pemindaian Elegan:** Tampilan visual *minimalist viewfinder* dengan *emerald laser sweep* yang halus saat proses inferensi.

---

## Kategori Penyakit yang Dikenali

| No | Nama Penyakit | Label Teknis | Deskripsi Visual Gejala |
|---|---|---|---|
| 1 | Bercak Cokelat | `brownSpot` | Lesi bulat hingga lonjong berwarna cokelat dengan tepi gelap di helaian daun. |
| 2 | Hawar Pelepah | `sheathBlight` | Lesi basah kehijauan/keabu-abuan menyerupai bercak air pada pelepah dan daun. |
| 3 | Penyakit Tungro | `tungro` | Daun menguning hingga jingga dari pucuk helai disertai pertumbuhan rumpun kerdil. |
| 4 | Penyakit Blas | `blast` | Lesi berbentuk belah ketupat (elips meruncing) dengan titik tengah abu-abu keputihan. |
| 5 | Daun Sehat | `healthy` | Permukaan helai daun hijau segar normal tanpa gejala klorotik atau nekrotik. |

---

## Struktur Direktori Proyek

```text
lib/
├── main.dart                          # Titik masuk aplikasi dan konfigurasi tema
├── models/
│   ├── bounding_box.dart              # Model data koordinat bounding box dan warna kelas
│   ├── detection_result.dart          # Model data hasil inferensi model AI
│   └── survey_models.dart             # Model data sesi survei 5 titik, config, dan rule result
├── services/
│   ├── tflite_service.dart            # Service pipeline TFLite on-device (YOLOv11 & RF-DETR)
│   ├── disease_analyzer.dart          # Logika diagnosis keparahan agronomi per helai daun
│   ├── rule_engine_service.dart       # Service evaluasi 5 langkah matriks BIMA 2026
│   └── report_export_service.dart     # Service pembuat & penyimpan laporan teks & JSON
├── widgets/
│   └── scanning_overlay.dart          # Komponen animasi scanning overlay elegan
└── screens/
    ├── splash_screen.dart             # Layar pembuka / splash screen
    ├── home_screen.dart               # Dashboard utama (Pilihan model, survei, & scan cepat)
    ├── survey_screen.dart             # Antarmuka survei 5 titik dengan simulasi cepat
    ├── survey_result_screen.dart      # Layar hasil diagnosis petak, jejak langkah, & unduh laporan
    └── result_screen.dart             # Layar visualisasi deteksi pemeriksaan cepat 1 daun
assets/
├── config/
│   └── config.json                    # Konfigurasi ambang ekonomi, matriks, & rekomendasi PHT
└── models/
    ├── yolov11.tflite                 # Bobot model YOLOv11 Float16 (~5.3 MB)
    ├── vit.tflite                     # Bobot model Vision Transformer Float16 (~1.5 MB)
    ├── rfdetr.tflite                  # Bobot model RF-DETR Transformer Float16
    └── labels.txt                     # Daftar label target 5 kelas
```

---

## Persyaratan Lingkungan dan Instalasi

### Prasyarat
- Flutter SDK: Version 3.20.0 atau lebih baru
- Dart SDK: Version 3.3.0 atau lebih baru
- Target Platform: Android API Level 26 (Android 8.0) ke atas

### Menjalankan Aplikasi

1. Kloning repositori:
   ```bash
   git clone https://github.com/23Barajapu/fluttere-robo.git
   cd fluttere-robo
   ```

2. Pasang seluruh dependensi paket:
   ```bash
   flutter pub get
   ```

3. Jalankan pengujian statis kode:
   ```bash
   flutter analyze
   ```

4. Jalankan pada emulator atau perangkat Android fisik:
   ```bash
   flutter run
   ```

---

## Spesifikasi Inferensi On-Device

- **Format Runtime:** TensorFlow Lite (`.tflite`) Float16
- **Input Tensor YOLOv11:** `[1, 640, 640, 3]`, Float32 ter-normalisasi $[0.0, 1.0]$
- **Input Tensor ViT / RF-DETR:** `[1, 224, 224, 3]`, Float32 ter-normalisasi $[0.0, 1.0]$
- **Post-Processing:** Non-Maximum Suppression (NMS, IoU Threshold: 0.45, Confidence Threshold: 0.35)
- **Mesin Keputusan:** Deterministik berbasis tabel ambang ekonomi PHT (tanpa *black-box* probabilitas pada logika agregasi).

---

## Lisensi
Hak Cipta (c) 2026 Tim Peneliti Hibah BIMA 2026 • Politeknik Negeri Subang. Seluruh hak cipta dilindungi undang-undang.
