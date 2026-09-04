import 'dart:math' as math;
import 'package:flutter/material.dart';

class ReadoraLogo extends StatelessWidget {
  final double fontSize;
  const ReadoraLogo({super.key, this.fontSize = 48});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Glow halo behind the text
            Text(
              'Readora',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = fontSize * 0.06
                  ..color = Colors.white.withOpacity(0.08)
                  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
                letterSpacing: 3.0,
              ),
            ),
            // Split-color gradient text (main visual)
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFFFFFFFF), // bright white top
                  Color(0xFFE8C97A), // warm golden mid
                  Color(0xFFFFFFFF), // bright white
                  Color(0xFFA8D8EA), // cool blue-silver bottom
                ],
                stops: [0.0, 0.35, 0.55, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'Readora',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                  letterSpacing: 3.0,
                ),
              ),
            ),
            // Diagonal glare/slash cut across the text
            Positioned.fill(
              child: ClipRect(
                child: Align(
                  alignment: Alignment.center,
                  child: Transform.rotate(
                    angle: -math.pi / 12,
                    child: Container(
                      width: fontSize * 0.5,
                      height: fontSize * 3.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.18),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Glowing curved underline arc
        SizedBox(
          width: fontSize * 4.8,
          height: fontSize * 0.3,
          child: CustomPaint(
            painter: _ArcUnderlinePainter(fontSize: fontSize),
          ),
        ),
      ],
    );
  }
}

class _ArcUnderlinePainter extends CustomPainter {
  final double fontSize;
  const _ArcUnderlinePainter({required this.fontSize});

  @override
  void paint(Canvas canvas, Size size) {
    // Glowing outer arc
    final glowPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFFE8C97A).withOpacity(0.5),
          Colors.white.withOpacity(0.9),
          const Color(0xFFA8D8EA).withOpacity(0.5),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = fontSize * 0.05
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final sharpPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Colors.transparent,
          Color(0xFFE8C97A),
          Colors.white,
          Color(0xFFA8D8EA),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = fontSize * 0.03
      ..style = PaintingStyle.stroke;

    final arcRect = Rect.fromLTWH(
      size.width * 0.05,
      -size.height * 0.5,
      size.width * 0.9,
      size.height * 3,
    );
    const startAngle = math.pi * 0.05;
    const sweepAngle = math.pi * 0.9;

    canvas.drawArc(arcRect, startAngle, sweepAngle, false, glowPaint);
    canvas.drawArc(arcRect, startAngle, sweepAngle, false, sharpPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
