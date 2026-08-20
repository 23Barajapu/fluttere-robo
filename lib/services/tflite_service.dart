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
  static Interpreter? _rfdetrInterpreter;
  static List<String> _labels = [];
  static OfflineModel activeModel = OfflineModel.yoloV11;

  static const int inputSize = 640;
  static const double confThreshold = 0.35;
  static const double iouThreshold = 0.45;

  static String get activeModelName =>
      activeModel == OfflineModel.yoloV11 ? 'YOLOv11 Nano' : 'RF-DETR (ViT)';

  /// Inisialisasi Interpreter TFLite lokal & muat labels
  static Future<void> init() async {
    try {
      final options = InterpreterOptions()..threads = 4;

      // 1. Muat YOLOv11 TFLite
      _yoloInterpreter ??= await Interpreter.fromAsset(
        'assets/models/yolov11.tflite',
        options: options,
      );

      // 2. Coba muat RF-DETR jika ada file tflite-nya
      if (_rfdetrInterpreter == null) {
        try {
          _rfdetrInterpreter = await Interpreter.fromAsset(
            'assets/models/rfdetr.tflite',
            options: options,
          );
        } catch (_) {
          // Fallback ke YOLO jika rfdetr.tflite belum di-load
          _rfdetrInterpreter = _yoloInterpreter;
        }
      }

      // 3. Muat labels
      try {
        final labelsData = await rootBundle.loadString('assets/models/labels.txt');
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

  /// Eksekusi Inferensi Offline 100% pada citra
  static Future<DetectionResult> detectImage(String filePath) async {
    if (_yoloInterpreter == null) {
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

    // 1. Preprocessing citra: Resize ke 640x640 dan normalisasi [0..1]
    final resized = img.copyResize(originalImage, width: inputSize, height: inputSize);

    // Input buffer [1, 640, 640, 3] Float32
    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );

    // 2. Output buffer [1, 9, 8400]
    final numClasses = _labels.isNotEmpty ? _labels.length : 5;
    final outputChannels = 4 + numClasses; // 9
    final output = List.generate(
      1,
      (_) => List.generate(
        outputChannels,
        (_) => List<double>.filled(8400, 0.0),
      ),
    );

    // 3. Eksekusi Interpreter sesuai model aktif
    final interpreter = (activeModel == OfflineModel.rfDetr && _rfdetrInterpreter != null)
        ? _rfdetrInterpreter!
        : _yoloInterpreter!;

    interpreter.run(input, output);

    // 4. Parsing Bounding Box & Class Scores
    final candidateBoxes = <BoundingBox>[];
    final outMatrix = output[0]; // [9, 8400]

    final scaleX = origW / inputSize;
    final scaleY = origH / inputSize;

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

    // 5. Non-Maximum Suppression (NMS)
    final filteredBoxes = _applyNMS(candidateBoxes, iouThreshold);

    stopwatch.stop();
    final elapsedMs = stopwatch.elapsedMilliseconds.toDouble();

    // 6. Agronomic Severity & Threshold Analyzer
    final analysis = DiseaseAnalyzer.analyze(filteredBoxes);

    return DetectionResult(
      imagePath: filePath,
      imageWidth: origW,
      imageHeight: origH,
      predictions: filteredBoxes,
      primaryDisease: analysis.diseaseKey,
      primaryDiseaseLabel: analysis.displayName,
      spotCount: analysis.spotCount,
      severityPercent: analysis.severityPercent,
      severityStatus: analysis.severityStatus,
      recommendation: analysis.recommendation,
      inferenceTimeMs: elapsedMs,
      modelName: '$activeModelName (Offline)',
    );
  }

  /// Algoritma Non-Maximum Suppression (NMS)
  static List<BoundingBox> _applyNMS(List<BoundingBox> boxes, double threshold) {
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
