import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/tflite_service.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String _loadingMessage = '';

  @override
  void initState() {
    super.initState();
    TFLiteService.init().catchError((e) {
      debugPrint('Error init TFLite: $e');
    });
  }

  Future<void> _processImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (pickedFile == null) return;

      setState(() {
        _isLoading = true;
        _loadingMessage =
            'Menganalisis lesi daun via ${TFLiteService.activeModelName} (Edge AI Offline)...';
      });

      final result = await TFLiteService.detectImage(pickedFile.path);

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
            Text('Gagal Menganalisis', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Text(
          error,
          style: const TextStyle(color: Color(0xFFD8F3DC), fontSize: 13, height: 1.4),
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
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF1B4332),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.eco_rounded, color: Color(0xFF52B788), size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'RiceLeaf AI',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                // Status Bar Offline Engine
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B3D2B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2D6A4F)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.offline_bolt_rounded,
                        color: Color(0xFF52B788),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aktif: ${TFLiteService.activeModelName} (100% Offline)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const Text(
                              'Inferensi lokal di memori HP tanpa koneksi server',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Model Switcher Selector
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF132A1C),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2D6A4F).withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.tune_rounded, color: Color(0xFF52B788), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Pilih Arsitektur Model AI (On-Device)',
                            style: TextStyle(
                              color: Color(0xFFB7E4C7),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildModelChoiceCard(
                              title: 'YOLOv11',
                              subtitle: 'Nano • Float16 (640x640)',
                              icon: Icons.flash_on_rounded,
                              isSelected: TFLiteService.activeModel == OfflineModel.yoloV11,
                              onTap: () {
                                setState(() {
                                  TFLiteService.activeModel = OfflineModel.yoloV11;
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
                              isSelected: TFLiteService.activeModel == OfflineModel.rfDetr,
                              onTap: () {
                                setState(() {
                                  TFLiteService.activeModel = OfflineModel.rfDetr;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Hero Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2D6A4F).withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Diagnosa Penyakit Daun Padi Langsung di Sawah',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Menggunakan model ${TFLiteService.activeModelName} untuk mendeteksi lesi bercak secara offline, menghitung keparahan, serta rekomendasi penanganan.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFD8F3DC),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Mulai Analisis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB7E4C7),
                  ),
                ),
                const SizedBox(height: 14),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.camera_alt_rounded,
                        title: 'Kamera',
                        subtitle: 'Ambil foto daun langsung',
                        color: const Color(0xFF2D6A4F),
                        onTap: () => _processImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.photo_library_rounded,
                        title: 'Galeri',
                        subtitle: 'Pilih foto dari galeri',
                        color: const Color(0xFF1B4332),
                        onTap: () => _processImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Penyakit yang Didukung Card
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
                        'Kategori Penyakit Terdeteksi',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDiseaseItem('Bercak Cokelat', 'Brown Spot', const Color(0xFFE65100)),
                      const Divider(color: Colors.white10, height: 16),
                      _buildDiseaseItem('Hawar Pelepah', 'Sheath Blight', const Color(0xFFF57F17)),
                      const Divider(color: Colors.white10, height: 16),
                      _buildDiseaseItem('Penyakit Tungro', 'Tungro Virus', const Color(0xFFD50000)),
                      const Divider(color: Colors.white10, height: 16),
                      _buildDiseaseItem('Penyakit Blas', 'Pyricularia oryzae', const Color(0xFFC2185B)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.75),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF132A1C),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2D6A4F)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF52B788)),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _loadingMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
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
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF95D5B2) : Colors.white60,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFD8F3DC) : Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF52B788), size: 16),
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
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
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          latin,
          style: const TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}
