import '../models/bounding_box.dart';

enum StrataType {
  bawah, // Posisi 1 - 3
  tengah, // Posisi 4 - 7
  atas, // Posisi teratas / daun bendera
}

extension StrataTypeExt on StrataType {
  String get label {
    switch (this) {
      case StrataType.bawah:
        return 'Daun Bawah (Pos 1-3)';
      case StrataType.tengah:
        return 'Daun Tengah (Pos 4-7)';
      case StrataType.atas:
        return 'Daun Atas / Bendera';
    }
  }

  String get code {
    switch (this) {
      case StrataType.bawah:
        return 'Nb';
      case StrataType.tengah:
        return 'Nt';
      case StrataType.atas:
        return 'Na';
    }
  }
}

class LeafPhotoSample {
  final String imagePath;
  final StrataType strata;
  final int spotCount;
  final String diseaseName;
  final double confidence;
  final List<BoundingBox> boundingBoxes;
  final double? leafAreaPx;
  final double? spotsAreaPx;

  LeafPhotoSample({
    required this.imagePath,
    required this.strata,
    required this.spotCount,
    required this.diseaseName,
    required this.confidence,
    required this.boundingBoxes,
    this.leafAreaPx,
    this.spotsAreaPx,
  });
}

class SurveyPointData {
  final String id; // T1, T2, T3, T4, T5
  final String name; // Kiri Atas, Kanan Atas, Kiri Bawah, Kanan Bawah, Tengah
  int nb; // Jumlah bercak daun bawah
  int nt; // Jumlah bercak daun tengah
  int na; // Jumlah bercak daun atas
  final Map<StrataType, LeafPhotoSample?> samples;
  bool isUnreachable;
  String? unreachableReason;

  SurveyPointData({
    required this.id,
    required this.name,
    this.nb = 0,
    this.nt = 0,
    this.na = 0,
    Map<StrataType, LeafPhotoSample?>? samples,
    this.isUnreachable = false,
    this.unreachableReason,
  }) : samples = samples ?? {
          StrataType.bawah: null,
          StrataType.tengah: null,
          StrataType.atas: null,
        };

  int get totalSpots => nb + nt + na;

  bool get isComplete =>
      isUnreachable ||
      (samples[StrataType.bawah] != null &&
          samples[StrataType.tengah] != null &&
          samples[StrataType.atas] != null);
}

class MatrixCell {
  final int level;
  final String sumber; // "tabel" atau "turunan"

  MatrixCell({required this.level, required this.sumber});

  factory MatrixCell.fromJson(Map<String, dynamic> json) {
    return MatrixCell(
      level: json['level'] as int? ?? 0,
      sumber: json['sumber']?.toString() ?? 'turunan',
    );
  }
}

class RecommendationItem {
  final String judul;
  final List<String> tindakan;

  RecommendationItem({required this.judul, required this.tindakan});

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    final list = json['tindakan'] as List? ?? [];
    return RecommendationItem(
      judul: json['judul']?.toString() ?? '',
      tindakan: list.map((e) => e.toString()).toList(),
    );
  }
}

class RuleEngineConfig {
  final String versiAmbang;
  final String status;
  final double nbPadat;
  final double ntRinganMin;
  final double ntBerat;
  final double naMin;
  final int titikMinimum;
  final int jumlahTitikSurvei;
  final double intensitasAmanMaks;
  final double koreksiLuasBbox;
  final Map<String, MatrixCell> matriks;
  final Map<int, RecommendationItem> rekomendasi;

  RuleEngineConfig({
    required this.versiAmbang,
    required this.status,
    required this.nbPadat,
    required this.ntRinganMin,
    required this.ntBerat,
    required this.naMin,
    required this.titikMinimum,
    required this.jumlahTitikSurvei,
    required this.intensitasAmanMaks,
    required this.koreksiLuasBbox,
    required this.matriks,
    required this.rekomendasi,
  });

  factory RuleEngineConfig.fromJson(Map<String, dynamic> json) {
    final ambang = json['ambang'] as Map<String, dynamic>? ?? {};
    final rawMatriks = json['matriks'] as Map<String, dynamic>? ?? {};
    final rawRekomendasi = json['rekomendasi'] as Map<String, dynamic>? ?? {};

    final matriks = <String, MatrixCell>{};
    rawMatriks.forEach((k, v) {
      if (v is Map<String, dynamic>) {
        matriks[k] = MatrixCell.fromJson(v);
      }
    });

    final rekomendasi = <int, RecommendationItem>{};
    rawRekomendasi.forEach((k, v) {
      final keyInt = int.tryParse(k);
      if (keyInt != null && v is Map<String, dynamic>) {
        rekomendasi[keyInt] = RecommendationItem.fromJson(v);
      }
    });

    return RuleEngineConfig(
      versiAmbang: json['versi_ambang']?.toString() ?? '1.0',
      status: json['status']?.toString() ?? 'default',
      nbPadat: (ambang['nb_padat'] as num?)?.toDouble() ?? 20.0,
      ntRinganMin: (ambang['nt_ringan_min'] as num?)?.toDouble() ?? 1.0,
      ntBerat: (ambang['nt_berat'] as num?)?.toDouble() ?? 10.0,
      naMin: (ambang['na_min'] as num?)?.toDouble() ?? 1.0,
      titikMinimum: ambang['titik_minimum'] as int? ?? 2,
      jumlahTitikSurvei: ambang['jumlah_titik_survei'] as int? ?? 5,
      intensitasAmanMaks:
          (ambang['intensitas_aman_maks'] as num?)?.toDouble() ?? 2.7,
      koreksiLuasBbox:
          (ambang['koreksi_luas_bbox'] as num?)?.toDouble() ?? 0.785,
      matriks: matriks,
      rekomendasi: rekomendasi,
    );
  }

  static RuleEngineConfig get defaultFallback {
    return RuleEngineConfig(
      versiAmbang: '1.0',
      status: 'default fallback',
      nbPadat: 20.0,
      ntRinganMin: 1.0,
      ntBerat: 10.0,
      naMin: 1.0,
      titikMinimum: 2,
      jumlahTitikSurvei: 5,
      intensitasAmanMaks: 2.7,
      koreksiLuasBbox: 0.785,
      matriks: {
        'K0_S0': MatrixCell(level: 0, sumber: 'turunan'),
        'K0_S1': MatrixCell(level: 1, sumber: 'tabel'),
        'K1_S1': MatrixCell(level: 2, sumber: 'turunan'),
        'K0_S2': MatrixCell(level: 2, sumber: 'tabel'),
        'K1_S2': MatrixCell(level: 3, sumber: 'turunan'),
        'K0_S3': MatrixCell(level: 3, sumber: 'turunan'),
        'K1_S3': MatrixCell(level: 3, sumber: 'tabel'),
        'K0_S4': MatrixCell(level: 4, sumber: 'turunan'),
        'K1_S4': MatrixCell(level: 4, sumber: 'tabel'),
      },
      rekomendasi: {
        0: RecommendationItem(
          judul: 'Sehat',
          tindakan: [
            'Tidak ada tindakan khusus.',
            'Lanjutkan pemantauan rutin berkala.'
          ],
        ),
        1: RecommendationItem(
          judul: 'Di bawah ambang ekonomi',
          tindakan: [
            'Monitoring rutin, sanitasi lahan, dan pemupukan berimbang.',
            'Pengaturan air sawah dan gunakan agens hayati (Paenibacillus polymyxa).'
          ],
        ),
        2: RecommendationItem(
          judul: 'Mendekati ambang ekonomi',
          tindakan: [
            'Tingkatkan frekuensi monitoring di lapangan.',
            'Perbaiki faktor predisposisi (kurangi pupuk N, kurangi kelembapan mikro).',
            'Aplikasi agens pengendali hayati secara preventif.'
          ],
        ),
        3: RecommendationItem(
          judul: 'Melampaui ambang ekonomi',
          tindakan: [
            'Lakukan tindakan pengendalian segera dengan pestisida hayati dan atau kimia.',
            'Evaluasi efektivitas aplikasi pengendalian.'
          ],
        ),
        4: RecommendationItem(
          judul: 'Serangan sangat tinggi',
          tindakan: [
            'Prioritaskan tindakan cepat menekan penyakit (fungisida terdaftar & efektif).',
            'Pertahankan komponen PHT lainnya dan konsultasikan dengan PPL.'
          ],
        ),
      },
    );
  }
}

class RuleEngineResult {
  final double a; // Rata-rata Nb
  final int b; // Titik Na >= na_min
  final int c; // Titik Nt > nt_berat
  final int d; // Titik Nt >= nt_ringan_min
  final String kodeK; // K0 atau K1
  final String kodeS; // S0, S1, S2, S3, S4
  final String fullCode; // contoh: "K1-S4"
  final int level; // 0, 1, 2, 3, 4
  final String levelTitle;
  final List<String> rekomendasi;
  final String sumberSel; // "tabel" atau "turunan"
  final bool peringatanHotspot;
  final List<String> hotspotTitikList;
  final double? intensitas;
  final bool intensitasTerkoreksi;

  final String langkah1Log;
  final String langkah2Log;
  final String langkah3Log;
  final String langkah4Log;
  final String langkah5Log;

  RuleEngineResult({
    required this.a,
    required this.b,
    required this.c,
    required this.d,
    required this.kodeK,
    required this.kodeS,
    required this.fullCode,
    required this.level,
    required this.levelTitle,
    required this.rekomendasi,
    required this.sumberSel,
    required this.peringatanHotspot,
    required this.hotspotTitikList,
    required this.langkah1Log,
    required this.langkah2Log,
    required this.langkah3Log,
    required this.langkah4Log,
    required this.langkah5Log,
    this.intensitas,
    this.intensitasTerkoreksi = false,
  });

  bool get isTurunan => sumberSel.toLowerCase() == 'turunan';
}
