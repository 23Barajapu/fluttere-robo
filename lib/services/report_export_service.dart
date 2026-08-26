import 'dart:convert';
import '../models/survey_models.dart';

class ReportExportService {
  /// Menghasilkan teks ringkasan formal hasil diagnosis petak sawah
  static String generateTextSummary({
    required RuleEngineResult result,
    required List<SurveyPointData> points,
    String idPetak = 'PETAK-01',
    String? catatanPengamat,
  }) {
    final now = DateTime.now();
    final buffer = StringBuffer();

    buffer.writeln('====================================================');
    buffer.writeln('LAPORAN RINGKASAN DIAGNOSIS PENYAKIT DAUN PADI');
    buffer.writeln('Sistem Terintegrasi Deteksi & Rekomendasi Presisi');
    buffer.writeln('====================================================');
    buffer.writeln('ID Petak          : $idPetak');
    buffer.writeln('Waktu Survei      : ${now.toIso8601String().substring(0, 19).replaceAll('T', ' ')}');
    buffer.writeln('Metode Sampling   : Pola Diagonal X (5 Titik x 3 Strata)');
    buffer.writeln('Versi Ambang      : 1.0 (BIMA 2026)');
    buffer.writeln('----------------------------------------------------');
    buffer.writeln('KEPUTUSAN DIAGNOSIS AKHIR:');
    buffer.writeln('----------------------------------------------------');
    buffer.writeln('Tingkat Keparahan : LEVEL ${result.level} (${result.levelTitle})');
    buffer.writeln('Pasangan Kode     : ${result.fullCode} (Kepadatan: ${result.kodeK}, Sebaran: ${result.kodeS})');
    buffer.writeln('Sumber Matriks    : ${result.isTurunan ? 'Sel Turunan (Usulan BIMA 2026)' : 'Tabel Acuan Ahli Pertanian'}');
    buffer.writeln('Peringatan Hotspot: ${result.peringatanHotspot ? 'YA (Titik: ${result.hotspotTitikList.join(', ')})' : 'TIDAK'}');
    if (result.intensitasTerkoreksi) {
      buffer.writeln('Koreksi Luas      : Ya (Intensitas >= 2.7% -> Naik ke Level 2)');
    }
    buffer.writeln('----------------------------------------------------');
    buffer.writeln('RINCIAN 4 PARAMETER DASAR:');
    buffer.writeln('----------------------------------------------------');
    buffer.writeln('A (Rata-rata Nb)  : ${result.a.toStringAsFixed(2)} bercak / titik');
    buffer.writeln('B (Daun Atas Na)  : ${result.b} dari 5 titik terinfeksi (>= 1 bercak)');
    buffer.writeln('C (Tengah Berat)  : ${result.c} dari 5 titik infeksi berat (> 10 bercak)');
    buffer.writeln('D (Tengah Ringan) : ${result.d} dari 5 titik terinfeksi (>= 1 bercak)');
    buffer.writeln('----------------------------------------------------');
    buffer.writeln('REKAP DATA 5 TITIK RUMPUN:');
    buffer.writeln('----------------------------------------------------');
    for (final pt in points) {
      if (pt.isUnreachable) {
        buffer.writeln('${pt.id} - ${pt.name.padRight(20)}: [TIDAK TERJANGKAU - ${pt.unreachableReason ?? '-'}]');
      } else {
        buffer.writeln('${pt.id} - ${pt.name.padRight(20)}: Nb=${pt.nb.toString().padLeft(2)}, Nt=${pt.nt.toString().padLeft(2)}, Na=${pt.na.toString().padLeft(2)} | Total=${pt.totalSpots} bercak');
      }
    }
    buffer.writeln('----------------------------------------------------');
    buffer.writeln('REKOMENDASI TINDAKAN (PHT):');
    buffer.writeln('----------------------------------------------------');
    for (int i = 0; i < result.rekomendasi.length; i++) {
      buffer.writeln('${i + 1}. ${result.rekomendasi[i]}');
    }
    if (catatanPengamat != null && catatanPengamat.isNotEmpty) {
      buffer.writeln('----------------------------------------------------');
      buffer.writeln('CATATAN PENGAMAT:');
      buffer.writeln(catatanPengamat);
    }
    buffer.writeln('====================================================');

    return buffer.toString();
  }

  /// Menghasilkan payload JSON terstruktur untuk sinkronisasi database / riset
  static Map<String, dynamic> generateJsonPayload({
    required RuleEngineResult result,
    required List<SurveyPointData> points,
    String idSesi = '',
    String idPetak = 'PETAK-01',
    String? idPengamat,
  }) {
    return {
      'id_sesi': idSesi.isNotEmpty ? idSesi : 'SESI-${DateTime.now().millisecondsSinceEpoch}',
      'id_petak': idPetak,
      'id_pengamat': idPengamat,
      'waktu_survei': DateTime.now().toIso8601String(),
      'versi_ambang': '1.0',
      'skema_sampling': '5_titik_pola_x',
      'hasil_diagnosis': {
        'level': result.level,
        'judul_level': result.levelTitle,
        'kode_k': result.kodeK,
        'kode_s': result.kodeS,
        'full_code': result.fullCode,
        'sumber_matriks': result.sumberSel,
        'is_turunan': result.isTurunan,
        'peringatan_hotspot': result.peringatanHotspot,
        'titik_hotspot': result.hotspotTitikList,
        'intensitas_terkoreksi': result.intensitasTerkoreksi,
        'rekomendasi_tindakan': result.rekomendasi,
      },
      'parameter_agregasi': {
        'A_rata_rata_nb': result.a,
        'B_titik_na_terinfeksi': result.b,
        'C_titik_nt_berat': result.c,
        'D_titik_nt_ringan': result.d,
      },
      'data_titik': points.map((p) => {
        'kode': p.id,
        'nama_posisi': p.name,
        'is_terjangkau': !p.isUnreachable,
        'alasan_tidak_terjangkau': p.unreachableReason,
        'Nb': p.nb,
        'Nt': p.nt,
        'Na': p.na,
        'total_bercak': p.totalSpots,
      }).toList(),
      'jejak_perhitungan': {
        'langkah_1': result.langkah1Log,
        'langkah_2': result.langkah2Log,
        'langkah_3': result.langkah3Log,
        'langkah_4': result.langkah4Log,
        'langkah_5': result.langkah5Log,
      },
    };
  }

  /// Menghasilkan format JSON string rapi (pretty print)
  static String generateJsonPrettyString({
    required RuleEngineResult result,
    required List<SurveyPointData> points,
    String idPetak = 'PETAK-01',
  }) {
    final payload = generateJsonPayload(
      result: result,
      points: points,
      idPetak: idPetak,
    );
    return const JsonEncoder.withIndent('  ').convert(payload);
  }
}
