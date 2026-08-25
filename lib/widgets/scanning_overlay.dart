import 'dart:io';
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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scanAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _glowAnimation = Tween<double>(begin: 0.4, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      width: double.infinity,
      height: double.infinity,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Elegant Viewfinder
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      color: const Color(0xFF132A1C),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF52B788)
                              .withValues(alpha: _glowAnimation.value * 0.3),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFF52B788)
                            .withValues(alpha: _glowAnimation.value),
                        width: 1.5,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Leaf Image Preview
                        if (widget.imagePath != null &&
                            File(widget.imagePath!).existsSync())
                          Image.file(
                            File(widget.imagePath!),
                            fit: BoxFit.cover,
                          )
                        else
                          const Center(
                            child: Icon(
                              Icons.eco_rounded,
                              size: 72,
                              color: Color(0xFF52B788),
                            ),
                          ),

                        // Soft Vignette Overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.35),
                              ],
                              radius: 0.85,
                            ),
                          ),
                        ),

                        // Smooth Glowing Laser Line
                        Positioned(
                          top: _scanAnimation.value * 230,
                          left: 0,
                          right: 0,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Laser Trail
                              Container(
                                height: 28,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      const Color(0xFF52B788)
                                          .withValues(alpha: 0.0),
                                      const Color(0xFF52B788)
                                          .withValues(alpha: 0.30),
                                    ],
                                  ),
                                ),
                              ),
                              // Laser Beam Line
                              Container(
                                height: 2.5,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0xFF52B788),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Minimal Corner Brackets
                        CustomPaint(
                          painter: _ElegantCornerPainter(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Clean & Elegant Status Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF132A1C),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF2D6A4F),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF52B788),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Memindai Daun Padi...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    if (widget.subMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.subMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF95D5B2),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ElegantCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF74C69D)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 18.0;
    const pad = 12.0;

    // Top-Left
    canvas.drawLine(
        const Offset(pad, pad + len), const Offset(pad, pad), paint);
    canvas.drawLine(
        const Offset(pad, pad), const Offset(pad + len, pad), paint);

    // Top-Right
    canvas.drawLine(Offset(size.width - pad - len, pad),
        Offset(size.width - pad, pad), paint);
    canvas.drawLine(Offset(size.width - pad, pad),
        Offset(size.width - pad, pad + len), paint);

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
