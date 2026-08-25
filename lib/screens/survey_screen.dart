import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/detection_result.dart';
import '../models/survey_models.dart';
import '../services/rule_engine_service.dart';
import '../services/tflite_service.dart';
import '../widgets/scanning_overlay.dart';
import 'survey_result_screen.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  String _processingMessage = '';
  String? _processingImagePath;

  late List<SurveyPointData> _points;
  int _expandedPointIndex = 0;

  @override
  void initState() {
    super.initState();
    _initSurveyPoints();
    RuleEngineService.loadConfig().catchError((_) => RuleEngineConfig.defaultFallback);
  }

  void _initSurveyPoints() {
    _points = [
      SurveyPointData(id: 'T1', name: 'Sudut Kiri Atas'),
      SurveyPointData(id: 'T2', name: 'Sudut Kanan Atas'),
      SurveyPointData(id: 'T3', name: 'Sudut Kiri Bawah'),
      SurveyPointData(id: 'T4', name: 'Sudut Kanan Bawah'),
      SurveyPointData(id: 'T5', name: 'Titik Tengah Petak'),
    ];
  }

  int get _completedSlotsCount {
    int count = 0;
    for (final pt in _points) {
      if (pt.isUnreachable) {
        count += 3;
      } else {
        if (pt.samples[StrataType.bawah] != null) count++;
        if (pt.samples[StrataType.tengah] != null) count++;
        if (pt.samples[StrataType.atas] != null) count++;
      }
    }
    return count;
  }

  bool get _isSurveyReady {
    return _points.every((pt) => pt.isComplete);
  }

  Future<void> _captureLeaf(
    SurveyPointData pt,
    StrataType strata,
    ImageSource source,
  ) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (file == null) return;

      setState(() {
        _isProcessing = true;
        _processingImagePath = file.path;
        _processingMessage =
            'Mendeteksi bercak ${strata.label} pada ${pt.id}...';
      });

      final resultFuture = TFLiteService.detectImage(file.path);
      final results = await Future.wait([
        resultFuture,
        Future.delayed(const Duration(milliseconds: 1600)),
      ]);
      final result = results.first as DetectionResult;

      if (!mounted) return;
      setState(() {
        _isProcessing = false;

        final sample = LeafPhotoSample(
          imagePath: file.path,
          strata: strata,
          spotCount: result.spotCount,
          diseaseName: result.primaryDiseaseLabel,
          confidence: result.predictions.isNotEmpty
              ? result.predictions.first.confidence
              : 1.0,
          boundingBoxes: result.predictions,
        );

        pt.samples[strata] = sample;

        // Update nilai Nb, Nt, Na
        if (strata == StrataType.bawah) {
          pt.nb = sample.spotCount;
        } else if (strata == StrataType.tengah) {
          pt.nt = sample.spotCount;
        } else if (strata == StrataType.atas) {
          pt.na = sample.spotCount;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memproses gambar: $e'),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    }
  }

  void _setZeroSample(SurveyPointData pt, StrataType strata) {
    setState(() {
      pt.samples[strata] = LeafPhotoSample(
        imagePath: '',
        strata: strata,
        spotCount: 0,
        diseaseName: 'Nihil / Tidak Ada Daun',
        confidence: 1.0,
        boundingBoxes: [],
      );
      if (strata == StrataType.bawah) pt.nb = 0;
      if (strata == StrataType.tengah) pt.nt = 0;
      if (strata == StrataType.atas) pt.na = 0;
    });
  }

  void _editSpotCountManual(SurveyPointData pt, StrataType strata) {
    final current = (strata == StrataType.bawah)
        ? pt.nb
        : (strata == StrataType.tengah)
            ? pt.nt
            : pt.na;

    final controller = TextEditingController(text: current.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B3D2B),
        title: Text(
          'Koreksi Manual: ${pt.id} - ${strata.label}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Jumlah Bercak Terlihat',
            labelStyle: TextStyle(color: Color(0xFF95D5B2)),
            filled: true,
            fillColor: Color(0xFF132A1C),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text.trim()) ?? 0;
              setState(() {
                if (strata == StrataType.bawah) pt.nb = val;
                if (strata == StrataType.tengah) pt.nt = val;
                if (strata == StrataType.atas) pt.na = val;

                if (pt.samples[strata] == null) {
                  pt.samples[strata] = LeafPhotoSample(
                    imagePath: '',
                    strata: strata,
                    spotCount: val,
                    diseaseName: 'Input Manual',
                    confidence: 1.0,
                    boundingBoxes: [],
                  );
                }
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D6A4F),
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _runDiagnosis() {
    final result = RuleEngineService.evaluateSurvey(points: _points);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SurveyResultScreen(result: result, points: _points),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_completedSlotsCount / 15).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF132A1C),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Survei Petak (Pola X 5 Titik)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Standar Protokol BIMA 2026',
              style: TextStyle(color: Color(0xFF95D5B2), fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reset Survei',
            icon: const Icon(Icons.restart_alt_rounded, color: Colors.white70),
            onPressed: () {
              setState(() {
                _initSurveyPoints();
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress Header Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF132A1C),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2D6A4F)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Kelengkapan Sampel Petak',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '$_completedSlotsCount / 15 Sampel',
                            style: const TextStyle(
                              color: Color(0xFF52B788),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF52B788),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 5 Points Accordion List
                for (int i = 0; i < _points.length; i++) ...[
                  _buildPointCard(_points[i], i),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 24),

                // Calculate Button
                ElevatedButton.icon(
                  onPressed: _isSurveyReady ? _runDiagnosis : null,
                  icon: const Icon(Icons.analytics_rounded),
                  label: Text(
                    _isSurveyReady
                        ? 'Proses Diagnosis Petak Sawah'
                        : 'Lengkapi 15 Sampel Terlebih Dahulu',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D6A4F),
                    disabledBackgroundColor: Colors.white12,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white38,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),

          // Animated Scanning Overlay
          if (_isProcessing)
            ScanningOverlay(
              message: _processingMessage,
              imagePath: _processingImagePath,
              subMessage: 'Pemeriksaan Strata Petak Sawah • AI On-Device',
            ),
        ],
      ),
    );
  }

  Widget _buildPointCard(SurveyPointData pt, int index) {
    final isExpanded = _expandedPointIndex == index;
    final isDone = pt.isComplete;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF132A1C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? const Color(0xFF52B788)
              : isDone
                  ? const Color(0xFF2D6A4F)
                  : Colors.white12,
          width: isExpanded ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          // Header Bar
          ListTile(
            onTap: () {
              setState(() {
                _expandedPointIndex = isExpanded ? -1 : index;
              });
            },
            leading: CircleAvatar(
              backgroundColor: isDone
                  ? const Color(0xFF2D6A4F)
                  : const Color(0xFF1B3D2B),
              child: Text(
                pt.id,
                style: TextStyle(
                  color: isDone ? Colors.white : const Color(0xFF52B788),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              '${pt.id} • ${pt.name}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              pt.isUnreachable
                  ? 'Ditandai: Tidak Terjangkau'
                  : 'Nb: ${pt.nb} | Nt: ${pt.nt} | Na: ${pt.na}',
              style: TextStyle(
                color: isDone ? const Color(0xFF95D5B2) : Colors.white54,
                fontSize: 11,
              ),
            ),
            trailing: Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: Colors.white70,
            ),
          ),

          // Expanded Content (3 Strata Slots)
          if (isExpanded) ...[
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _buildStrataSlot(pt, StrataType.bawah),
                  const SizedBox(height: 10),
                  _buildStrataSlot(pt, StrataType.tengah),
                  const SizedBox(height: 10),
                  _buildStrataSlot(pt, StrataType.atas),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStrataSlot(SurveyPointData pt, StrataType strata) {
    final sample = pt.samples[strata];
    final count = (strata == StrataType.bawah)
        ? pt.nb
        : (strata == StrataType.tengah)
            ? pt.nt
            : pt.na;

    final isFilled = sample != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3D2B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFilled ? const Color(0xFF2D6A4F) : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF132A1C),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              strata.code,
              style: const TextStyle(
                color: Color(0xFF52B788),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strata.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  isFilled
                      ? '$count bercak terdeteksi'
                      : 'Belum ada foto/input',
                  style: TextStyle(
                    color: isFilled
                        ? const Color(0xFF95D5B2)
                        : Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (isFilled) ...[
            IconButton(
              tooltip: 'Koreksi Nilai',
              icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white70),
              onPressed: () => _editSpotCountManual(pt, strata),
            ),
          ],
          PopupMenuButton<String>(
            color: const Color(0xFF132A1C),
            icon: Icon(
              isFilled ? Icons.more_vert : Icons.add_a_photo_outlined,
              color: isFilled ? Colors.white70 : const Color(0xFF52B788),
              size: 20,
            ),
            onSelected: (val) {
              if (val == 'camera') {
                _captureLeaf(pt, strata, ImageSource.camera);
              } else if (val == 'gallery') {
                _captureLeaf(pt, strata, ImageSource.gallery);
              } else if (val == 'zero') {
                _setZeroSample(pt, strata);
              } else if (val == 'manual') {
                _editSpotCountManual(pt, strata);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'camera',
                child: Row(
                  children: [
                    Icon(Icons.camera_alt, color: Color(0xFF52B788), size: 18),
                    SizedBox(width: 8),
                    Text('Ambil Kamera', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'gallery',
                child: Row(
                  children: [
                    Icon(Icons.photo_library, color: Color(0xFF52B788), size: 18),
                    SizedBox(width: 8),
                    Text('Pilih Galeri', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'zero',
                child: Row(
                  children: [
                    Icon(Icons.exposure_zero, color: Color(0xFFFBC02D), size: 18),
                    SizedBox(width: 8),
                    Text('Nihil (0 Daun/Bercak)', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'manual',
                child: Row(
                  children: [
                    Icon(Icons.edit_note, color: Colors.white70, size: 18),
                    SizedBox(width: 8),
                    Text('Koreksi Hitungan', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
