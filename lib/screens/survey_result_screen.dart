import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/survey_models.dart';
import '../services/report_export_service.dart';

class SurveyResultScreen extends StatelessWidget {
  final RuleEngineResult result;
  final List<SurveyPointData> points;

  const SurveyResultScreen({
    super.key,
    required this.result,
    required this.points,
  });

  Color _getLevelColor(int level) {
    switch (level) {
      case 0:
        return const Color(0xFF2E7D32); // Green (Sehat)
      case 1:
        return const Color(0xFF43A047); // Light Green (Di bawah ambang)
      case 2:
        return const Color(0xFFFBC02D); // Yellow-Amber (Mendekati ambang)
      case 3:
        return const Color(0xFFFB8C00); // Orange (Melampaui ambang)
      case 4:
      default:
        return const Color(0xFFE53935); // Red (Serangan Sangat Tinggi)
    }
  }

  void _showDownloadDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF132A1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.download_rounded,
                    color: Color(0xFF52B788), size: 22),
                SizedBox(width: 10),
                Text(
                  'Unduh File Laporan Diagnosis',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildExportOptionTile(
              icon: Icons.description_rounded,
              title: 'Laporan Teks Lengkap (.txt)',
              subtitle: 'Format formal laporan PHT & rekomendasi agronomi',
              onTap: () {
                Navigator.pop(ctx);
                _downloadFile(context, isJson: false);
              },
            ),
            const SizedBox(height: 10),
            _buildExportOptionTile(
              icon: Icons.data_object_rounded,
              title: 'Dataset Terstruktur (.json)',
              subtitle: 'Data JSON untuk integrasi sistem / arsip riset',
              onTap: () {
                Navigator.pop(ctx);
                _downloadFile(context, isJson: true);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1B3D2B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2D6A4F)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF52B788).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF52B788), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style:
                        const TextStyle(color: Colors.white60, fontSize: 10.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.download_rounded,
                color: Color(0xFF52B788), size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadFile(BuildContext context, {required bool isJson}) async {
    try {
      final file = await ReportExportService.saveReportToFile(
        result: result,
        points: points,
        isJson: isJson,
      );

      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1B3D2B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: Color(0xFF52B788), size: 24),
              SizedBox(width: 8),
              Text(
                'File Berhasil Diunduh!',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Laporan berhasil disimpan ke penyimpanan HP:',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF132A1C),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2D6A4F)),
                ),
                child: SelectableText(
                  file.path,
                  style: const TextStyle(
                    color: Color(0xFFD8F3DC),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('Tutup', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan file: $e'),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final levelColor = _getLevelColor(result.level);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF132A1C),
        elevation: 0,
        title: const Text(
          'Hasil Diagnosis Petak Sawah',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Level Hero Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    levelColor.withValues(alpha: 0.25),
                    const Color(0xFF1B3D2B),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: levelColor, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: levelColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'LEVEL ${result.level}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          'Kode: ${result.fullCode}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    result.levelTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        result.isTurunan
                            ? Icons.info_outline
                            : Icons.verified_outlined,
                        color: const Color(0xFF95D5B2),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        result.isTurunan
                            ? 'Sumber Matriks: Sel Turunan (Usulan BIMA 2026)'
                            : 'Sumber Matriks: Tabel Acuan Ahli Pertanian',
                        style: const TextStyle(
                          color: Color(0xFF95D5B2),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Hotspot Warning Banner (Langkah 5b)
            if (result.peringatanHotspot) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3E1F1F),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE53935)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFE53935),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Peringatan Titik Parah (Hotspot Alert)',
                            style: TextStyle(
                              color: Color(0xFFFF8A80),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ditemukan serangan tinggi pada titik: ${result.hotspotTitikList.join(', ')}. Waspadai potensi perluasan dari titik ini.',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Intensitas Koreksi Banner (Langkah 5a)
            if (result.intensitasTerkoreksi) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C3E26),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFBC02D)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_graph, color: Color(0xFFFBC02D), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Level dinaikkan dari Level 1 ke Level 2 karena intensitas luas bercak >= 2.7%.',
                        style: TextStyle(
                          color: Color(0xFFFFF9C4),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Rincian 4 Parameter Dasar
            const Text(
              'Rincian Parameter Survei 5 Titik',
              style: TextStyle(
                color: Color(0xFFB7E4C7),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF132A1C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2D6A4F)),
              ),
              child: Column(
                children: [
                  _buildParamRow(
                    code: 'A',
                    label: 'Rata-rata bercak daun bawah (Nb)',
                    value: result.a.toStringAsFixed(1),
                    badge: result.kodeK == 'K1' ? 'Padat (K1)' : 'Rendah (K0)',
                    badgeColor: result.kodeK == 'K1'
                        ? const Color(0xFFE53935)
                        : const Color(0xFF43A047),
                  ),
                  const Divider(color: Colors.white10, height: 20),
                  _buildParamRow(
                    code: 'B',
                    label: 'Titik daun atas terinfeksi (Na >= 1)',
                    value: '${result.b} / 5 titik',
                    badge: result.b >= 2 ? 'S4 (Daun Atas)' : '-',
                    badgeColor: const Color(0xFFE53935),
                  ),
                  const Divider(color: Colors.white10, height: 20),
                  _buildParamRow(
                    code: 'C',
                    label: 'Titik daun tengah berat (Nt > 10)',
                    value: '${result.c} / 5 titik',
                    badge: result.c >= 2 ? 'S3 (Tengah Berat)' : '-',
                    badgeColor: const Color(0xFFFB8C00),
                  ),
                  const Divider(color: Colors.white10, height: 20),
                  _buildParamRow(
                    code: 'D',
                    label: 'Titik daun tengah ringan (Nt >= 1)',
                    value: '${result.d} / 5 titik',
                    badge: result.d >= 2 ? 'S2 (Tengah Ringan)' : '-',
                    badgeColor: const Color(0xFFFBC02D),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Jejak Perhitungan 5 Langkah (Sesuai PRD)
            const Text(
              'Jejak Perhitungan Sistem (5 Langkah BIMA 2026)',
              style: TextStyle(
                color: Color(0xFFB7E4C7),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF132A1C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2D6A4F).withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepLog('Langkah 1 (4 Angka Dasar)', result.langkah1Log),
                  const Divider(color: Colors.white10, height: 16),
                  _buildStepLog('Langkah 2 (Kode Kepadatan K)', result.langkah2Log),
                  const Divider(color: Colors.white10, height: 16),
                  _buildStepLog('Langkah 3 (Kode Sebaran S)', result.langkah3Log),
                  const Divider(color: Colors.white10, height: 16),
                  _buildStepLog('Langkah 4 (Matriks K × S)', result.langkah4Log),
                  const Divider(color: Colors.white10, height: 16),
                  _buildStepLog('Langkah 5 (Koreksi & Hotspot)', result.langkah5Log),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Rekomendasi PHT
            const Text(
              'Rekomendasi Tindakan Pengendalian (PHT)',
              style: TextStyle(
                color: Color(0xFFB7E4C7),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF132A1C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2D6A4F)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < result.rekomendasi.length; i++) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: levelColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            result.rekomendasi[i],
                            style: const TextStyle(
                              color: Color(0xFFD8F3DC),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (i < result.rekomendasi.length - 1)
                      const SizedBox(height: 12),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Rekap 5 Titik Pola X
            const Text(
              'Data Mentah 5 Titik Survei',
              style: TextStyle(
                color: Color(0xFFB7E4C7),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF132A1C),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: points.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: Colors.white10, height: 1),
                itemBuilder: (context, index) {
                  final pt = points[index];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF1B3D2B),
                      child: Text(
                        pt.id,
                        style: const TextStyle(
                          color: Color(0xFF52B788),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      pt.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      pt.isUnreachable
                          ? 'Tidak Terjangkau (${pt.unreachableReason})'
                          : 'Nb: ${pt.nb} | Nt: ${pt.nt} | Na: ${pt.na}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    trailing: Text(
                      pt.isUnreachable ? '-' : '${pt.totalSpots} bercak',
                      style: const TextStyle(
                        color: Color(0xFF95D5B2),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showDownloadDialog(context),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Download Hasil'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF52B788),
                          foregroundColor: const Color(0xFF0D1B13),
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final summaryText = ReportExportService.generateTextSummary(
                            result: result,
                            points: points,
                          );
                          Clipboard.setData(ClipboardData(text: summaryText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ringkasan laporan berhasil disalin ke clipboard!'),
                              backgroundColor: Color(0xFF2D6A4F),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Salin Teks'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF95D5B2),
                          side: const BorderSide(color: Color(0xFF52B788)),
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Kembali ke Survei'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildParamRow({
    required String code,
    required String label,
    required String value,
    required String badge,
    required Color badgeColor,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF1B3D2B),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            code,
            style: const TextStyle(
              color: Color(0xFF52B788),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        if (badge != '-')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeColor),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStepLog(String stepTitle, String logText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stepTitle,
          style: const TextStyle(
            color: Color(0xFF52B788),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          logText,
          style: const TextStyle(
            color: Color(0xFFD8F3DC),
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
