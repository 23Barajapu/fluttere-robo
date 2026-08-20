import '../models/bounding_box.dart';

class DiseaseAnalysis {
  final String diseaseKey;
  final String displayName;
  final int spotCount;
  final double severityPercent;
  final String severityStatus;
  final String recommendation;

  DiseaseAnalysis({
    required this.diseaseKey,
    required this.displayName,
    required this.spotCount,
    required this.severityPercent,
    required this.severityStatus,
    required this.recommendation,
  });
}

class DiseaseAnalyzer {
  static DiseaseAnalysis analyze(List<BoundingBox> boxes) {
    if (boxes.isEmpty) {
      return DiseaseAnalysis(
        diseaseKey: 'healthy',
        displayName: 'Daun Sehat',
        spotCount: 0,
        severityPercent: 0.0,
        severityStatus: 'Sehat',
        recommendation:
            'Tanaman berada dalam kondisi prima. Pertahankan pemupukan berimbang dan sanitasi lahan.',
      );
    }

    // Hitung frekuensi kelas terbanyak
    final classCounts = <String, int>{};
    for (final box in boxes) {
      final key = _normalizeClassKey(box.className);
      classCounts[key] = (classCounts[key] ?? 0) + 1;
    }

    // Cari kelas dominan
    String dominantKey = 'healthy';
    int maxCount = 0;
    classCounts.forEach((key, count) {
      if (count > maxCount) {
        maxCount = count;
        dominantKey = key;
      }
    });

    final totalSpots = boxes.length;

    switch (dominantKey) {
      case 'brownspot':
        return _analyzeBrownSpot(totalSpots);
      case 'sheathblight':
        return _analyzeSheathBlight(totalSpots);
      case 'tungro':
        return _analyzeTungro(totalSpots);
      case 'blast':
        return _analyzeBlast(totalSpots);
      default:
        // Jika label didapat 'healthy' atau lainnya
        if (dominantKey == 'healthy') {
          return DiseaseAnalysis(
            diseaseKey: 'healthy',
            displayName: 'Daun Sehat',
            spotCount: 0,
            severityPercent: 0.0,
            severityStatus: 'Sehat',
            recommendation:
                'Pertahankan pemupukan berimbang dan sanitasi lahan.',
          );
        }
        return _analyzeGeneric(dominantKey, totalSpots);
    }
  }

  static String _normalizeClassKey(String className) {
    final lower = className.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (lower.contains('brown') || lower.contains('bercak')) return 'brownspot';
    if (lower.contains('sheath') || lower.contains('pelepah') || lower.contains('hawar')) return 'sheathblight';
    if (lower.contains('tungro')) return 'tungro';
    if (lower.contains('blast') || lower.contains('blas')) return 'blast';
    if (lower.contains('healthy') || lower.contains('sehat')) return 'healthy';
    return lower;
  }

  static DiseaseAnalysis _analyzeBrownSpot(int count) {
    if (count <= 15) {
      return DiseaseAnalysis(
        diseaseKey: 'brownSpot',
        displayName: 'Bercak Cokelat (Brown Spot)',
        spotCount: count,
        severityPercent: 15.0,
        severityStatus: 'Ringan',
        recommendation: 'Pemantauan rutin. Belum memerlukan perlakuan kimia, jaga kecukupan unsur hara kalium.',
      );
    } else if (count <= 30) {
      return DiseaseAnalysis(
        diseaseKey: 'brownSpot',
        displayName: 'Bercak Cokelat (Brown Spot)',
        spotCount: count,
        severityPercent: 30.0,
        severityStatus: 'Sedang Rendah',
        recommendation: 'Semprot fungisida protektif jarang (interval 2 minggu). Cek keasaman air sawah.',
      );
    } else if (count <= 40) {
      return DiseaseAnalysis(
        diseaseKey: 'brownSpot',
        displayName: 'Bercak Cokelat (Brown Spot)',
        spotCount: count,
        severityPercent: 50.0,
        severityStatus: 'Sedang Tinggi',
        recommendation: 'Semprot fungisida kuratif (interval 1 minggu). Batasi pemupukan nitrogen berlebih.',
      );
    } else {
      return DiseaseAnalysis(
        diseaseKey: 'brownSpot',
        displayName: 'Bercak Cokelat (Brown Spot)',
        spotCount: count,
        severityPercent: 65.0,
        severityStatus: 'Berat',
        recommendation: 'Perlakuan intensif fungisida sistemik. Segera konsultasikan dengan Penyuluh Pertanian Lapangan (PPL).',
      );
    }
  }

  static DiseaseAnalysis _analyzeSheathBlight(int count) {
    if (count <= 10) {
      return DiseaseAnalysis(
        diseaseKey: 'sheathBlight',
        displayName: 'Hawar Pelepah (Sheath Blight)',
        spotCount: count,
        severityPercent: 10.0,
        severityStatus: 'Ringan',
        recommendation: 'Pemantauan rutin dan perbaiki sirkulasi udara di rumpun tanaman padi.',
      );
    } else if (count <= 20) {
      return DiseaseAnalysis(
        diseaseKey: 'sheathBlight',
        displayName: 'Hawar Pelepah (Sheath Blight)',
        spotCount: count,
        severityPercent: 20.0,
        severityStatus: 'Sedang Rendah',
        recommendation: 'Semprot fungisida berbahan aktif validamycin atau azoksistrobin dengan interval 2 minggu.',
      );
    } else if (count <= 30) {
      return DiseaseAnalysis(
        diseaseKey: 'sheathBlight',
        displayName: 'Hawar Pelepah (Sheath Blight)',
        spotCount: count,
        severityPercent: 40.0,
        severityStatus: 'Sedang Tinggi',
        recommendation: 'Semprot fungisida intensif (interval 1 minggu) dan keringkan sawah berkala (intermittent irrigation).',
      );
    } else {
      return DiseaseAnalysis(
        diseaseKey: 'sheathBlight',
        displayName: 'Hawar Pelepah (Sheath Blight)',
        spotCount: count,
        severityPercent: 55.0,
        severityStatus: 'Berat',
        recommendation: 'Pengendalian intensif, perbaikan drainase total, dan bersihkan pelepah yang membusuk parah.',
      );
    }
  }

  static DiseaseAnalysis _analyzeTungro(int count) {
    if (count <= 5) {
      return DiseaseAnalysis(
        diseaseKey: 'tungro',
        displayName: 'Penyakit Tungro',
        spotCount: count,
        severityPercent: 20.0,
        severityStatus: 'Ringan',
        recommendation: 'Pantau perkembangan tanaman dan periksa keberadaan wereng hijau pada rumpun.',
      );
    } else if (count <= 15) {
      return DiseaseAnalysis(
        diseaseKey: 'tungro',
        displayName: 'Penyakit Tungro',
        spotCount: count,
        severityPercent: 40.0,
        severityStatus: 'Sedang',
        recommendation: 'Kendalikan populasi wereng hijau (vektor) segera dengan insektisida yang direkomendasikan.',
      );
    } else {
      return DiseaseAnalysis(
        diseaseKey: 'tungro',
        displayName: 'Penyakit Tungro',
        spotCount: count,
        severityPercent: 70.0,
        severityStatus: 'Berat / Kritis',
        recommendation: 'Cabut dan musnahkan (bakar/kubur) tanaman yang terinfeksi untuk mencegah transmisi ke rumpun lain.',
      );
    }
  }

  static DiseaseAnalysis _analyzeBlast(int count) {
    if (count <= 10) {
      return DiseaseAnalysis(
        diseaseKey: 'blast',
        displayName: 'Penyakit Blas (Blast)',
        spotCount: count,
        severityPercent: 15.0,
        severityStatus: 'Ringan',
        recommendation: 'Kurangi pemupukan urea/nitrogen tinggi, jaga penggenangan air dan pantau bercak belah ketupat.',
      );
    } else if (count <= 25) {
      return DiseaseAnalysis(
        diseaseKey: 'blast',
        displayName: 'Penyakit Blas (Blast)',
        spotCount: count,
        severityPercent: 35.0,
        severityStatus: 'Sedang',
        recommendation: 'Semprot fungisida berbahan aktif Tricyclazole atau Isoprothiolane pada pagi/sore hari.',
      );
    } else {
      return DiseaseAnalysis(
        diseaseKey: 'blast',
        displayName: 'Penyakit Blas (Blast)',
        spotCount: count,
        severityPercent: 60.0,
        severityStatus: 'Berat',
        recommendation: 'Serangan blas parah. Isolasi petak sawah dan laporkan ke dinas pertanian/PPL setempat.',
      );
    }
  }

  static DiseaseAnalysis _analyzeGeneric(String name, int count) {
    final severity = (count * 5.0).clamp(10.0, 90.0);
    return DiseaseAnalysis(
      diseaseKey: name,
      displayName: name,
      spotCount: count,
      severityPercent: severity,
      severityStatus: severity > 50 ? 'Tinggi' : 'Sedang',
      recommendation: 'Terdeteksi $count gejala. Lakukan pemantauan dan konsultasi dengan ahli agronomis.',
    );
  }
}
