# 📑 Ringkasan Hasil Deteksi dan Diagnosis Penyakit Daun Padi

Dokumen ini memuat spesifikasi struktur data laporan, format ekspor ringkasan, dan visualisasi hasil evaluasi lapangan berbasis **Sistem Deteksi, Diagnosis, dan Rekomendasi Presisi (Hibah BIMA 2026)**.

---

## 1. Format Ringkasan Formal (Ekspor Teks)

```text
====================================================
🌾 LAPORAN RINGKASAN DIAGNOSIS PENYAKIT DAUN PADI
   Sistem Terintegrasi Deteksi & Rekomendasi Presisi
====================================================
ID Petak          : PETAK-01
Waktu Survei      : 2026-08-26 16:15:00
Metode Sampling   : Pola Diagonal X (5 Titik × 3 Strata)
Versi Ambang      : 1.0 (BIMA 2026)
----------------------------------------------------
📊 KEPUTUSAN DIAGNOSIS AKHIR:
----------------------------------------------------
Tingkat Keparahan : LEVEL 4 (Serangan sangat tinggi)
Pasangan Kode     : K1-S4 (Kepadatan: K1, Sebaran: S4)
Sumber Matriks    : Tabel Acuan Ahli Pertanian
Peringatan Hotspot: TIDAK
----------------------------------------------------
📈 RINCIAN 4 PARAMETER DASAR:
----------------------------------------------------
A (Rata-rata Nb)  : 20.00 bercak / titik
B (Daun Atas Na)  : 2 dari 5 titik terinfeksi (>= 1 bercak)
C (Tengah Berat)  : 5 dari 5 titik infeksi berat (> 10 bercak)
D (Tengah Ringan) : 5 dari 5 titik terinfeksi (>= 1 bercak)
----------------------------------------------------
📍 REKAP DATA 5 TITIK RUMPUN:
----------------------------------------------------
T1 - Sudut Kiri Atas     : Nb=18, Nt=12, Na= 1 | Total=31 bercak
T2 - Sudut Kanan Atas    : Nb=22, Nt=14, Na= 0 | Total=36 bercak
T3 - Sudut Kiri Bawah    : Nb=19, Nt=11, Na= 1 | Total=31 bercak
T4 - Sudut Kanan Bawah   : Nb=21, Nt=13, Na= 0 | Total=34 bercak
T5 - Titik Tengah Petak  : Nb=20, Nt=12, Na= 0 | Total=32 bercak
----------------------------------------------------
💡 REKOMENDASI TINDAKAN (PHT):
----------------------------------------------------
1. Prioritaskan tindakan yang paling cepat menekan perkembangan penyakit (terutama fungisida yang terdaftar dan efektif).
2. Pertahankan dan integrasikan komponen PHT lainnya.
3. Segera konsultasikan dengan Penyuluh Pertanian Lapangan (PPL) setempat.
====================================================
```

---

## 2. Struktur Payload Data Penelitian (JSON Schema)

```json
{
  "id_sesi": "SESI-1787739300000",
  "id_petak": "PETAK-01",
  "id_pengamat": "PPL-SUBANG-01",
  "waktu_survei": "2026-08-26T16:15:00.000Z",
  "versi_ambang": "1.0",
  "skema_sampling": "5_titik_pola_x",
  "hasil_diagnosis": {
    "level": 4,
    "judul_level": "Serangan sangat tinggi",
    "kode_k": "K1",
    "kode_s": "S4",
    "full_code": "K1-S4",
    "sumber_matriks": "tabel",
    "is_turunan": false,
    "peringatan_hotspot": false,
    "titik_hotspot": [],
    "intensitas_terkoreksi": false,
    "rekomendasi_tindakan": [
      "Prioritaskan tindakan yang paling cepat menekan perkembangan penyakit (terutama fungisida yang terdaftar dan efektif).",
      "Pertahankan dan integrasikan komponen PHT lainnya.",
      "Segera konsultasikan dengan Penyuluh Pertanian Lapangan (PPL) setempat."
    ]
  },
  "parameter_agregasi": {
    "A_rata_rata_nb": 20.0,
    "B_titik_na_terinfeksi": 2,
    "C_titik_nt_berat": 5,
    "D_titik_nt_ringan": 5
  },
  "data_titik": [
    { "kode": "T1", "nama_posisi": "Sudut Kiri Atas", "is_terjangkau": true, "Nb": 18, "Nt": 12, "Na": 1, "total_bercak": 31 },
    { "kode": "T2", "nama_posisi": "Sudut Kanan Atas", "is_terjangkau": true, "Nb": 22, "Nt": 14, "Na": 0, "total_bercak": 36 },
    { "kode": "T3", "nama_posisi": "Sudut Kiri Bawah", "is_terjangkau": true, "Nb": 19, "Nt": 11, "Na": 1, "total_bercak": 31 },
    { "kode": "T4", "nama_posisi": "Sudut Kanan Bawah", "is_terjangkau": true, "Nb": 21, "Nt": 13, "Na": 0, "total_bercak": 34 },
    { "kode": "T5", "nama_posisi": "Titik Tengah Petak", "is_terjangkau": true, "Nb": 20, "Nt": 12, "Na": 0, "total_bercak": 32 }
  ],
  "jejak_perhitungan": {
    "langkah_1": "A = (18 + 22 + 19 + 21 + 20) / 5 = 20.0 | B = 2 (T1, T3) | C = 5 (T1..T5) | D = 5 (T1..T5)",
    "langkah_2": "A = 20.0 >= 20 -> K1 (Padat)",
    "langkah_3": "Urutan 1: B = 2 >= 2 -> S4 (Sampai daun atas)",
    "langkah_4": "Pasangan K1 + S4 -> Level 4 (Tabel Ahli)",
    "langkah_5": "Koreksi intensitas: Lewat | Hotspot: Tidak ada titik ekstrem yang melebihi petak"
  }
}
```

---

## 3. Matriks Keputusan Level & Rekomendasi PHT

| Kode | Kondisi Kepadatan & Sebaran | Level | Kategori Status | Rekomendasi Utama |
|:---:|---|:---:|---|---|
| **K0-S0** | $A < 20$, Bebas bercak | **Level 0** | **Sehat** | Pemantauan rutin berkala tanpa perlakuan kimia. |
| **K0-S1** | $A < 20$, Hanya daun bawah | **Level 1** | **Di bawah Ambang Ekonomi** | Sanitasi, pemupukan berimbang, agens hayati (*P. polymyxa*). |
| **K0-S2** | $A < 20$, Daun tengah infeksi ringan ($D \ge 2$) | **Level 2** | **Mendekati Ambang Ekonomi** | Kurangi pupuk N berlebih, perbaiki sirkulasi, agens hayati. |
| **K1-S1** | $A \ge 20$, Hanya daun bawah | **Level 2** | **Mendekati Ambang Ekonomi** *(Turunan)* | Kurangi kelembapan mikro, monitoring intensif. |
| **K0-S3** | $A < 20$, Daun tengah infeksi berat ($C \ge 2$) | **Level 3** | **Melampaui Ambang Ekonomi** *(Turunan)* | Pengendalian segera pestisida hayati/kimia. |
| **K1-S3** | $A \ge 20$, Daun tengah infeksi berat ($C \ge 2$) | **Level 3** | **Melampaui Ambang Ekonomi** | Aplikasi fungisida terdaftar & evaluasi berkala. |
| **K0-S4** | $A < 20$, Daun atas terinfeksi ($B \ge 2$) | **Level 4** | **Serangan Sangat Tinggi** *(Turunan)* | Prioritaskan fungisida cepat & perlindungan daun bendera. |
| **K1-S4** | $A \ge 20$, Daun atas terinfeksi ($B \ge 2$) | **Level 4** | **Serangan Sangat Tinggi** | Prioritaskan fungisida cepat, PHT terpadu, hubungi PPL. |
