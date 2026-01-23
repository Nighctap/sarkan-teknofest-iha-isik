// ignore_for_file: unused_local_variable

import 'dart:math';
import 'package:flutter/material.dart';

class AttitudeIndicator extends StatelessWidget {
  final double roll; // in degrees
  final double pitch; // in degrees

  const AttitudeIndicator({super.key, required this.roll, required this.pitch});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double size = min(constraints.maxWidth, constraints.maxHeight);
        if (size.isInfinite) size = 300.0; // Fallback to prevent layout errors
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: AttitudePainter(roll: roll, pitch: pitch),
            child: const Center(),
          ),
        );
      },
    );
  }
}

class AttitudePainter extends CustomPainter {
  final double roll;
  final double pitch;

  AttitudePainter({required this.roll, required this.pitch});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Clip circle
    final path = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.clipPath(path);

    // Transform for roll/pitch
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-roll * pi / 180);

    // Pitch scaling: 10 degrees = 20% of radius (approx)
    final pitchOffset = (pitch * radius) / 45.0; // 45 degrees fills half screen
    canvas.translate(0, pitchOffset);

    // Sky (Blue)
    final skyPaint = Paint()..color = const Color(0xFF3e95cd);
    canvas.drawRect(Rect.fromLTRB(-radius * 2, -radius * 2, radius * 2, 0), skyPaint);

    // Ground (Brown)
    final groundPaint = Paint()..color = const Color(0xFF8c5b3e);
    canvas.drawRect(Rect.fromLTRB(-radius * 2, 0, radius * 2, radius * 2), groundPaint);

    // Horizon Line
    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;
    canvas.drawLine(Offset(-radius * 2, 0), Offset(radius * 2, 0), linePaint);

    // Pitch Ladders
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 10; i <= 90; i += 10) {
      if (i % 10 == 0) {
        // Sky ladder
        double y = -i * (radius / 45.0);
        double w = (i % 20 == 0) ? radius * 0.4 : radius * 0.2;
        canvas.drawLine(Offset(-w / 2, y), Offset(w / 2, y), linePaint);

        // Ground ladder
        y = i * (radius / 45.0);
        canvas.drawLine(Offset(-w / 2, y), Offset(w / 2, y), linePaint);
      }
    }

    canvas.restore(); // Undo roll/pitch transform for static elements

    // Aircraft Symbol (Fixed in center)
    final aircraftPaint = Paint()
      ..color =
          const Color(0xFFFFFF00) // Yellow
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final wingPath = Path(); // simple gull-wing shape or lines
    // Center point
    canvas.drawCircle(center, 2, Paint()..color = const Color(0xFFFFFF00));

    // Wings
    // Left Wing
    canvas.drawLine(
      Offset(center.dx - radius * 0.5, center.dy),
      Offset(center.dx - radius * 0.15, center.dy),
      aircraftPaint,
    );
    // Left Wing Down
    canvas.drawLine(
      Offset(center.dx - radius * 0.15, center.dy),
      Offset(center.dx - radius * 0.15, center.dy + radius * 0.05),
      aircraftPaint,
    );

    // Right Wing
    canvas.drawLine(
      Offset(center.dx + radius * 0.5, center.dy),
      Offset(center.dx + radius * 0.15, center.dy),
      aircraftPaint,
    );
    // Right Wing Down
    canvas.drawLine(
      Offset(center.dx + radius * 0.15, center.dy),
      Offset(center.dx + radius * 0.15, center.dy + radius * 0.05),
      aircraftPaint,
    );

    // Bank Scale (Top)
    final bankPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw arc
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius * 0.9), -pi / 2 - pi / 6, pi / 3, false, bankPaint);

    // Bank ticks: 0, 10, 20, 30, 45, 60
    final bankAngles = [0, 10, 20, 30, 45, 60];
    for (var angle in bankAngles) {
      _drawBankTick(canvas, center, radius, angle);
      if (angle != 0) _drawBankTick(canvas, center, radius, -angle);
    }
  }

  void _drawBankTick(Canvas canvas, Offset center, double radius, int angle) {
    final rad = (angle - 90) * pi / 180;
    final tickLen = radius * 0.1;
    final p1 = Offset(center.dx + radius * 0.9 * cos(rad), center.dy + radius * 0.9 * sin(rad));
    final p2 = Offset(center.dx + (radius * 0.9 - tickLen) * cos(rad), center.dy + (radius * 0.9 - tickLen) * sin(rad));
    canvas.drawLine(
      p1,
      p2,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant AttitudePainter oldDelegate) {
    return oldDelegate.roll != roll || oldDelegate.pitch != pitch;
  }
}
