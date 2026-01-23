// ignore_for_file: unused_local_variable, avoid_types_as_parameter_names, unused_element

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/flight_data_controller.dart';

class MissionScreen extends StatefulWidget {
  const MissionScreen({super.key});

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> {
  double task1Progress = 0.0;
  double task2Progress = 0.0;
  // Atış noktaları ve tahminler
  final List<Offset> shots = [];
  final List<Offset> blueShots = [];
  // Initialize with some default "prediction" points as place holders
  final List<Offset> predictedCorners = [
    const Offset(100, 100),
    const Offset(300, 100),
    const Offset(300, 300),
    const Offset(100, 300),
  ];
  final List<Offset> kCorners = [
    Offset(50, 50),
    Offset(350, 50),
    Offset(350, 350),
    Offset(50, 350),
  ]; // k1-k4 başlangıçta dolu

  String? greenShotLocation;
  String? blueShotLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0e14),
      appBar: AppBar(
        title: const Text(
          'Görevler',
          style: TextStyle(color: Colors.white, fontFamily: 'monospace'),
        ),
        backgroundColor: const Color(0xFF151c25),
        iconTheme: const IconThemeData(color: Color(0xFF00d4ff)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double mapMaxHeight = (constraints.maxHeight - 200) / 1.2;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTaskProgress('1. Görev', task1Progress, segments: 2),
                const SizedBox(height: 24),
                _buildTaskProgress('2. Görev', (shots.length + blueShots.length) / 2.0, segments: 2, showButton: false),
                const SizedBox(height: 32),
                // Alt içeriği Expanded ile sığdır
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('2. Görev: Atış Noktaları (m1-m4)', style: _sectionTitleStyle()),
                            const SizedBox(height: 12),
                            Expanded(
                              child: _buildMapContainer(
                                title: 'ATIŞ ALANI (YEŞİL)',
                                color: Colors.greenAccent,
                                points: shots,
                                cornerPoints: const [], // M points hidden
                                isShootingMap: true,
                                onTap: (pos) => _addShot(shots, pos, 1),
                              ),
                            ),
                            _buildResultCard('FAYDALI YÜK KONUMU', greenShotLocation, Colors.greenAccent),
                            const SizedBox(height: 16),
                            Text('M Noktaları:', style: _sectionTitleStyle()),
                            _buildInputList('m', predictedCorners),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('2. Görev: Atış Noktaları (k1-k4)', style: _sectionTitleStyle()),
                            const SizedBox(height: 12),
                            Expanded(
                              child: _buildMapContainer(
                                title: 'ATIŞ ALANI (MAVİ)',
                                color: Colors.blueAccent,
                                points: blueShots,
                                cornerPoints: const [], // K points hidden
                                isShootingMap: true,
                                onTap: (pos) => _addShot(blueShots, pos, 2),
                              ),
                            ),
                            _buildResultCard('FAYDALI YÜK KONUMU', blueShotLocation, Colors.blueAccent),
                            const SizedBox(height: 16),
                            Text('K Noktaları:', style: _sectionTitleStyle()),
                            _buildInputList('k', kCorners),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTaskProgress(String title, double progress, {int segments = 1, bool showButton = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: _sectionTitleStyle()),
            // Temp button for Task 1 Testing
            if (segments > 1 && showButton)
              IconButton(
                icon: const Icon(Icons.add_circle, color: Color(0xFF00d4ff)),
                onPressed: () {
                  setState(() {
                    task1Progress = (task1Progress + 0.5).clamp(0.0, 1.0);
                  });
                },
                tooltip: 'Tur Tamamla',
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (segments > 1)
          Row(
            children: List.generate(segments, (index) {
              // Check if this segment is "filled"
              // e.g. progress 0.5 means 1st segment filled (1 of 2)
              // progress 1.0 means both filled (2 of 2)
              // Threshold for index 0 is >= 0.5? No.
              // If we have 2 segments:
              // Segment 0: 0.0 -> 0.5 range. Logic: (index + 1) / segments <= progress ?
              // If progress is 0.5, segment 0 is done. (1/2 <= 0.5) True.

              double segmentThreshold = (index + 1) / segments;
              bool isFilled = progress >= segmentThreshold;

              return Expanded(
                child: Container(
                  height: 16,
                  margin: EdgeInsets.only(right: index < segments - 1 ? 4.0 : 0.0), // Gap between segments
                  decoration: BoxDecoration(
                    color: isFilled ? const Color(0xFF00d4ff) : Colors.white12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          )
        else
          LinearProgressIndicator(
            value: progress,
            minHeight: 16,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00d4ff)),
          ),
      ],
    );
  }

  Widget _buildMapContainer({
    required String title,
    required Color color,
    required List<Offset> points,
    required List<Offset> cornerPoints,
    required bool isShootingMap,
    required Function(Offset) onTap, // Restore Callback
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(8),
            color: Colors.black.withOpacity(0.3),
          ),
          child: Stack(
            children: [
              // Title Overlay (Top Left)
              Positioned(
                top: 8,
                left: 8,
                child: Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
              ),
              // Custom Paint (Grid + Points)
              Positioned.fill(
                child: CustomPaint(
                  painter: _MapPainter(
                    color: color,
                    shotPoints: points,
                    cornerPoints: cornerPoints,
                    drawRect: true,
                    points: points,
                  ),
                ),
              ),
              // Interaction (Her iki harita için de aktif)
              Positioned.fill(
                child: GestureDetector(
                  onTapDown: (details) {
                    if (isShootingMap) {
                      onTap(details.localPosition);
                    }
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputList(String prefix, List<Offset> points) {
    // Render inputs in 2x2 grid: two rows, two columns
    Widget field(int i) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: TextFormField(
          initialValue: '${points[i].dx.toStringAsFixed(0)}, ${points[i].dy.toStringAsFixed(0)}',
          decoration: InputDecoration(
            labelText: '$prefix${i + 1} (x, y)',
            labelStyle: const TextStyle(color: Color(0xFF00d4ff)),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00d4ff))),
          ),
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          onChanged: (val) {
            final parts = val.split(',');
            if (parts.length == 2) {
              final x = double.tryParse(parts[0].trim()) ?? 0;
              final y = double.tryParse(parts[1].trim()) ?? 0;
              setState(() {
                points[i] = Offset(x, y);
              });
            }
          },
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: field(0)),
            const SizedBox(width: 12),
            Expanded(child: field(1)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: field(2)),
            const SizedBox(width: 12),
            Expanded(child: field(3)),
          ],
        ),
      ],
    );
  }

  TextStyle _sectionTitleStyle() =>
      const TextStyle(color: Color(0xFF00d4ff), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace');

  TextStyle _valueStyle() => const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'monospace');

  Widget _buildResultCard(String title, String? location, Color color) {
    if (location == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.gps_fixed, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addShot(List<Offset> shotList, Offset localPos, int taskIndex) {
    if (shotList.isEmpty) {
      // Limit to 1
      final controller = Get.find<FlightDataController>();
      final data = controller.currentData.value;

      setState(() {
        shotList.add(localPos);
        if (taskIndex == 1) {
          // Green
          greenShotLocation = '${data.latitude.toStringAsFixed(6)}, ${data.longitude.toStringAsFixed(6)}';
          controller.addPayloadLocation(data.latitude, data.longitude);
        } else {
          // Blue
          blueShotLocation = '${data.latitude.toStringAsFixed(6)}, ${data.longitude.toStringAsFixed(6)}';
          controller.addPayloadLocation(data.latitude, data.longitude);
        }
      });
    }
  }
}

class _MapPainter extends CustomPainter {
  final Color color;
  final List<Offset> shotPoints; // Red dots
  final List<Offset> cornerPoints; // Map themed dots (M/K)
  final bool drawRect;

  _MapPainter({
    required this.color,
    required this.shotPoints,
    required this.cornerPoints,
    this.drawRect = true,
    required List<Offset> points,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw Boundary Rect
    // Draw Boundary Rect
    // if (drawRect) {
    //   final rect = Rect.fromLTWH(20, 20, size.width - 40, size.height - 40);
    //   canvas.drawRect(rect, paint);
    // }

    // Draw Corner Points (The M or K inputs) - Small themed dots
    final cornerPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    for (final p in cornerPoints) {
      if (p != Offset.zero) {
        canvas.drawCircle(p, 4, cornerPaint);
      }
    }

    // Draw Shot Points (The "Hits") - Large Red dots
    final shotPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    for (final p in shotPoints) {
      canvas.drawCircle(p, 8, shotPaint);
      // White ring
      canvas.drawCircle(
        p,
        10,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) {
    return oldDelegate.shotPoints != shotPoints ||
        oldDelegate.cornerPoints != cornerPoints ||
        oldDelegate.color != color;
  }
}
