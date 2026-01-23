import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/flight_data_controller.dart';
import '../widgets/gauges/attitude_indicator.dart';
import '../widgets/gauges/airspeed_indicator.dart';
import '../widgets/gauges/altimeter_widget.dart';
import '../widgets/gauges/generic_gauge.dart';

class CockpitView extends StatelessWidget {
  const CockpitView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FlightDataController>();

    // Using Column and Rows with Expanded to force fit on screen without scrolling
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Row 1: Attitude, Airspeed, Altimeter
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildInstrumentCard(
                    'ATTITUDE', 
                    Obx(() => AttitudeIndicator(
                      roll: controller.currentData.value.roll,
                      pitch: controller.currentData.value.pitch,
                    ))
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInstrumentCard(
                    'AIRSPEED', 
                    Obx(() => AirspeedIndicator(
                      speed: controller.currentData.value.speed,
                    ))
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInstrumentCard(
                    'ALTITUDE', 
                    Obx(() => AltimeterWidget(
                      altitude: controller.currentData.value.altitude,
                    ))
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Row 2: VSI, RPM, EGT
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildInstrumentCard(
                    'VERTICAL SPEED',
                     Obx(() => GenericLikelyGauge(
                      label: 'VSI',
                      value: controller.currentData.value.verticalSpeed,
                      minValue: -10,
                      maxValue: 10,
                      units: 'm/s',
                      primaryColor: Colors.white,
                    ))
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInstrumentCard(
                    'MOTOR RPM',
                     Obx(() => GenericLikelyGauge(
                      label: 'RPM',
                      value: controller.currentData.value.rpm,
                      minValue: 0,
                      maxValue: 3000,
                      units: 'RPM',
                      primaryColor: Colors.greenAccent,
                    ))
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInstrumentCard(
                    'EGT',
                     Obx(() => GenericLikelyGauge(
                      label: 'EGT',
                      value: controller.currentData.value.egt,
                      minValue: 0,
                      maxValue: 1000,
                      units: '°C',
                      primaryColor: Colors.orangeAccent,
                    ))
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstrumentCard(String title, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131920),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00d4ff).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: child,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: const Color(0xFF00d4ff).withOpacity(0.7),
              fontSize: 12, // Fixed size font
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
