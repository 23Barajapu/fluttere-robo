import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/bounding_box.dart';
import '../models/detection_result.dart';
import 'disease_analyzer.dart';

enum OfflineModel {
  yoloV11,
  rfDetr,
}

class TFLiteService {
  static Interpreter? _yoloInterpreter;
  static Interpreter? _vitInterpreter;
  static List<String> _labels = [];
  static OfflineModel activeModel = OfflineModel.yoloV11;

  static const int yoloInputSize = 640;
  static const int vitInputSize = 224;
  static const double confThreshold = 0.35;
  static const double iouThreshold = 0.45;

  static String get activeModelName =>
      activeModel == OfflineModel.yoloV11 ? 'YOLOv11 Nano' : 'ViT / RF-DETR';

  /// Inisialisasi Dual Model On-Device (YOLOv11 + Vision Transformer)
  static Future<void> init() async {
    try {
      final options = InterpreterOptions()..threads = 4;

      // 1. Muat YOLOv11 TFLite (Spot Detector)
      _yoloInterpreter ??= await Interpreter.fromAsset(
        'assets/models/yolov11.tflite',
        options: options,
      );

      // 2. Muat Vision Transformer / RF-DETR TFLite (Disease Classifier)
      _vitInterpreter ??= await Interpreter.fromAsset(
        'assets/models/vit.tflite',
        options: options,
      );

      // 3. Muat labels
      try {
        final labelsData =
            await rootBundle.loadString('assets/models/labels.txt');
        _labels = labelsData
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } catch (_) {
        _labels = ['healthy', 'brownSpot', 'sheathBlight', 'tungro', 'blast'];
      }
    } catch (e) {
      throw Exception('Gagal memuat model TFLite: $e');
    }
  }

  /// Eksekusi Inferensi Dual-Model Pipeline (YOLO Spot Detector + ViT Classifier)
  static Future<DetectionResult> detectImage(String filePath) async {
    if (_yoloInterpreter == null || _vitInterpreter == null) {
      await init();
    }

    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File gambar tidak ditemukan: $filePath');
    }

    final bytes = await file.readAsBytes();
    final originalImage = img.decodeImage(bytes);
    if (originalImage == null) {
      throw Exception('Gagal mendecode file gambar.');
    }

    final origW = originalImage.width.toDouble();
    final origH = originalImage.height.toDouble();

    final stopwatch = Stopwatch()..start();

    // ==========================================
    // TAHAP 1.1: Deteksi Kotak Lesi via YOLOv11
    // ==========================================
    final yoloResized = img.copyResize(originalImage,
        width: yoloInputSize, height: yoloInputSize);

    final yoloInput = List.generate(
      1,
      (_) => List.generate(
        yoloInputSize,
        (y) => List.generate(
          yoloInputSize,
          (x) {
            final pixel = yoloResized.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );

    final numClasses = _labels.isNotEmpty ? _labels.length : 5;
    final outputChannels = 4 + numClasses; // 9
    final yoloOutput = List.generate(
      1,
      (_) => List.generate(
        outputChannels,
        (_) => List<double>.filled(8400, 0.0),
      ),
    );

    _yoloInterpreter!.run(yoloInput, yoloOutput);

    // Parsing YOLO output
    final candidateBoxes = <BoundingBox>[];
    final outMatrix = yoloOutput[0];
    final scaleX = origW / yoloInputSize;
    final scaleY = origH / yoloInputSize;

    for (int i = 0; i < 8400; i++) {
      double maxScore = 0.0;
      int bestClassIndex = 0;

      for (int c = 0; c < numClasses; c++) {
        final score = outMatrix[4 + c][i];
        if (score > maxScore) {
          maxScore = score;
          bestClassIndex = c;
        }
      }

      if (maxScore >= confThreshold) {
        final cx = outMatrix[0][i] * scaleX;
        final cy = outMatrix[1][i] * scaleY;
        final w = outMatrix[2][i] * scaleX;
        final h = outMatrix[3][i] * scaleY;

        final className = bestClassIndex < _labels.length
            ? _labels[bestClassIndex]
            : 'Class $bestClassIndex';

        candidateBoxes.add(
          BoundingBox(
            x: cx,
            y: cy,
            width: w,
            height: h,
            confidence: maxScore,
            className: className,
            classId: bestClassIndex,
          ),
        );
      }
    }

    final filteredBoxes = _applyNMS(candidateBoxes, iouThreshold);

    // ===============================================
    // TAHAP 1.2: Klasifikasi Penyakit via ViT Model
    // ===============================================
    String vitPredictedClass = 'healthy';
    try {
      final vitResized = img.copyResize(originalImage,
          width: vitInputSize, height: vitInputSize);
      final vitInput = List.generate(
        1,
        (_) => List.generate(
          vitInputSize,
          (y) => List.generate(
            vitInputSize,
            (x) {
              final pixel = vitResized.getPixel(x, y);
              return [
                pixel.r / 255.0,
                pixel.g / 255.0,
                pixel.b / 255.0,
              ];
            },
          ),
        ),
      );

      final vitOutput = List.generate(1, (_) => List<double>.filled(5, 0.0));
      _vitInterpreter!.run(vitInput, vitOutput);

      int bestVitIdx = 0;
      double maxVitProb = 0.0;
      for (int c = 0; c < 5; c++) {
        if (vitOutput[0][c] > maxVitProb) {
          maxVitProb = vitOutput[0][c];
          bestVitIdx = c;
        }
      }

      if (bestVitIdx < _labels.length) {
        vitPredictedClass = _labels[bestVitIdx];
      }
    } catch (_) {
      // Fallback jika ViT inferensi error
      if (filteredBoxes.isNotEmpty) {
        vitPredictedClass = filteredBoxes.first.className;
      }
    }

    stopwatch.stop();
    final elapsedMs = stopwatch.elapsedMilliseconds.toDouble();

    // ===============================================
    // TAHAP 1.3: Agronomic Severity Analysis
    // ===============================================
    final analysis = DiseaseAnalyzer.analyze(filteredBoxes);

    return DetectionResult(
      imagePath: filePath,
      imageWidth: origW,
      imageHeight: origH,
      predictions: filteredBoxes,
      primaryDisease: vitPredictedClass,
      primaryDiseaseLabel: analysis.displayName,
      spotCount: analysis.spotCount,
      severityPercent: analysis.severityPercent,
      severityStatus: analysis.severityStatus,
      recommendation: analysis.recommendation,
      inferenceTimeMs: elapsedMs,
      modelName:
          'Dual Model: YOLOv11 (${filteredBoxes.length} spots) + ViT ($vitPredictedClass)',
    );
  }

  /// Algoritma Non-Maximum Suppression (NMS)
  static List<BoundingBox> _applyNMS(
      List<BoundingBox> boxes, double threshold) {
    if (boxes.isEmpty) return [];

    boxes.sort((a, b) => b.confidence.compareTo(a.confidence));

    final selected = <BoundingBox>[];
    final active = List<bool>.filled(boxes.length, true);

    for (int i = 0; i < boxes.length; i++) {
      if (!active[i]) continue;

      final a = boxes[i];
      selected.add(a);

      for (int j = i + 1; j < boxes.length; j++) {
        if (!active[j]) continue;

        final b = boxes[j];
        final iou = _calculateIoU(a, b);
        if (iou >= threshold) {
          active[j] = false;
        }
      }
    }

    return selected;
  }

  /// Hitung Intersection over Union (IoU)
  static double _calculateIoU(BoundingBox a, BoundingBox b) {
    final x1 = max(a.left, b.left);
    final y1 = max(a.top, b.top);
    final x2 = min(a.left + a.width, b.left + b.width);
    final y2 = min(a.top + a.height, b.top + b.height);

    final intersectionW = max(0.0, x2 - x1);
    final intersectionH = max(0.0, y2 - y1);
    final intersectionArea = intersectionW * intersectionH;

    final areaA = a.width * a.height;
    final areaB = b.width * b.height;
    final unionArea = areaA + areaB - intersectionArea;

    return unionArea <= 0 ? 0.0 : intersectionArea / unionArea;
  }
}
