import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class ScanningOverlay extends StatefulWidget {
  final String message;
  final String? imagePath;
  final String? subMessage;

  const ScanningOverlay({
    super.key,
    required this.message,
    this.imagePath,
    this.subMessage,
  });

  @override
  State<ScanningOverlay> createState() => _ScanningOverlayState();
}

class _ScanningOverlayState extends State<ScanningOverlay>
    with TickerProviderStateMixin {
  late AnimationController _laserController;
  late AnimationController _radarController;
  late AnimationController _progressController;
  late AnimationController _targetLockController;

  late Animation<double> _laserAnimation;
  late Animation<double> _radarAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _targetLockAnimation;

  int _currentStepIndex = 0;
  final List<String> _scanSteps = [
    'Ekstraksi Citra & Normalisasi Tensors...',
    'Memindai Lesi & Karakteristik Bercak Daun...',
    'Menghitung Tingkat Keparahan Agromoni...',
    'Menyusun Rekomendasi PHT Presisi...',
  ];

  @override
  void initState() {
    super.initState();

    // 1. Laser Loop
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOutSine),
    );

    // 2. Radar Sweep Loop
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    _radarAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _radarController, curve: Curves.linear),
    );

    // 3. Simulated Progress 0% -> 100%
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();
    _progressAnimation = Tween<double>(begin: 0.08, end: 0.98).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    // 4. Target Lock Pulse
    _targetLockController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _targetLockAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(
          parent: _targetLockController, curve: Curves.easeInOutQuad),
    );

    _startStepCycler();
  }

  void _startStepCycler() async {
    for (int i = 0; i < _scanSteps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _currentStepIndex = i;
        });
      }
    }
  }

  @override
  void dispose() {
    _laserController.dispose();
    _radarController.dispose();
    _progressController.dispose();
    _targetLockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.92),
      width: double.infinity,
      height: double.infinity,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Top Sci-Fi Badge Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF132A1C),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0xFF52B788).withValues(alpha: 0.6),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF52B788).withValues(alpha: 0.25),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.radar_rounded, color: Color(0xFF52B788), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'AI NEURAL SCANNER • ACTIVE',
                    style: TextStyle(
                      color: Color(0xFF74C69D),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Futuristic HUD Viewfinder Box
            Center(
              child: SizedBox(
                width: 290,
                height: 290,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Rotating Radar Compass
                    AnimatedBuilder(
                      animation: _radarAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _radarAnimation.value,
                          child: Container(
                            width: 285,
                            height: 285,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF52B788)
                                    .withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                            child: CustomPaint(
                              painter: _RadarTicksPainter(),
                            ),
                          ),
                        );
                      },
                    ),

                    // Outer Glowing Ring Pulse
                    AnimatedBuilder(
                      animation: _targetLockAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _targetLockAnimation.value,
                          child: Container(
                            width: 270,
                            height: 270,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF52B788)
                                    .withValues(alpha: 0.35),
                                width: 1.5,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Main Image Frame
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1B13),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF52B788).withValues(alpha: 0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF52B788)
                                .withValues(alpha: 0.35),
                            blurRadius: 25,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Background Image
                          if (widget.imagePath != null &&
                              File(widget.imagePath!).existsSync())
                            Image.file(
                              File(widget.imagePath!),
                              fit: BoxFit.cover,
                            )
                          else
                            Center(
                              child: Icon(
                                Icons.eco_rounded,
                                size: 90,
                                color: const Color(0xFF52B788)
                                    .withValues(alpha: 0.25),
                              ),
                            ),

                          // Dynamic Grid Matrix
                          CustomPaint(
                            painter: _SciFiGridPainter(),
                          ),

                          // Animated Target Detection Locks (Simulating AI detection)
                          AnimatedBuilder(
                            animation: _targetLockAnimation,
                            builder: (context, child) {
                              return Stack(
                                children: [
                                  // Spot Target 1 (Center-Right)
                                  Positioned(
                                    top: 75,
                                    right: 50,
                                    child: _buildTargetLock(
                                      size: 44 * _targetLockAnimation.value,
                                      label: 'SPOT #1 96.4%',
                                      color: const Color(0xFFFFB703),
                                    ),
                                  ),
                                  // Spot Target 2 (Bottom-Left)
                                  Positioned(
                                    bottom: 50,
                                    left: 60,
                                    child: _buildTargetLock(
                                      size: 40 * _targetLockAnimation.value,
                                      label: 'SPOT #2 93.1%',
                                      color: const Color(0xFF52B788),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          // Sweeping Scanning Laser Beam
                          AnimatedBuilder(
                            animation: _laserAnimation,
                            builder: (context, child) {
                              return Positioned(
                                top: _laserAnimation.value * 230,
                                left: 0,
                                right: 0,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Laser Glow Trail
                                    Container(
                                      height: 38,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            const Color(0xFF52B788)
                                                .withValues(alpha: 0.0),
                                            const Color(0xFF52B788)
                                                .withValues(alpha: 0.45),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Ultra-Bright Neon Core Line
                                    Container(
                                      height: 3.5,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFB7E4C7),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0xFF52B788),
                                            blurRadius: 14,
                                            spreadRadius: 3,
                                          ),
                                          BoxShadow(
                                            color: Colors.white,
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          // Reticle Frame Corners
                          CustomPaint(
                            painter: _TechCornersPainter(
                              color: const Color(0xFF52B788),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Live Progress & Telemetry Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF132A1C).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF2D6A4F),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Step Message with Animated Switcher
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Row(
                        key: ValueKey<int>(_currentStepIndex),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF52B788)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              _scanSteps[_currentStepIndex],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Progress Bar
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: _progressAnimation.value,
                                minHeight: 6,
                                backgroundColor: const Color(0xFF1B3D2B),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF52B788)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.subMessage ??
                                      'EDGE AI • 100% OFFLINE INFERENCE',
                                  style: const TextStyle(
                                    color: Color(0xFF95D5B2),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${(_progressAnimation.value * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: Color(0xFF52B788),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetLock({
    required double size,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 1.8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _RadarTicksPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = const Color(0xFF52B788).withValues(alpha: 0.45)
      ..strokeWidth = 1.5;

    for (int i = 0; i < 16; i++) {
      final angle = (i * math.pi / 8);
      final p1 = Offset(
        center.dx + (radius - 8) * math.cos(angle),
        center.dy + (radius - 8) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TechCornersPainter extends CustomPainter {
  final Color color;

  _TechCornersPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 24.0;
    const pad = 8.0;

    // Top-Left
    canvas.drawLine(const Offset(pad, pad + len), const Offset(pad, pad), paint);
    canvas.drawLine(const Offset(pad, pad), const Offset(pad + len, pad), paint);

    // Top-Right
    canvas.drawLine(
        Offset(size.width - pad - len, pad), Offset(size.width - pad, pad), paint);
    canvas.drawLine(
        Offset(size.width - pad, pad), Offset(size.width - pad, pad + len), paint);

    // Bottom-Left
    canvas.drawLine(Offset(pad, size.height - pad - len),
        Offset(pad, size.height - pad), paint);
    canvas.drawLine(Offset(pad, size.height - pad),
        Offset(pad + len, size.height - pad), paint);

    // Bottom-Right
    canvas.drawLine(Offset(size.width - pad - len, size.height - pad),
        Offset(size.width - pad, size.height - pad), paint);
    canvas.drawLine(Offset(size.width - pad, size.height - pad),
        Offset(size.width - pad, size.height - pad - len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SciFiGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF52B788).withValues(alpha: 0.12)
      ..strokeWidth = 1.0;

    const step = 20.0;
    for (double x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
