import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yer_istasyonu/controllers/flight_data_controller.dart';
import 'package:yer_istasyonu/widgets/camera_feed_widget.dart';
import 'package:yer_istasyonu/widgets/compass_widget.dart';
import 'package:yer_istasyonu/widgets/flight_map_widget.dart';
import 'package:yer_istasyonu/widgets/speed_chart_widget.dart';

import '../widgets/gauges/turn_coordinator.dart';

/// Dashboard content view (stripped of scaffold/header)
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the controller
    final controller = Get.find<FlightDataController>();

    // Add a small control row and then the grid; MainScreen handles the Scaffold/Header
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Top-row controls removed; 'Uçuş Bitir' moved to persistent header
          const SizedBox(height: 8),
          const SizedBox(height: 12),
          Expanded(child: _buildDashboardGrid(controller)),
        ],
      ),
    );
  }

  Widget _buildDashboardGrid(FlightDataController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive layout
        final isWide = constraints.maxWidth > 900;

        if (isWide) {
          // Desktop layout: 2x2 grid
          return Row(
            children: [
              // Left column
              Expanded(
                child: Column(
                  children: [
                    // Camera
                    Expanded(
                      child: _buildPanel(
                        title: 'KAMERA GÖRÜNTÜSÜ',
                        icon: Icons.videocam,
                        child: const CameraFeedWidget(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Instruments (Compass + Turn Coordinator)
                    Expanded(
                      child: _buildPanel(
                        title: 'UÇUŞ GÖSTERGELERİ',
                        icon: Icons.explore,
                        child: Row(
                          children: [
                            Expanded(child: const CompassWidget()),
                            const VerticalDivider(color: Colors.white10),
                            Expanded(
                              child: Obx(
                                () => TurnCoordinatorWidget(
                                  turnRate: controller.currentData.value.turnRate,
                                  slip: controller.currentData.value.slip,
                                  pitch: controller.currentData.value.pitch,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right column (wider for map)
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    // Map
                    Expanded(
                      child: _buildPanel(
                        title: 'HARİTA - UÇUŞ ROTASI',
                        icon: Icons.map,
                        child: const FlightMapWidget(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Speed chart
                    Expanded(
                      child: _buildPanel(title: 'HIZ GRAFİĞİ', icon: Icons.show_chart, child: const SpeedChartWidget()),
                    ),
                  ],
                ),
              ),
            ],
          );
        } else {
          // Mobile/tablet layout: single column
          return SingleChildScrollView(
            child: Column(
              children: [
                // Camera
                SizedBox(
                  height: 250,
                  child: _buildPanel(title: 'KAMERA GÖRÜNTÜSÜ', icon: Icons.videocam, child: const CameraFeedWidget()),
                ),
                const SizedBox(height: 12),
                // Instruments
                SizedBox(
                  height: 250, // Reduced height as they are side-by-side
                  child: _buildPanel(
                    title: 'UÇUŞ GÖSTERGELERİ',
                    icon: Icons.explore,
                    child: Row(
                      children: [
                        Expanded(child: const CompassWidget()),
                        const VerticalDivider(color: Colors.white10),
                        Expanded(
                          child: Obx(
                            () => TurnCoordinatorWidget(
                              turnRate: controller.currentData.value.turnRate,
                              slip: controller.currentData.value.slip,
                              pitch: controller.currentData.value.pitch,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Map
                SizedBox(
                  height: 300,
                  child: _buildPanel(title: 'HARİTA - UÇUŞ ROTASI', icon: Icons.map, child: const FlightMapWidget()),
                ),
                const SizedBox(height: 12),
                // Speed chart
                SizedBox(
                  height: 250,
                  child: _buildPanel(title: 'HIZ GRAFİĞİ', icon: Icons.show_chart, child: const SpeedChartWidget()),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildPanel({required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF151c25), Color(0xFF0d1217)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00d4ff).withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Panel header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: const Color(0xFF00d4ff).withOpacity(0.15))),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF00d4ff), size: 16),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF00d4ff),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          // Panel content
          Expanded(
            child: Padding(padding: const EdgeInsets.all(12), child: child),
          ),
        ],
      ),
    );
  }
}
