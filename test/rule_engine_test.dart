import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_robo/models/survey_models.dart';
import 'package:flutter_robo/services/rule_engine_service.dart';

void main() {
  group('BIMA 2026 PRD Spesifikasi & Implementasi Perhitungan (Bab 5 & Bab 9)', () {
    final cfg = RuleEngineConfig.defaultFallback;

    test('Implementasi Perhitungan Bab 5: Kasus K1-S4 menghasilkan Level 4 Serangan Sangat Tinggi', () {
      final points = [
        SurveyPointData(id: 'T1', name: 'Kiri Atas', nb: 18, nt: 12, na: 1),
        SurveyPointData(id: 'T2', name: 'Kanan Atas', nb: 22, nt: 14, na: 0),
        SurveyPointData(id: 'T3', name: 'Kiri Bawah', nb: 19, nt: 11, na: 1),
        SurveyPointData(id: 'T4', name: 'Kanan Bawah', nb: 21, nt: 13, na: 0),
        SurveyPointData(id: 'T5', name: 'Tengah', nb: 20, nt: 12, na: 0),
      ];

      final result = RuleEngineService.evaluateSurvey(
        points: points,
        customConfig: cfg,
      );

      // Langkah 1: Hitung 4 Parameter
      expect(result.a, equals(20.0));
      expect(result.b, equals(2)); // T1, T3
      expect(result.c, equals(5)); // T1..T5
      expect(result.d, equals(5)); // T1..T5

      // Langkah 2: Kode Kepadatan
      expect(result.kodeK, equals('K1'));

      // Langkah 3: Kode Sebaran
      expect(result.kodeS, equals('S4'));

      // Langkah 4: Matriks K x S
      expect(result.fullCode, equals('K1-S4'));
      expect(result.level, equals(4));
      expect(result.levelTitle, equals('Serangan sangat tinggi'));
      expect(result.sumberSel, equals('tabel'));

      // Langkah 5: Koreksi & Hotspot
      expect(result.peringatanHotspot, isFalse);
      expect(result.intensitasTerkoreksi, isFalse);

      // Log Perhitungan
      expect(result.langkah1Log, contains('A = (18 + 22 + 19 + 21 + 20) / 5 = 20.0'));
      expect(result.langkah2Log, contains('K1 (Padat)'));
      expect(result.langkah3Log, contains('S4'));
      expect(result.langkah4Log, contains('Level 4'));
    });

    test('Uji 2: Kasus K0-S2 menghasilkan Level 2 dan Hotspot Alert pada Titik T5', () {
      final points = [
        SurveyPointData(id: 'T1', name: 'Kiri Atas', nb: 8, nt: 0, na: 0),
        SurveyPointData(id: 'T2', name: 'Kanan Atas', nb: 9, nt: 0, na: 0),
        SurveyPointData(id: 'T3', name: 'Kiri Bawah', nb: 7, nt: 0, na: 0),
        SurveyPointData(id: 'T4', name: 'Kanan Bawah', nb: 10, nt: 1, na: 0),
        SurveyPointData(id: 'T5', name: 'Tengah', nb: 26, nt: 15, na: 3),
      ];

      final result = RuleEngineService.evaluateSurvey(
        points: points,
        customConfig: cfg,
      );

      expect(result.a, equals(12.0));
      expect(result.b, equals(1));
      expect(result.c, equals(1));
      expect(result.d, equals(2));
      expect(result.kodeK, equals('K0'));
      expect(result.kodeS, equals('S2'));
      expect(result.fullCode, equals('K0-S2'));
      expect(result.level, equals(2));
      expect(result.sumberSel, equals('tabel'));
      expect(result.peringatanHotspot, isTrue);
      expect(result.hotspotTitikList.any((e) => e.contains('T5')), isTrue);
    });

    test('Uji 3a: Kasus K0-S1 normal menghasilkan Level 1', () {
      final points = [
        SurveyPointData(id: 'T1', name: 'Kiri Atas', nb: 5, nt: 0, na: 0),
        SurveyPointData(id: 'T2', name: 'Kanan Atas', nb: 6, nt: 0, na: 0),
        SurveyPointData(id: 'T3', name: 'Kiri Bawah', nb: 4, nt: 0, na: 0),
        SurveyPointData(id: 'T4', name: 'Kanan Bawah', nb: 7, nt: 0, na: 0),
        SurveyPointData(id: 'T5', name: 'Tengah', nb: 5, nt: 0, na: 0),
      ];

      final result = RuleEngineService.evaluateSurvey(
        points: points,
        intensitas: 1.5,
        customConfig: cfg,
      );

      expect(result.a, closeTo(5.4, 0.001));
      expect(result.b, equals(0));
      expect(result.c, equals(0));
      expect(result.d, equals(0));
      expect(result.kodeK, equals('K0'));
      expect(result.kodeS, equals('S1'));
      expect(result.fullCode, equals('K0-S1'));
      expect(result.level, equals(1));
      expect(result.intensitasTerkoreksi, isFalse);
    });

    test('Uji 3b: Koreksi Intensitas (Level 1 naik ke Level 2 jika intensitas >= 2.7%)', () {
      final points = [
        SurveyPointData(id: 'T1', name: 'Kiri Atas', nb: 5, nt: 0, na: 0),
        SurveyPointData(id: 'T2', name: 'Kanan Atas', nb: 6, nt: 0, na: 0),
        SurveyPointData(id: 'T3', name: 'Kiri Bawah', nb: 4, nt: 0, na: 0),
        SurveyPointData(id: 'T4', name: 'Kanan Bawah', nb: 7, nt: 0, na: 0),
        SurveyPointData(id: 'T5', name: 'Tengah', nb: 5, nt: 0, na: 0),
      ];

      final result = RuleEngineService.evaluateSurvey(
        points: points,
        intensitas: 3.1, // >= 2.7%
        customConfig: cfg,
      );

      expect(result.kodeK, equals('K0'));
      expect(result.kodeS, equals('S1'));
      expect(result.level, equals(2));
      expect(result.intensitasTerkoreksi, isTrue);
    });

    test('Uji 4: Kasus K1-S1 menghasilkan Level 2 (Sumber Sel Turunan)', () {
      final points = [
        SurveyPointData(id: 'T1', name: 'Kiri Atas', nb: 24, nt: 0, na: 0),
        SurveyPointData(id: 'T2', name: 'Kanan Atas', nb: 26, nt: 0, na: 0),
        SurveyPointData(id: 'T3', name: 'Kiri Bawah', nb: 22, nt: 0, na: 0),
        SurveyPointData(id: 'T4', name: 'Kanan Bawah', nb: 25, nt: 0, na: 0),
        SurveyPointData(id: 'T5', name: 'Tengah', nb: 23, nt: 0, na: 0),
      ];

      final result = RuleEngineService.evaluateSurvey(
        points: points,
        customConfig: cfg,
      );

      expect(result.a, equals(24.0));
      expect(result.b, equals(0));
      expect(result.c, equals(0));
      expect(result.d, equals(0));
      expect(result.kodeK, equals('K1'));
      expect(result.kodeS, equals('S1'));
      expect(result.fullCode, equals('K1-S1'));
      expect(result.level, equals(2));
      expect(result.sumberSel, equals('turunan'));
      expect(result.isTurunan, isTrue);
    });

    test('Uji 5: Kasus Bebas Bercak menghasilkan Level 0 Sehat', () {
      final points = [
        SurveyPointData(id: 'T1', name: 'Kiri Atas', nb: 0, nt: 0, na: 0),
        SurveyPointData(id: 'T2', name: 'Kanan Atas', nb: 0, nt: 0, na: 0),
        SurveyPointData(id: 'T3', name: 'Kiri Bawah', nb: 0, nt: 0, na: 0),
        SurveyPointData(id: 'T4', name: 'Kanan Bawah', nb: 0, nt: 0, na: 0),
        SurveyPointData(id: 'T5', name: 'Tengah', nb: 0, nt: 0, na: 0),
      ];

      final result = RuleEngineService.evaluateSurvey(
        points: points,
        customConfig: cfg,
      );

      expect(result.a, equals(0.0));
      expect(result.b, equals(0));
      expect(result.c, equals(0));
      expect(result.d, equals(0));
      expect(result.kodeK, equals('K0'));
      expect(result.kodeS, equals('S0'));
      expect(result.fullCode, equals('K0-S0'));
      expect(result.level, equals(0));
      expect(result.levelTitle, equals('Sehat'));
    });
  });
}
