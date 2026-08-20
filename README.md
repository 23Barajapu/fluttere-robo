# 🌾 RiceLeaf AI (Deteksi & Keparahan Penyakit Daun Padi)

[![Flutter](https://img.shields.io/badge/Flutter-3.47.0-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.0-0175C2?logo=dart)](https://dart.dev)
[![TensorFlow Lite](https://img.shields.io/badge/TFLite-Edge%20AI-FF6F00?logo=tensorflow)](https://tensorflow.org/lite)
[![Architecture](https://img.shields.io/badge/Inference-100%25%20Offline-2D6A4F)](#)

Aplikasi mobile cerdas berbasis **Flutter** dan **TensorFlow Lite (Edge AI)** untuk mendiagnosis jenis penyakit daun padi secara otomatis, cepat, dan 100% offline langsung pada perangkat *smartphone* petani di sawah.

---

## 🚀 Fitur Utama

- 📶 **100% Offline On-Device Inference:** Eksekusi inferensi AI langsung di CPU perangkat Android menggunakan model TensorFlow Lite tanpa ketergantungan koneksi internet ataupun API pihak ketiga.
- 🎯 **Deteksi Lesi Berbasis YOLOv11:** Deteksi titik bercak lesi akurat dengan model YOLOv11 Nano (Float16 ~5.3 MB) berkecepatan tinggi.
- 📊 **Kalkulasi Tingkat Keparahan Agronomi:** Menghitung estimasi persentase keparahan penyakit (*severity percentage*) berdasarkan kepadatan bercak/lesi.
- 💡 **Rekomendasi Pengendalian Hama Terpadu (PHT):** Memberikan saran tindakan agronomis berbasis aturan ilmiah sesuai tingkat keparahan yang teridentifikasi.
- 🔍 **Visualisasi Interaktif:** Menampilkan overlay *bounding box* lesi transparan dengan kanvas yang mendukung *pinch-to-zoom* dan *panning*.

---

## 🌿 Kategori Penyakit yang Didukung

| No | Nama Penyakit | Label Teknis | Karakteristik Visual |
|---|---|---|---|
| 1 | **Daun Sehat** | `healthy` | Permukaan daun hijau mulus tanpa bercak klorotik/nekrotik |
| 2 | **Bercak Cokelat** | `brownSpot` | Bercak bulat-lonjong kecokelatan dengan tepi gelap |
| 3 | **Hawar Pelepah** | `sheathBlight` | Lesi basah keabu-abuan/kehijauan mirip bercak air |
| 4 | **Penyakit Tungro** | `tungro` | Daun menguning/oranye dari ujung daun, tanaman kerdil |
| 5 | **Penyakit Blas** | `blast` | Bercak belah ketupat/mata dengan pusat abu-abu keputihan |

---

## 🏗️ Struktur Proyek

```text
lib/
├── main.dart                      # Entry point aplikasi & tema agronomis modern
├── models/
│   ├── bounding_box.dart          # Data model koordinat & warna bounding box
│   └── detection_result.dart      # Data model hasil inferensi & kalkulasi keparahan
├── services/
│   ├── tflite_service.dart        # Engine inferensi TFLite lokal (YOLOv11 Nano Float16)
│   └── disease_analyzer.dart      # Rule engine agronomi (keparahan & rekomendasi)
└── screens/
    ├── splash_screen.dart         # Animated splash screen & warmup TFLite
    ├── home_screen.dart           # Dashboard kamera, galeri, & model selector
    └── result_screen.dart         # Visualisasi bounding box, gauge, & saran PHT
assets/
└── models/
    ├── yolov11.tflite             # Model On-Device Float16 (~5.3 MB)
    └── labels.txt                 # Daftar label 5 kelas penyakit
```

---

## ⚙️ Persyaratan Sistem & Instalasi

### Prasyarat
- **Flutter SDK:** Version 3.47.0+
- **Dart SDK:** Version 3.13.0+
- **Android Target:** Android 8.0 (API 26) ke atas

### Langkah Menjalankan Aplikasi

1. **Clone repository:**
   ```bash
   git clone <repository-url>
   cd flutter-robo
   ```

2. **Pasang dependensi:**
   ```bash
   flutter pub get
   ```

3. **Jalankan pengujian unit:**
   ```bash
   flutter test
   ```

4. **Jalankan pada perangkat / emulator Android:**
   ```bash
   flutter run
   ```

---

## 🧪 Spesifikasi Teknis Model

- **Format Model:** TensorFlow Lite (`.tflite`) Float16
- **Ukuran File:** 5.3 MB
- **Input Tensor:** `[1, 640, 640, 3]` (Float32, Normalized `0.0 - 1.0`)
- **Output Tensor:** `[1, 9, 8400]` (Bounding box coordinates + 5 class probability scores)
- **Post-Processing:** Non-Maximum Suppression (NMS, IoU Threshold `0.45`, Confidence Threshold `0.35`)

---

## 📄 Lisensi
Hak Cipta © 2026 Tim Pengembang RiceLeaf AI. Seluruh hak cipta dilindungi undang-undang.
