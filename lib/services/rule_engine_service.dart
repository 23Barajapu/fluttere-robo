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
    final cfg = customConfig ?? _cachedConfig ?? RuleEngineConfig.defaultFallback;

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
      );
    }

    // ---------- LANGKAH 1: Hitung 4 Parameter Dasar ----------
    final totalNb = validPoints.fold<int>(0, (sum, p) => sum + p.nb);
    final double a = totalNb / validPoints.length; // Tanpa pembulatan awal

    final int b = validPoints.where((p) => p.na >= cfg.naMin).length;
    final int c = validPoints.where((p) => p.nt > cfg.ntBerat).length;
    final int d = validPoints.where((p) => p.nt >= cfg.ntRinganMin).length;
    final bool adaBercak =
        validPoints.any((p) => (p.nb + p.nt + p.na) > 0);

    // ---------- LANGKAH 2: Tentukan Kode Kepadatan (K) ----------
    final String kodeK = (a >= cfg.nbPadat) ? 'K1' : 'K0';

    // ---------- LANGKAH 3: Tentukan Kode Sebaran (S) ----------
    final int m = cfg.titikMinimum;
    String kodeS;
    if (b >= m) {
      kodeS = 'S4';
    } else if (c >= m) {
      kodeS = 'S3';
    } else if (d >= m) {
      kodeS = 'S2';
    } else if (adaBercak) {
      kodeS = 'S1';
    } else {
      kodeS = 'S0';
    }

    // ---------- LANGKAH 4: Pencocokan Matriks Level Dasar ----------
    final String matrixKey = '${kodeK}_$kodeS';
    final MatrixCell cell = cfg.matriks[matrixKey] ??
        MatrixCell(level: 0, sumber: 'turunan');
    int finalLevel = cell.level;

    // ---------- LANGKAH 5a: Koreksi Intensitas ----------
    bool intensitasTerkoreksi = false;
    if (finalLevel == 1 &&
        intensitas != null &&
        intensitas >= cfg.intensitasAmanMaks) {
      finalLevel = 2;
      intensitasTerkoreksi = true;
    }

    // ---------- LANGKAH 5b: Peringatan Titik Parah (Hotspot) ----------
    final List<String> hotspotList = [];
    for (final pt in validPoints) {
      final singleResult = _evaluateSinglePoint(pt, cfg);
      if (singleResult.level >= 3) {
        hotspotList.add('${pt.id} (${pt.name})');
      }
    }

    final bool peringatanHotspot =
        (hotspotList.isNotEmpty && finalLevel <= 2);

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
