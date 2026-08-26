import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/bounding_box.dart';
import '../models/survey_models.dart';

class RuleEngineService {
  static RuleEngineConfig? _cachedConfig;

  /// Memuat berkas konfigurasi ambang dan matriks dari assets/config/config.json
  static Future<RuleEngineConfig> loadConfig() async {
    if (_cachedConfig != null) return _cachedConfig!;

    try {
      final jsonString =
          await rootBundle.loadString('assets/config/config.json');
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      _cachedConfig = RuleEngineConfig.fromJson(jsonMap);
    } catch (_) {
      _cachedConfig = RuleEngineConfig.defaultFallback;
    }
    return _cachedConfig!;
  }

  /// Pure Function: Evaluasi hasil survei 5 titik berdasarkan aturan 5 langkah BIMA 2026
  static RuleEngineResult evaluateSurvey({
    required List<SurveyPointData> points,
    double? intensitas,
    RuleEngineConfig? customConfig,
  }) {
    final cfg =
        customConfig ?? _cachedConfig ?? RuleEngineConfig.defaultFallback;

    final validPoints = points.where((p) => !p.isUnreachable).toList();
    if (validPoints.isEmpty) {
      return RuleEngineResult(
        a: 0.0,
        b: 0,
        c: 0,
        d: 0,
        kodeK: 'K0',
        kodeS: 'S0',
        fullCode: 'K0-S0',
        level: 0,
        levelTitle: cfg.rekomendasi[0]?.judul ?? 'Sehat',
        rekomendasi: cfg.rekomendasi[0]?.tindakan ?? [],
        sumberSel: 'turunan',
        peringatanHotspot: false,
        hotspotTitikList: [],
        langkah1Log: 'Data titik kosong / tidak terjangkau',
        langkah2Log: 'A = 0.0 < 20 -> K0 (Rendah)',
        langkah3Log: 'Bebas bercak -> S0',
        langkah4Log: 'K0 + S0 -> Level 0',
        langkah5Log: 'Tidak ada koreksi.',
      );
    }

    // ---------- LANGKAH 1: Hitung 4 Parameter Dasar ----------
    final totalNb = validPoints.fold<int>(0, (sum, p) => sum + p.nb);
    final double a = totalNb / validPoints.length; // Tanpa pembulatan awal

    final bList = validPoints.where((p) => p.na >= cfg.naMin).map((p) => p.id).toList();
    final cList = validPoints.where((p) => p.nt > cfg.ntBerat).map((p) => p.id).toList();
    final dList = validPoints.where((p) => p.nt >= cfg.ntRinganMin).map((p) => p.id).toList();

    final int b = bList.length;
    final int c = cList.length;
    final int d = dList.length;
    final bool adaBercak = validPoints.any((p) => (p.nb + p.nt + p.na) > 0);

    final nbParts = validPoints.map((p) => p.nb.toString()).join(' + ');
    final String l1Log =
        'A = ($nbParts) / ${validPoints.length} = ${a.toStringAsFixed(1)} | '
        'B = $b ${bList.isNotEmpty ? '(${bList.join(', ')})' : ''} | '
        'C = $c ${cList.isNotEmpty ? '(${cList.join(', ')})' : ''} | '
        'D = $d ${dList.isNotEmpty ? '(${dList.join(', ')})' : ''}';

    // ---------- LANGKAH 2: Tentukan Kode Kepadatan (K) ----------
    final bool isPadat = a >= cfg.nbPadat;
    final String kodeK = isPadat ? 'K1' : 'K0';
    final String l2Log =
        'A = ${a.toStringAsFixed(1)} ${isPadat ? '>= 20 -> K1 (Padat)' : '< 20 -> K0 (Rendah)'}';

    // ---------- LANGKAH 3: Tentukan Kode Sebaran (S) ----------
    final int m = cfg.titikMinimum;
    String kodeS;
    String l3Reason;
    if (b >= m) {
      kodeS = 'S4';
      l3Reason = 'Urutan 1: B = $b >= $m -> S4 (Sampai daun atas)';
    } else if (c >= m) {
      kodeS = 'S3';
      l3Reason = 'Urutan 2: C = $c >= $m -> S3 (Daun tengah berat > 10)';
    } else if (d >= m) {
      kodeS = 'S2';
      l3Reason = 'Urutan 3: D = $d >= $m -> S2 (Daun tengah ringan >= 1)';
    } else if (adaBercak) {
      kodeS = 'S1';
      l3Reason = 'Urutan 4: Masih ditemukan bercak -> S1 (Hanya daun bawah)';
    } else {
      kodeS = 'S0';
      l3Reason = 'Urutan 5: Bebas bercak -> S0 (Sehat)';
    }

    // ---------- LANGKAH 4: Pencocokan Matriks Level Dasar ----------
    final String matrixKey = '${kodeK}_$kodeS';
    final MatrixCell cell =
        cfg.matriks[matrixKey] ?? MatrixCell(level: 0, sumber: 'turunan');
    int finalLevel = cell.level;
    final String l4Log =
        'Pasangan $kodeK + $kodeS -> Level $finalLevel (${cell.sumber == 'tabel' ? 'Tabel Ahli' : 'Sel Turunan'})';

    // ---------- LANGKAH 5a: Koreksi Intensitas ----------
    bool intensitasTerkoreksi = false;
    String l5aLog = 'Koreksi intensitas: Lewat';
    if (finalLevel == 1) {
      if (intensitas != null && intensitas >= cfg.intensitasAmanMaks) {
        finalLevel = 2;
        intensitasTerkoreksi = true;
        l5aLog =
            'Koreksi intensitas: Intensitas ${intensitas.toStringAsFixed(1)}% >= 2.7% -> Naik ke Level 2';
      } else {
        l5aLog =
            'Koreksi intensitas: Aman (${intensitas != null ? '${intensitas.toStringAsFixed(1)}%' : 'N/A'})';
      }
    }

    // ---------- LANGKAH 5b: Peringatan Titik Parah (Hotspot) ----------
    final List<String> hotspotList = [];
    for (final pt in validPoints) {
      final singleResult = _evaluateSinglePoint(pt, cfg);
      if (singleResult.level >= 3) {
        hotspotList.add('${pt.id} (${pt.name})');
      }
    }

    final bool peringatanHotspot = (hotspotList.isNotEmpty && finalLevel <= 2);
    final String l5bLog = peringatanHotspot
        ? 'Hotspot: Terdeteksi titik ekstrem Level >= 3 (${hotspotList.join(', ')}) saat petak Level $finalLevel'
        : 'Hotspot: Tidak ada titik ekstrem yang melebihi petak';

    final String l5Log = '$l5aLog | $l5bLog';

    final recoItem = cfg.rekomendasi[finalLevel];
    final String levelTitle = recoItem?.judul ?? 'Level $finalLevel';
    final List<String> actions = recoItem?.tindakan ?? [];

    return RuleEngineResult(
      a: a,
      b: b,
      c: c,
      d: d,
      kodeK: kodeK,
      kodeS: kodeS,
      fullCode: '$kodeK-$kodeS',
      level: finalLevel,
      levelTitle: levelTitle,
      rekomendasi: actions,
      sumberSel: cell.sumber,
      peringatanHotspot: peringatanHotspot,
      hotspotTitikList: hotspotList,
      langkah1Log: l1Log,
      langkah2Log: l2Log,
      langkah3Log: l3Reason,
      langkah4Log: l4Log,
      langkah5Log: l5Log,
      intensitas: intensitas,
      intensitasTerkoreksi: intensitasTerkoreksi,
    );
  }

  /// Evaluasi mandiri 1 titik dengan titik_minimum = 1
  static RuleEngineResult _evaluateSinglePoint(
    SurveyPointData pt,
    RuleEngineConfig cfg,
  ) {
    final double a = pt.nb.toDouble();
    final String k = (a >= cfg.nbPadat) ? 'K1' : 'K0';

    String s;
    if (pt.na >= cfg.naMin) {
      s = 'S4';
    } else if (pt.nt > cfg.ntBerat) {
      s = 'S3';
    } else if (pt.nt >= cfg.ntRinganMin) {
      s = 'S2';
    } else if ((pt.nb + pt.nt + pt.na) > 0) {
      s = 'S1';
    } else {
      s = 'S0';
    }

    final key = '${k}_$s';
    final cell = cfg.matriks[key] ?? MatrixCell(level: 0, sumber: 'turunan');

    return RuleEngineResult(
      a: a,
      b: pt.na >= cfg.naMin ? 1 : 0,
      c: pt.nt > cfg.ntBerat ? 1 : 0,
      d: pt.nt >= cfg.ntRinganMin ? 1 : 0,
      kodeK: k,
      kodeS: s,
      fullCode: '$k-$s',
      level: cell.level,
      levelTitle: '',
      rekomendasi: [],
      sumberSel: cell.sumber,
      peringatanHotspot: false,
      hotspotTitikList: [],
      langkah1Log: '',
      langkah2Log: '',
      langkah3Log: '',
      langkah4Log: '',
      langkah5Log: '',
    );
  }

  /// Hitung nilai intensitas serangan berbasis luas bounding box dengan faktor koreksi 0.785
  static double calculateIntensitas({
    required List<BoundingBox> boxes,
    required double leafAreaPx,
    double factor = 0.785,
  }) {
    if (leafAreaPx <= 0 || boxes.isEmpty) return 0.0;
    double totalBboxArea = 0.0;
    for (final box in boxes) {
      totalBboxArea += (box.width * box.height);
    }
    return (factor * totalBboxArea / leafAreaPx) * 100.0;
  }
}
