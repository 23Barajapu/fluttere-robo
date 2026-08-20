import 'package:flutter/material.dart';

class BoundingBox {
  final double x; // Center X
  final double y; // Center Y
  final double width;
  final double height;
  final double confidence;
  final String className;
  final int? classId;

  BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.confidence,
    required this.className,
    this.classId,
  });

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      className: json['class']?.toString() ?? 'unknown',
      classId: json['class_id'] as int?,
    );
  }

  // Koordinat pojok kiri atas (Left)
  double get left => x - (width / 2);

  // Koordinat pojok atas (Top)
  double get top => y - (height / 2);

  // Warna badge & border bounding box berdasarkan kelas
  Color get color {
    final lower = className.toLowerCase();
    if (lower.contains('brown') || lower.contains('bercak')) {
      return const Color(0xFFE65100); // Orange-Brown
    } else if (lower.contains('sheath') || lower.contains('pelepah')) {
      return const Color(0xFFF57F17); // Amber-Yellow
    } else if (lower.contains('tungro')) {
      return const Color(0xFFD50000); // Red
    } else if (lower.contains('blast') || lower.contains('blas')) {
      return const Color(0xFFC2185B); // Pink-Crimson
    } else if (lower.contains('healthy') || lower.contains('sehat')) {
      return const Color(0xFF2E7D32); // Green
    }
    return const Color(0xFF00897B); // Teal Default
  }

  // Format persentase keyakinan
  String get confidenceText => '${(confidence * 100).toStringAsFixed(1)}%';
}
