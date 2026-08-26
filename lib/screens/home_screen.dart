import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/detection_result.dart';
import '../services/tflite_service.dart';
import '../widgets/scanning_overlay.dart';
import 'result_screen.dart';
import 'survey_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String _loadingMessage = '';
  String? _scanningImagePath;

  @override
  void initState() {
    super.initState();
    TFLiteService.init().catchError((e) {
      debugPrint('Error init TFLite: $e');
    });
  }

  Future<void> _processQuickScan(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (pickedFile == null) return;

      setState(() {
        _isLoading = true;
        _scanningImagePath = pickedFile.path;
        _loadingMessage =
            'Menganalisis lesi daun via ${TFLiteService.activeModelName} (Edge AI Offline)...';
      });

      final resultFuture = TFLiteService.detectImage(pickedFile.path);
      final results = await Future.wait([
        resultFuture,
        Future.delayed(const Duration(milliseconds: 1800)),
      ]);
      final result = results.first as DetectionResult;

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultScreen(result: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B3D2B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Color(0xFFE53935)),
            SizedBox(width: 8),
            Text('Gagal Menganalisis',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Text(
          error,
          style: const TextStyle(
              color: Color(0xFFD8F3DC), fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF132A1C),
        elevation: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/logo.png',
                width: 30,
                height: 30,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1B4332),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco_rounded,
                      color: Color(0xFF52B788), size: 18),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RADAR',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2),
                ),
                Text(
                  'Rice Anomaly Detection and Assessment Recognition',
                  style: TextStyle(fontSize: 9, color: Color(0xFF95D5B2)),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Primary Hero Card: Survei Petak 5 Titik (Main Mode)
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SurveyScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2D6A4F), Color(0xFF1B4332)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2D6A4F).withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFF52B788),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF52B788),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'METODE UTAMA',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white70,
                              size: 16,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Survei Petak Sawah (Pola X 5 Titik)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Ambil sampel 5 titik rumpun x 3 strata daun untuk mendapatkan status ambang ekonomi petak (Level 0-4) dan rekomendasi PHT resmi.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFD8F3DC),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildFeatureBadge(
                                Icons.grid_view_rounded, 'Pola Diagonal X'),
                            const SizedBox(width: 8),
                            _buildFeatureBadge(
                                Icons.calculate_outlined, 'Pure Rule Engine'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Secondary Mode: Quick Leaf Scan
                const Text(
                  'Mode Pemeriksaan Cepat',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB7E4C7),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.camera_alt_rounded,
                        title: 'Kamera Cepat',
                        subtitle: 'Scan 1 helai daun',
                        color: const Color(0xFF1B3D2B),
                        onTap: () => _processQuickScan(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.photo_library_rounded,
                        title: 'Galeri Cepat',
                        subtitle: 'Pilih 1 foto daun',
                        color: const Color(0xFF132A1C),
                        onTap: () => _processQuickScan(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Model AI Engine Status & Selector
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF132A1C),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.tune_rounded,
                              color: Color(0xFF52B788), size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Arsitektur Model AI (100% On-Device)',
                            style: TextStyle(
                              color: Color(0xFFB7E4C7),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _buildModelChoiceCard(
                                title: 'YOLOv11',
                                subtitle: 'Nano • Float16',
                                icon: Icons.flash_on_rounded,
                                isSelected: TFLiteService.activeModel ==
                                    OfflineModel.yoloV11,
                                onTap: () {
                                  setState(() {
                                    TFLiteService.activeModel =
                                        OfflineModel.yoloV11;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildModelChoiceCard(
                                title: 'RF-DETR',
                                subtitle: 'ViT • Transformer',
                                icon: Icons.remove_red_eye_rounded,
                                isSelected: TFLiteService.activeModel ==
                                    OfflineModel.rfDetr,
                                onTap: () {
                                  setState(() {
                                    TFLiteService.activeModel =
                                        OfflineModel.rfDetr;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Daftar Penyakit
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF132A1C),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kategori Penyakit yang Dikenali',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDiseaseItem('Bercak Cokelat', 'Brown Spot',
                          const Color(0xFFE65100)),
                      const Divider(color: Colors.white10, height: 14),
                      _buildDiseaseItem('Hawar Pelepah', 'Sheath Blight',
                          const Color(0xFFF57F17)),
                      const Divider(color: Colors.white10, height: 14),
                      _buildDiseaseItem('Penyakit Tungro', 'Tungro Virus',
                          const Color(0xFFD50000)),
                      const Divider(color: Colors.white10, height: 14),
                      _buildDiseaseItem('Penyakit Blas', 'Pyricularia oryzae',
                          const Color(0xFFC2185B)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Animated Scanning Overlay
          if (_isLoading)
            ScanningOverlay(
              message: _loadingMessage,
              imagePath: _scanningImagePath,
              subMessage: 'Inferensi On-Device Float16 • ${TFLiteService.activeModelName}',
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF95D5B2)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD8F3DC),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelChoiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D6A4F) : const Color(0xFF1B3D2B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF52B788) : Colors.white12,
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF95D5B2) : Colors.white60,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFFD8F3DC)
                          : Colors.white54,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseItem(String name, String latin, Color badgeColor) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          latin,
          style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}
