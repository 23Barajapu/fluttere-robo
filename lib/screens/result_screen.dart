import 'dart:io';
import 'package:flutter/material.dart';
import '../models/bounding_box.dart';
import '../models/detection_result.dart';

class ResultScreen extends StatelessWidget {
  final DetectionResult result;

  const ResultScreen({super.key, required this.result});

  Color _getSeverityColor(double percent) {
    if (percent <= 0) return const Color(0xFF2E7D32); // Green
    if (percent <= 20) return const Color(0xFF43A047); // Light Green
    if (percent <= 40) return const Color(0xFFFB8C00); // Orange
    return const Color(0xFFE53935); // Red
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = _getSeverityColor(result.severityPercent);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF132A1C),
        elevation: 0,
        title: const Text(
          'Hasil Analisis Daun',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview Gambar dengan Bounding Box Overlay
            Container(
              height: 340,
              width: double.infinity,
              color: Colors.black,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  InteractiveViewer(
                    maxScale: 4.0,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Center(
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: result.imageWidth,
                              height: result.imageHeight,
                              child: Stack(
                                children: [
                                  Image.file(
                                    File(result.imagePath),
                                    fit: BoxFit.fill,
                                  ),
                                  CustomPaint(
                                    size: Size(
                                      result.imageWidth,
                                      result.imageHeight,
                                    ),
                                    painter: BoundingBoxPainter(
                                      boxes: result.predictions,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.speed,
                            color: Color(0xFF52B788),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${result.inferenceTimeMs.toStringAsFixed(0)} ms',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B3D2B).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF52B788)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.memory_rounded,
                            color: Color(0xFF52B788),
                            size: 13,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            result.modelName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Diagnosis Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B3D2B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF2D6A4F),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: severityColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            result.spotCount == 0
                                ? Icons.check_circle_outline
                                : Icons.warning_amber_rounded,
                            color: severityColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                result.primaryDiseaseLabel,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Status: ${result.severityStatus} • ${result.spotCount} lesi terdeteksi',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Severity Gauge Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF132A1C),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tingkat Keparahan',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB7E4C7),
                              ),
                            ),
                            Text(
                              '${result.severityPercent.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: severityColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (result.severityPercent / 100).clamp(0.0, 1.0),
                            minHeight: 10,
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation<Color>(severityColor),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          result.spotCount == 0
                              ? 'Tidak ada gejala bercak terdeteksi pada daun.'
                              : 'Berdasarkan kalkulasi kepadatan ${result.spotCount} titik lesi pada permukaan sampel.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF95D5B2),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Agronomic Advisory Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF132A1C),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.science_outlined,
                              color: Color(0xFF52B788),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Rekomendasi Tindakan Agronomi',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          result.recommendation,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFFD8F3DC),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Detected Spots Breakdown (if any)
                  if (result.predictions.isNotEmpty) ...[
                    const Text(
                      'Daftar Deteksi Bounding Box',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB7E4C7),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF132A1C),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: result.predictions.length > 8
                            ? 8
                            : result.predictions.length,
                        separatorBuilder: (context, index) =>
                            const Divider(color: Colors.white10, height: 1),
                        itemBuilder: (context, index) {
                          final box = result.predictions[index];
                          return ListTile(
                            dense: true,
                            leading: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: box.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: Text(
                              'Lesi #${index + 1} (${box.className})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Ukuran: ${box.width.toStringAsFixed(0)}x${box.height.toStringAsFixed(0)} px',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: box.color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                box.confidenceText,
                                style: TextStyle(
                                  color: box.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (result.predictions.length > 8)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Center(
                          child: Text(
                            '+ ${result.predictions.length - 8} lesi lainnya terdeteksi',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],

                  const SizedBox(height: 32),

                  // Action Buttons
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.document_scanner_rounded),
                    label: const Text(
                      'Pindai Daun Lain',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D6A4F),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Kembali ke Beranda'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF95D5B2),
                      side: const BorderSide(color: Color(0xFF2D6A4F)),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BoundingBoxPainter extends CustomPainter {
  final List<BoundingBox> boxes;

  BoundingBoxPainter({required this.boxes});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < boxes.length; i++) {
      final box = boxes[i];
      final rect = Rect.fromLTWH(box.left, box.top, box.width, box.height);

      // Border Box
      final paint = Paint()
        ..color = box.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawRect(rect, paint);

      // Background Label Text
      final label = '#${i + 1} ${box.confidenceText}';
      final textSpan = TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final labelRect = Rect.fromLTWH(
        box.left,
        (box.top - textPainter.height - 4).clamp(0.0, size.height),
        textPainter.width + 8,
        textPainter.height + 4,
      );

      final bgPaint = Paint()..color = box.color.withValues(alpha: 0.9);
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
        bgPaint,
      );

      textPainter.paint(
        canvas,
        Offset(labelRect.left + 4, labelRect.top + 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return oldDelegate.boxes != boxes;
  }
}
