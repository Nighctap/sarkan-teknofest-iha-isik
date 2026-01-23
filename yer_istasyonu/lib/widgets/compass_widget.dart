import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/flight_data_controller.dart';

/// Aviation-style compass widget with rotating face
class CompassWidget extends StatefulWidget {
  const CompassWidget({super.key});

  @override
  State<CompassWidget> createState() => _CompassWidgetState();
}

class _CompassWidgetState extends State<CompassWidget> {
  final controller = Get.find<FlightDataController>();
  double _displayHeading = 0.0;

  @override
  void initState() {
    super.initState();
    // Initialize with current heading
    _displayHeading = controller.currentData.value.heading;
    
    // Listen for heading changes to update displayHeading with shortest path logic
    ever(controller.currentData, (data) {
      final newHeading = data.heading;
      
      // Calculate angular difference
      double diff = newHeading - (_displayHeading % 360);
      
      // Normalize difference to [-180, 180] for shortest path
      if (diff > 180) diff -= 360;
      if (diff < -180) diff += 360;
      
      if (mounted) {
        setState(() {
          _displayHeading += diff;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1a2332), Color(0xFF0d1217)],
                  ),
                  border: Border.all(color: const Color(0xFF00d4ff).withOpacity(0.3), width: 3),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF00d4ff).withOpacity(0.2), blurRadius: 20, spreadRadius: 2),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF131920),
                      border: Border.all(color: const Color(0xFF00d4ff).withOpacity(0.2), width: 2),
                    ),
                    child: AnimatedRotation(
                        turns: -_displayHeading / 360,
                        duration: const Duration(milliseconds: 100), // Faster response for 20 FPS
                        curve: Curves.linear, // Linear for continuous movement
                        child: CustomPaint(painter: CompassPainter(), child: const SizedBox.expand()),
                    ),
                  ),
                ),
              ),
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
            child: Obx(() {
               final heading = controller.currentData.value.heading;
               return Text(
                '${heading.toStringAsFixed(0)}°',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00d4ff),
                  shadows: [Shadow(color: Color(0xFF00d4ff), blurRadius: 10)],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw tick marks
    for (int i = 0; i < 360; i += 10) {
      final isMajor = i % 30 == 0;
      final startRadius = isMajor ? radius * 0.78 : radius * 0.85;
      final endRadius = radius * 0.92;

      final angle = (i - 90) * pi / 180;
      final start = Offset(center.dx + startRadius * cos(angle), center.dy + startRadius * sin(angle));
      final end = Offset(center.dx + endRadius * cos(angle), center.dy + endRadius * sin(angle));

      final paint = Paint()
        ..color = isMajor ? const Color(0xFF00d4ff) : const Color(0xFF6e7681)
        ..strokeWidth = isMajor ? 2 : 1;

      canvas.drawLine(start, end, paint);
    }

    // Draw direction labels
    final directions = [
      {'label': 'N', 'angle': 0, 'color': const Color(0xFFef4444)},
      {'label': 'E', 'angle': 90, 'color': const Color(0xFF00d4ff)},
      {'label': 'S', 'angle': 180, 'color': const Color(0xFF00d4ff)},
      {'label': 'W', 'angle': 270, 'color': const Color(0xFF00d4ff)},
    ];

    for (final dir in directions) {
      final angle = ((dir['angle'] as int) - 90) * pi / 180;
      final textRadius = radius * 0.65;
      final x = center.dx + textRadius * cos(angle);
      final y = center.dy + textRadius * sin(angle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: dir['label'] as String,
          style: TextStyle(
            color: dir['color'] as Color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }

    // Draw aircraft symbol
    final aircraftPath = Path();
    final scale = radius * 0.35;

    // Fuselage
    aircraftPath.moveTo(center.dx, center.dy - scale);
    aircraftPath.lineTo(center.dx + scale * 0.15, center.dy - scale * 0.6);
    aircraftPath.lineTo(center.dx + scale * 0.15, center.dy + scale * 0.3);
    aircraftPath.lineTo(center.dx + scale * 0.5, center.dy + scale * 0.7);
    aircraftPath.lineTo(center.dx + scale * 0.5, center.dy + scale * 0.8);
    aircraftPath.lineTo(center.dx + scale * 0.15, center.dy + scale * 0.65);
    aircraftPath.lineTo(center.dx + scale * 0.15, center.dy + scale * 0.8);
    aircraftPath.lineTo(center.dx + scale * 0.3, center.dy + scale);
    aircraftPath.lineTo(center.dx, center.dy + scale * 0.85);
    aircraftPath.lineTo(center.dx - scale * 0.3, center.dy + scale);
    aircraftPath.lineTo(center.dx - scale * 0.15, center.dy + scale * 0.8);
    aircraftPath.lineTo(center.dx - scale * 0.15, center.dy + scale * 0.65);
    aircraftPath.lineTo(center.dx - scale * 0.5, center.dy + scale * 0.8);
    aircraftPath.lineTo(center.dx - scale * 0.5, center.dy + scale * 0.7);
    aircraftPath.lineTo(center.dx - scale * 0.15, center.dy + scale * 0.3);
    aircraftPath.lineTo(center.dx - scale * 0.15, center.dy - scale * 0.6);
    aircraftPath.close();

    final aircraftPaint = Paint()
      ..color = const Color(0xFF00d4ff)
      ..style = PaintingStyle.fill;

    canvas.drawPath(aircraftPath, aircraftPaint);

    // Draw center dot
    canvas.drawCircle(
      center,
      6,
      Paint()
        ..color = const Color(0xFF00d4ff)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
