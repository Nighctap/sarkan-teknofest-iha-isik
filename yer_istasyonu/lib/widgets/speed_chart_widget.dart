import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../controllers/flight_data_controller.dart';
import '../models/flight_data.dart';

/// Speed chart widget using Syncfusion Charts
class SpeedChartWidget extends StatelessWidget {
  const SpeedChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FlightDataController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Obx(() {
          final speedHistory = controller.speedHistory;
          final currentSpeed = speedHistory.isNotEmpty ? speedHistory.last.speed : 0.0;
          
          // Calculate chart range (last 60 seconds)
          final now = DateTime.now();
          final maxDate = speedHistory.isNotEmpty ? speedHistory.last.time : now;
          final minDate = maxDate.subtract(const Duration(seconds: 60));

          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Stack(
              children: [
                // Chart
                SfCartesianChart(
                  backgroundColor: Colors.transparent,
                  plotAreaBorderWidth: 0,
                  margin: const EdgeInsets.fromLTRB(8, 32, 8, 8),
                  primaryXAxis: DateTimeAxis(
                    minimum: minDate,
                    maximum: maxDate,
                    axisLine: AxisLine(color: const Color(0xFF00d4ff).withOpacity(0.3)),
                    majorGridLines: MajorGridLines(color: const Color(0xFF00d4ff).withOpacity(0.1)),
                    labelStyle: const TextStyle(color: Color(0xFF8b949e), fontSize: 10),
                    dateFormat: DateFormat.Hms(),
                    intervalType: DateTimeIntervalType.seconds,
                    interval: 15,
                  ),
                  primaryYAxis: NumericAxis(
                    title: AxisTitle(
                      text: 'Hız (km/h)',
                      textStyle: const TextStyle(color: Color(0xFF00d4ff), fontSize: 10),
                    ),
                    minimum: 0,
                    maximum: 150,
                    axisLine: AxisLine(color: const Color(0xFF00d4ff).withOpacity(0.3)),
                    majorGridLines: MajorGridLines(color: const Color(0xFF00d4ff).withOpacity(0.1)),
                    labelStyle: const TextStyle(color: Color(0xFF8b949e), fontSize: 10),
                  ),
                  tooltipBehavior: TooltipBehavior(
                    enable: true,
                    color: Colors.black.withOpacity(0.8),
                    textStyle: const TextStyle(color: Colors.white),
                  ),
                  series: <CartesianSeries<SpeedDataPoint, DateTime>>[
                    AreaSeries<SpeedDataPoint, DateTime>(
                      dataSource: speedHistory.toList(), // Create list once per build
                      xValueMapper: (SpeedDataPoint data, _) => data.time,
                      yValueMapper: (SpeedDataPoint data, _) => data.speed,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [const Color(0xFF00d4ff).withOpacity(0.3), const Color(0xFF00d4ff).withOpacity(0.0)],
                      ),
                      borderWidth: 0,
                    ),
                    SplineSeries<SpeedDataPoint, DateTime>(
                      dataSource: speedHistory.toList(),
                      xValueMapper: (SpeedDataPoint data, _) => data.time,
                      yValueMapper: (SpeedDataPoint data, _) => data.speed,
                      color: const Color(0xFF00d4ff),
                      width: 3,
                      animationDuration: 300,
                    ),
                  ],
                ),

                // Current speed overlay
                Positioned(
                  top: 8,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF00d4ff).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'MEVCUT',
                          style: TextStyle(color: Color(0xFF8b949e), fontSize: 10),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              currentSpeed.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Color(0xFF00d4ff),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(color: Color(0xFF00d4ff), blurRadius: 10)],
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('km/h', style: TextStyle(color: Color(0xFF8b949e), fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}
