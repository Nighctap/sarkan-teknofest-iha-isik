import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/flight_data_controller.dart';

/// Flight map widget using flutter_map with OpenStreetMap
class FlightMapWidget extends StatefulWidget {
  const FlightMapWidget({super.key});

  @override
  State<FlightMapWidget> createState() => _FlightMapWidgetState();
}

class _FlightMapWidgetState extends State<FlightMapWidget> {
  late final MapController _mapController;
  final FlightDataController controller = Get.find();
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  // Effect to center map when position changes
  void _setupMapCentering() {
    ever(controller.currentData, (data) {
      if (_mapReady) {
        try {
          _mapController.move(LatLng(data.latitude, data.longitude), _mapController.camera.zoom);
        } catch (_) {}
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Obx(() {
          final positionHistory = controller.positionHistory;
          final currentData = controller.currentData.value;
          final pathPoints = positionHistory.map((p) => LatLng(p.latitude, p.longitude)).toList();

          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: RepaintBoundary(
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(currentData.latitude, currentData.longitude),
                        initialZoom: 15,
                        backgroundColor: const Color(0xFF131920),
                        onMapReady: () {
                          setState(() => _mapReady = true);
                          _setupMapCentering();
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
                          userAgentPackageName: 'com.teknofest.yer_istasyonu',
                          tileProvider: CancellableNetworkTileProvider(),
                        ),
                        if (pathPoints.length > 1)
                          PolylineLayer(
                            polylines: [
                              Polyline(points: pathPoints, strokeWidth: 3, color: const Color(0xFF00d4ff)),
                              if (pathPoints.length > 10)
                                Polyline(
                                  points: pathPoints.sublist(pathPoints.length - 10),
                                  strokeWidth: 6,
                                  color: const Color(0xFF7c3aed).withOpacity(0.5),
                                ),
                            ],
                          ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(currentData.latitude, currentData.longitude),
                              width: 50,
                              height: 50,
                              child: Transform.rotate(
                                angle: currentData.heading * 3.14159 / 180,
                                child: Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(color: const Color(0xFF00d4ff).withOpacity(0.5), blurRadius: 15, spreadRadius: 3),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.airplanemode_active,
                                    color: Color(0xFF00d4ff),
                                    size: 36,
                                    shadows: [Shadow(color: Color(0xFF00d4ff), blurRadius: 10)],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF00d4ff).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildInfoRow('LAT', currentData.latitude.toStringAsFixed(6)),
                        _buildInfoRow('LNG', currentData.longitude.toStringAsFixed(6)),
                        _buildInfoRow('ALT', '${currentData.altitude.toStringAsFixed(0)} m'),
                        _buildInfoRow('GPS', '${currentData.gpsStatus} (${currentData.satellites} sat)'),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      _buildTelemetryBadge(
                        'Batarya',
                        '${currentData.batteryPercent.toStringAsFixed(0)}%',
                        currentData.batteryPercent < 20 ? const Color(0xFFef4444) : const Color(0xFF22c55e),
                      ),
                      const SizedBox(width: 8),
                      _buildTelemetryBadge(
                        'Sinyal',
                        '${currentData.signalStrength.toStringAsFixed(0)}%',
                        currentData.signalStrength < 50 ? const Color(0xFFf59e0b) : const Color(0xFF00d4ff),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(color: Color(0xFF00d4ff), fontSize: 11, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(color: Color(0xFF8b949e), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildTelemetryBadge(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF00d4ff).withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF6e7681), fontSize: 9)),
          Text(value, style: TextStyle(color: valueColor, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
