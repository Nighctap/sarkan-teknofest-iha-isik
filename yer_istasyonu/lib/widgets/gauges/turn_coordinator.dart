import 'dart:math';
import 'package:flutter/material.dart';

class TurnCoordinatorWidget extends StatelessWidget {
  final double turnRate; // Proportional to rate of turn (standard rate = ?)
  final double slip; // -1.0 to 1.0 (Skid/Slip)
  final double pitch; // new field
  const TurnCoordinatorWidget({super.key, required this.turnRate, required this.slip, required this.pitch});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Safe size calculation
                double size = min(constraints.maxWidth, constraints.maxHeight);
                if (size.isInfinite) size = 200.0;

                return Center(
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Match Compass gradient background
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1a2332), Color(0xFF0d1217)],
                      ),
                      // Match Compass Border and Shadow
                      border: Border.all(color: const Color(0xFF00d4ff).withOpacity(0.3), width: 3),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF00d4ff).withOpacity(0.2), blurRadius: 20, spreadRadius: 2),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8), // Inner padding like Compass
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF131920), // Inner dark circle
                          border: Border.all(color: const Color(0xFF00d4ff).withOpacity(0.2), width: 2),
                        ),
                        child: CustomPaint(
                          painter: TurnCoordinatorPainter(turnRate: turnRate, slip: slip),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF00d4ff).withOpacity(0.3)),
            ),
            child: Text(
              '${pitch.toStringAsFixed(0)}°',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00d4ff),
                shadows: [Shadow(color: Color(0xFF00d4ff), blurRadius: 10)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TurnCoordinatorPainter extends CustomPainter {
  final double turnRate;
  final double slip;

  TurnCoordinatorPainter({required this.turnRate, required this.slip});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Markings (L, R, D.C. ELEC, etc.) =====================================
    final textColor = const Color(0xFF00d4ff).withOpacity(0.9); // Cyan text

    // "L"
    final textStyle = TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'monospace');
    _drawText(canvas, center, radius, 'L', -0.75, 0.1, textStyle);

    // "R"
    _drawText(canvas, center, radius, 'R', 0.65, 0.1, textStyle); // Adjusted R position

    // Labels
    final labelStyle = TextStyle(
      color: textColor.withOpacity(0.7),
      fontSize: 10,
      fontWeight: FontWeight.bold,
      fontFamily: 'monospace',
    );
    _drawTextCentered(canvas, center, radius, 'D.C. ELEC.', -0.7, labelStyle);
    // Labels
    _drawTextCentered(canvas, center, radius, 'D.C. ELEC.', -0.7, labelStyle);
    // Removed NO PITCH INFORMATION lines

    // Standard Rate Turn Indices (The notches) ================================
    final markPaint = Paint()
      ..color =
          const Color(0xFF00d4ff) // Cyan Notches
      ..strokeWidth =
          3 // Slightly thinner for cleaner look
      ..strokeCap = StrokeCap.round;

    // Level marks
    canvas.drawLine(
      Offset(center.dx - radius * 0.9, center.dy),
      Offset(center.dx - radius * 0.75, center.dy),
      markPaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius * 0.9, center.dy),
      Offset(center.dx + radius * 0.75, center.dy),
      markPaint,
    );

    // Bank marks (Standard Rate)
    // Left Bank notch
    canvas.drawLine(
      Offset(center.dx - radius * 0.9, center.dy + radius * 0.25),
      Offset(center.dx - radius * 0.75, center.dy + radius * 0.25),
      markPaint,
    );
    // Right Bank notch
    canvas.drawLine(
      Offset(center.dx + radius * 0.9, center.dy + radius * 0.25),
      Offset(center.dx + radius * 0.75, center.dy + radius * 0.25),
      markPaint,
    );

    // 2. Inclinometer (The Ball) =============================================
    final tubeRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + radius * 0.45), // Moved up slightly
      width: radius * 1.0,
      height: radius * 0.2,
    );

    // Tube Background
    final tubePaint = Paint()..color = Colors.black.withOpacity(0.6);
    final tubePath = Path()
      ..moveTo(tubeRect.left, tubeRect.top)
      ..quadraticBezierTo(tubeRect.center.dx, tubeRect.top + 5, tubeRect.right, tubeRect.top)
      ..lineTo(tubeRect.right, tubeRect.bottom)
      ..quadraticBezierTo(tubeRect.center.dx, tubeRect.bottom + 5, tubeRect.left, tubeRect.bottom)
      ..close();
    canvas.drawPath(tubePath, tubePaint);

    // Cage Lines (Center box)
    final cagePaint = Paint()
      ..color = const Color(0xFF00d4ff).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    double cageWidth = radius * 0.14;
    canvas.drawRect(
      Rect.fromCenter(center: tubeRect.center, width: cageWidth, height: tubeRect.height * 0.8),
      cagePaint,
    );

    // The Ball
    double visualSlip = slip.clamp(-1.0, 1.0);
    double ballX = center.dx + (visualSlip * (radius * 0.4));
    double ballY = tubeRect.center.dy + (visualSlip * visualSlip * 3); // Parabolic movement

    // Ball Glow
    canvas.drawCircle(Offset(ballX, ballY), radius * 0.08, Paint()..color = const Color(0xFF00d4ff).withOpacity(0.3));
    // Ball Core
    canvas.drawCircle(Offset(ballX, ballY), radius * 0.06, Paint()..color = Colors.white);

    // 3. Airplane Symbol (Rotates) ===========================================
    canvas.save();
    canvas.translate(center.dx, center.dy);

    double rotationAngle = turnRate.clamp(-45.0, 45.0) * pi / 180;
    canvas.rotate(rotationAngle);

    final planePaint = Paint()
      ..color =
          const Color(0xFF00d4ff) // Cyan Plane
      ..strokeWidth = 3
      ..style = PaintingStyle.fill;

    final planePath = Path();

    // Fuselage (Sleeker)
    planePath.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: radius * 0.7, height: radius * 0.06),
        const Radius.circular(4),
      ),
    );

    // Vertical Stabilizer
    planePath.addRect(Rect.fromCenter(center: Offset(0, -radius * 0.08), width: radius * 0.04, height: radius * 0.16));

    canvas.drawPath(planePath, planePaint);
    canvas.drawPath(
      planePath,
      Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    ); // Highlight

    canvas.restore();
  }

  void _drawText(
    Canvas canvas,
    Offset center,
    double radius,
    String text,
    double xFactor,
    double yFactor,
    TextStyle style,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(
      canvas,
      Offset(center.dx + (radius * xFactor) - tp.width / 2, center.dy + (radius * yFactor) - tp.height / 2),
    );
  }

  void _drawTextCentered(Canvas canvas, Offset center, double radius, String text, double vPos, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy + (radius * vPos) - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant TurnCoordinatorPainter oldDelegate) {
    return oldDelegate.turnRate != turnRate || oldDelegate.slip != slip;
  }
}
