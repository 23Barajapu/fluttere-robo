import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_robo/models/bounding_box.dart';
import 'package:flutter_robo/services/disease_analyzer.dart';

void main() {
  group('DiseaseAnalyzer Unit Tests', () {
    test('Kondisi 0: Daun Sehat (Healthy) saat tidak ada deteksi', () {
      final analysis = DiseaseAnalyzer.analyze([]);
      expect(analysis.diseaseKey, equals('healthy'));
      expect(analysis.spotCount, equals(0));
      expect(analysis.severityPercent, equals(0.0));
      expect(analysis.severityStatus, equals('Sehat'));
    });

    test('Kondisi 1: Bercak Cokelat Ringan (<= 15 bercak)', () {
      final boxes = List.generate(
        10,
        (i) => BoundingBox(
          x: 100,
          y: 100,
          width: 20,
          height: 20,
          confidence: 0.8,
          className: 'brownSpot',
        ),
      );

      final analysis = DiseaseAnalyzer.analyze(boxes);
      expect(analysis.diseaseKey, equals('brownSpot'));
      expect(analysis.spotCount, equals(10));
      expect(analysis.severityPercent, equals(15.0));
      expect(analysis.severityStatus, equals('Ringan'));
    });

    test('Kondisi 2: Bercak Cokelat Sedang Rendah (16-30 bercak)', () {
      final boxes = List.generate(
        25,
        (i) => BoundingBox(
          x: 100,
          y: 100,
          width: 20,
          height: 20,
          confidence: 0.8,
          className: 'brownSpot',
        ),
      );

      final analysis = DiseaseAnalyzer.analyze(boxes);
      expect(analysis.diseaseKey, equals('brownSpot'));
      expect(analysis.spotCount, equals(25));
      expect(analysis.severityPercent, equals(30.0));
      expect(analysis.severityStatus, equals('Sedang Rendah'));
    });

    test('Kondisi 3: Hawar Pelepah Berat (> 30 bercak)', () {
      final boxes = List.generate(
        35,
        (i) => BoundingBox(
          x: 100,
          y: 100,
          width: 20,
          height: 20,
          confidence: 0.85,
          className: 'sheathBlight',
        ),
      );

      final analysis = DiseaseAnalyzer.analyze(boxes);
      expect(analysis.diseaseKey, equals('sheathBlight'));
      expect(analysis.spotCount, equals(35));
      expect(analysis.severityPercent, equals(55.0));
      expect(analysis.severityStatus, equals('Berat'));
    });

    test('Kondisi 4: Tungro Kritis (> 15 bercak)', () {
      final boxes = List.generate(
        18,
        (i) => BoundingBox(
          x: 100,
          y: 100,
          width: 20,
          height: 20,
          confidence: 0.9,
          className: 'tungro',
        ),
      );

      final analysis = DiseaseAnalyzer.analyze(boxes);
      expect(analysis.diseaseKey, equals('tungro'));
      expect(analysis.severityStatus, contains('Kritis'));
      expect(analysis.severityPercent, equals(70.0));
    });
  });
}
