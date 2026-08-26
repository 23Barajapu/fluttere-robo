# RADAR: Rice Anomaly Detection and Assessment Recognition

Aplikasi mobile berbasis Flutter dan TensorFlow Lite (On-Device Edge AI) yang dirancang untuk mendeteksi lesi bercak daun padi, mengklasifikasikan jenis penyakit, dan mengevaluasi tingkat keparahan petak sawah menggunakan Pure Rule Engine deterministik sesuai protokol penelitian Hibah BIMA 2026.

---

## Fitur Sistem

- **Inferensi On-Device 100% Offline:** Seluruh proses komputasi computer vision dan evaluasi mesin aturan dieksekusi secara lokal di perangkat Android tanpa koneksi internet.
- **Pipeline Dual-Model:**
  - **YOLOv11 Nano (Float16 ~5.3 MB):** Deteksi koordinat bounding box dan penghitungan jumlah lesi bercak.
  - **Vision Transformer / ViT (Float16 ~1.5 MB):** Klasifikasi probabilitas 5 kategori penyakit daun padi.
- **Protokol Sampling 5 Titik (Pola Diagonal X):** Pengambilan sampel 5 titik per petak sawah dengan 3 strata daun per rumpun (Daun Bawah $N_b$, Daun Tengah $N_t$, Daun Atas $N_a$) menghasilkan total 15 sampel foto.
- **Mesin Aturan Deterministik (Pure Rule Engine):** Algoritma 5 langkah berbasis parameter $A, B, C, D \rightarrow$ Matriks $K \times S \rightarrow$ Level 0 hingga 4, dilengkapi koreksi intensitas luas bercak dan peringatan titik parah (*Hotspot Alert*).
- **Konfigurasi Eksternal Dinamis:** Seluruh ambang batas, matriks keputusan, dan rekomendasi PHT dimuat dari berkas `config.json`.
- **Ekspor Laporan Formal:** Fasilitas pembuatan ringkasan diagnosis dalam format teks terstruktur dan payload JSON untuk penelusuran data penelitian (*data provenance*).

---

## Kategori Penyakit

| No | Nama Penyakit | Label Teknis | Deskripsi Visual |
|---|---|---|---|
| 1 | Daun Sehat | `healthy` | Permukaan helaian daun hijau normal tanpa gejala lesi klorotik atau nekrotik. |
| 2 | Bercak Cokelat | `brownSpot` | Lesi bulat hingga lonjong berwarna cokelat dengan bagian tepi lebih gelap. |
| 3 | Hawar Pelepah | `sheathBlight` | Lesi basah kehijauan atau keabu-abuan menyerupai bercak air pada pelepah/daun. |
| 4 | Penyakit Tungro | `tungro` | Daun menguning hingga jingga mulai dari ujung helai, disertai pertumbuhan kerdil. |
| 5 | Penyakit Blas | `blast` | Lesi berbentuk belah ketupat (elips meruncing) dengan titik tengah berwarna abu-abu keputihan. |

---

## Struktur Direktori

```text
lib/
├── main.dart                          # Titik masuk aplikasi dan konfigurasi tema
├── models/
│   ├── bounding_box.dart              # Model data bounding box dan koordinat visual
│   ├── detection_result.dart          # Model data hasil inferensi model
│   └── survey_models.dart             # Model data sesi survei 5 titik, config, dan rule result
├── services/
│   ├── tflite_service.dart            # Service pipeline TFLite on-device (YOLOv11 & ViT)
│   ├── disease_analyzer.dart          # Logika analisis keparahan agronomi per helai
│   ├── rule_engine_service.dart       # Service evaluasi 5 langkah matriks BIMA 2026
│   └── report_export_service.dart     # Service pembuat ringkasan laporan teks & JSON
└── screens/
    ├── splash_screen.dart             # Layar pembuka
    ├── home_screen.dart               # Dashboard utama (Survei 5 Titik & Scan Cepat)
    ├── survey_screen.dart             # Antarmuka wizard survei 5 titik (Pola X)
    ├── survey_result_screen.dart      # Layar hasil diagnosis petak, jejak langkah, & PHT
    └── result_screen.dart             # Layar visualisasi deteksi pemeriksaan cepat
assets/
├── config/
│   └── config.json                    # Berkas konfigurasi ambang, matriks, & rekomendasi
└── models/
    ├── yolov11.tflite                 # Bobot model YOLOv11 Float16 (~5.3 MB)
    ├── vit.tflite                     # Bobot model Vision Transformer Float16 (~1.5 MB)
    ├── rfdetr.tflite                  # Bobot model RF-DETR Transformer Float16
    └── labels.txt                     # Daftar label kelas target
```

---

## Persyaratan Lingkungan dan Instalasi

### Prasyarat
- Flutter SDK: Version 3.20.0 atau lebih baru
- Dart SDK: Version 3.3.0 atau lebih baru
- Target Platform: Android API Level 26 (Android 8.0) ke atas

### Menjalankan Proyek

1. Unduh repositori:
   ```bash
   git clone https://github.com/23Barajapu/fluttere-robo.git
   cd flutter-robo
   ```

2. Pasang dependensi paket:
   ```bash
   flutter pub get
   ```

3. Jalankan pengujian statis dan unit:
   ```bash
   flutter analyze
   flutter test
   ```

4. Jalankan pada perangkat target:
   ```bash
   flutter run
   ```

---

## Spesifikasi Inferensi On-Device

- Format Runtime: TensorFlow Lite (`.tflite`) Float16
- Input Tensor YOLOv11: `[1, 640, 640, 3]`, Float32 ter-normalisasi $[0.0, 1.0]$
- Input Tensor ViT: `[1, 224, 224, 3]`, Float32 ter-normalisasi $[0.0, 1.0]$
- Post-Processing: Non-Maximum Suppression (NMS, IoU Threshold: 0.45, Confidence Threshold: 0.35)
- Arsitektur Pengambilan Keputusan: Deterministik berbasis tabel ambang ekonomi (tanpa inferensi probabilitas gelap di mesin aturan).

---

## Lisensi
Hak Cipta (c) 2026 Tim Peneliti Politeknik Negeri Subang. Seluruh hak cipta dilindungi undang-undang.
