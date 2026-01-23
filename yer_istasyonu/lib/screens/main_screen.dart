import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/flight_data_controller.dart';
import 'dashboard_screen.dart'; // Will be aliased/renamed to view later
import 'cockpit_screen.dart'; // Will be aliased/renamed to view later
import 'mission_screen.dart';
import 'records_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FlightDataController>();

    return Scaffold(
      backgroundColor: const Color(0xFF0a0e14),
      body: Column(
        children: [
          // 1. Persistent Header
          _buildHeader(controller),

          // 2. Main Content Area (Sidebar + Body)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch, // Fixes Sidebar Expanded Overflow
              children: [
                // Sidebar (NavigationRail)
                // Custom Sidebar to match "Grid" look
                Container(
                  width: 90, // Slightly wider for labeled grid items
                  color: const Color(0xFF0d1217),
                  child: Column(
                    children: [
                      // Top Icon (Plane Taking Off)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Icon(Icons.flight_takeoff, color: const Color(0xFF00d4ff), size: 40),
                      ),

                      // Menu Items (Spread out)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildSidebarItem(controller, 0, Icons.grid_view, 'PANEL'),
                            _buildSidebarItem(controller, 1, Icons.speed, 'KOKPİT'),
                            _buildSidebarItem(controller, 2, Icons.map_outlined, 'GÖREV', activeIcon: Icons.map),
                            _buildSidebarItem(controller, 3, Icons.history, 'KAYIT'),
                            _buildSidebarItem(
                              controller,
                              4,
                              Icons.settings_outlined,
                              'AYAR',
                              activeIcon: Icons.settings,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // Vertical Divider
                const VerticalDivider(thickness: 1, width: 1, color: Color(0xFF1f2937)),

                // Body Content
                Expanded(
                  child: Obx(() {
                    switch (controller.selectedTabIndex.value) {
                      case 0:
                        return const DashboardView();
                      case 1:
                        return const CockpitView();
                      case 2:
                        return const MissionScreen();
                      case 3:
                        return const RecordsScreen();
                      case 4:
                        return const SettingsScreen();
                      default:
                        return const DashboardView();
                    }
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(FlightDataController controller) {
    return Obx(() {
      final data = controller.currentData.value;
      final isConnected = controller.isConnected.value;

      return Container(
        height: 70, // Fixed height for header
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF0d1217),
          border: Border(bottom: BorderSide(color: const Color(0xFF00d4ff).withOpacity(0.15))),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Title
            ShaderMask(
              shaderCallback: (bounds) =>
                  const LinearGradient(colors: [Color(0xFF00d4ff), Color(0xFF7c3aed)]).createShader(bounds),
              child: const Text(
                'SARKAN İHA YER İSTASYONU',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                  fontFamily: 'monospace',
                ),
              ),
            ),

            const Spacer(),

            // Flight End button and status indicators
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    controller.endCurrentFlight();
                    Get.snackbar('Uçuş', 'Uçuş kaydedildi', snackPosition: SnackPosition.BOTTOM);
                  },
                  icon: const Icon(Icons.flag, size: 18, color: Colors.black),
                  iconAlignment: IconAlignment.start,
                  label: const Text(
                    'Uçuşu Bitir',
                    style: TextStyle(fontFamily: 'monospace', color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00d4ff),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    minimumSize: const Size(140, 40),
                  ),
                ),
                const SizedBox(width: 20),
                _buildStatusIndicator(icon: Icons.wifi, label: isConnected ? 'BAĞLI' : 'KOPUK', isActive: isConnected),
                const SizedBox(width: 16),
                _buildStatusIndicator(
                  icon: Icons.gps_fixed,
                  label: 'GPS: ${data.gpsStatus}',
                  isActive: data.gpsStatus == 'FIX',
                ),
                const SizedBox(width: 16),
                _buildStatusIndicator(
                  icon: Icons.battery_full,
                  label: 'BAT: ${data.batteryPercent.toStringAsFixed(0)}%',
                  isActive: data.batteryPercent > 20,
                  activeColor: data.batteryPercent > 20 ? const Color(0xFF22c55e) : const Color(0xFFef4444),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatusIndicator({
    required IconData icon,
    required String label,
    required bool isActive,
    Color activeColor = const Color(0xFF22c55e),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF131920),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? activeColor.withOpacity(0.3) : const Color(0xFFef4444).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isActive ? activeColor : const Color(0xFFef4444)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : const Color(0xFF8b949e),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    FlightDataController controller,
    int index,
    IconData icon,
    String label, {
    IconData? activeIcon,
  }) {
    return Obx(() {
      final isSelected = controller.selectedTabIndex.value == index;
      return InkWell(
        onTap: () => controller.selectedTabIndex.value = index,
        child: Container(
          width: 70, // Fixed width for touch target
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: isSelected
              ? BoxDecoration(color: const Color(0xFF00d4ff).withOpacity(0.15), borderRadius: BorderRadius.circular(16))
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? (activeIcon ?? icon) : icon,
                color: isSelected ? const Color(0xFF00d4ff) : Colors.white,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF00d4ff) : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
