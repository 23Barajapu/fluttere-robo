import 'bounding_box.dart';

class DetectionResult {
  final String imagePath;
  final double imageWidth;
  final double imageHeight;
  final List<BoundingBox> predictions;
  final String primaryDisease;
  final String primaryDiseaseLabel;
  final int spotCount;
  final double severityPercent;
  final String severityStatus;
  final String recommendation;
  final double inferenceTimeMs;
  final String modelName;

  DetectionResult({
    required this.imagePath,
    required this.imageWidth,
    required this.imageHeight,
    required this.predictions,
    required this.primaryDisease,
    required this.primaryDiseaseLabel,
    required this.spotCount,
    required this.severityPercent,
    required this.severityStatus,
    required this.recommendation,
    required this.inferenceTimeMs,
    required this.modelName,
  });
}
