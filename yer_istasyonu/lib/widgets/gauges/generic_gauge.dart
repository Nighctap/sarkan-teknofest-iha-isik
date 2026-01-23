import 'dart:math';
import 'package:flutter/material.dart';

class GenericLikelyGauge extends StatelessWidget {
  final String label;
  final double value;
  final double minValue;
  final double maxValue;
  final Color primaryColor;
  final String units;

  const GenericLikelyGauge({
    super.key,
    required this.label,
    required this.value,
    this.minValue = 0,
    this.maxValue = 100,
    this.primaryColor = const Color(0xFF00d4ff),
    required this.units,
  });

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
            painter: GenericGaugePainter(
              value: value,
              minValue: minValue,
              maxValue: maxValue,
              primaryColor: primaryColor,
              label: label,
              units: units,
            ),
          ),
        );
      },
    );
  }
}

class GenericGaugePainter extends CustomPainter {
  final double value;
  final double minValue;
  final double maxValue;
  final Color primaryColor;
  final String label;
  final String units;

  GenericGaugePainter({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.primaryColor,
    required this.label,
    required this.units,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background
    final bgPaint = Paint()..color = const Color(0xFF131920);
    canvas.drawCircle(center, radius, bgPaint);
    
    // Border
    final borderPaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, borderPaint);

    // Ticks
    final tickPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;
    
    // Start angle 135 deg to 405 deg (270 degree sweep)
    const startAngle = 135.0;
    const sweepAngle = 270.0;
    
    for (int i = 0; i <= 10; i++) {
       final fraction = i / 10.0;
       final angleDeg = startAngle + (fraction * sweepAngle);
       final angleRad = angleDeg * pi / 180;
       
       final p1 = Offset(center.dx + radius * 0.85 * cos(angleRad), center.dy + radius * 0.85 * sin(angleRad));
       final p2 = Offset(center.dx + radius * 0.95 * cos(angleRad), center.dy + radius * 0.95 * sin(angleRad));
       
       canvas.drawLine(p1, p2, tickPaint);
       
       // Labels
       final val = minValue + (fraction * (maxValue - minValue));
       final tp = TextPainter(
         text: TextSpan(text: val.toInt().toString(), style: const TextStyle(color: Colors.white, fontSize: 10)),
         textDirection: TextDirection.ltr
       )..layout();
       
       final pText = Offset(center.dx + radius * 0.70 * cos(angleRad) - tp.width/2, center.dy + radius * 0.70 * sin(angleRad) - tp.height/2);
       tp.paint(canvas, pText);
    }
    
    // Labels (Name and Unit)
    final labelTp = TextPainter(
         text: TextSpan(text: label, style: TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.bold)),
         textDirection: TextDirection.ltr
       )..layout();
    labelTp.paint(canvas, Offset(center.dx - labelTp.width/2, center.dy - radius * 0.4));
    
    final unitTp = TextPainter(
         text: TextSpan(text: units, style: const TextStyle(color: Colors.grey, fontSize: 12)),
         textDirection: TextDirection.ltr
       )..layout();
    unitTp.paint(canvas, Offset(center.dx - unitTp.width/2, center.dy + radius * 0.3));

    // Needle
    final normalizedValue = (value - minValue) / (maxValue - minValue);
    final needleAngleDeg = startAngle + (normalizedValue.clamp(0.0, 1.0) * sweepAngle);
    final needleAngleRad = needleAngleDeg * pi / 180;
    
    final needlePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
      
    canvas.drawLine(center, Offset(center.dx + radius * 0.8 * cos(needleAngleRad), center.dy + radius * 0.8 * sin(needleAngleRad)), needlePaint);
    
    // Center cap
    canvas.drawCircle(center, 5, Paint()..color = primaryColor);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
