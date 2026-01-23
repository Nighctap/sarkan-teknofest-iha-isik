// ignore_for_file: unused_local_variable, unused_element

import 'dart:async';
import 'dart:math';
import 'package:get/get.dart';
import '../models/flight_data.dart';
import '../models/flight_record.dart';

/// GetX Controller for flight data with mock data generation
class FlightDataController extends GetxController {
  // Observable state
  final Rx<FlightData> currentData = FlightData.empty().obs;
  final RxList<SpeedDataPoint> speedHistory = <SpeedDataPoint>[].obs;
  final RxList<PositionData> positionHistory = <PositionData>[].obs;
  final RxBool isConnected = false.obs;
  final RxInt selectedTabIndex = 0.obs;
  final RxList<FlightRecord> flightRecords = <FlightRecord>[].obs;

  // Connection URL storage for Settings UI
  String connectionUrl = '';
  // Track current flight start time and collected payload locations
  DateTime currentFlightStart = DateTime.now();
  final List<Map<String, double>> currentPayloadLocations = [];

  /// Add a payload location (latitude/longitude) for the ongoing flight
  void addPayloadLocation(double lat, double lon) {
    currentPayloadLocations.add({'lat': lat, 'lon': lon});
  }

  /// End the current flight and save a FlightRecord
  void endCurrentFlight() {
    final now = DateTime.now();
    final duration = now.difference(currentFlightStart);
    final id = 'FLIGHT-${(flightRecords.length + 1).toString().padLeft(3, '0')}';

    final record = FlightRecord(
      id: id,
      startTime: currentFlightStart,
      duration: duration,
      payloadLocations: currentPayloadLocations.isEmpty ? null : List.from(currentPayloadLocations),
    );

    flightRecords.add(record);

    // Reset for next flight
    currentPayloadLocations.clear();
    currentFlightStart = DateTime.now();
  }

  /// Clear all flight records
  void clearFlightRecords() {
    flightRecords.clear();
  }

  // COM ports (mocked) and selected port
  final RxList<String> comPorts = <String>['COM1', 'COM3', 'COM4'].obs;
  final RxString selectedComPort = ''.obs;

  // Theme brightness (0.0 - dark, 1.0 - light) for dynamic theming
  final RxDouble themeBrightness = 0.0.obs; // default: dark

  /// Connect to a mock data source (stub). Sets `isConnected` to true and stores URL.
  void connectToMockDataSource(String url) {
    connectionUrl = url;
    isConnected.value = true;
  }

  /// Disconnect from data source (stub)
  void disconnectDataSource() {
    connectionUrl = '';
    isConnected.value = false;
  }

  Timer? _mockDataTimer;

  @override
  void onInit() {
    super.onInit();
    // Start mock data generation for demo
    startMockDataGeneration();
    // Populate some mock flight records
    _generateMockRecords();
  }

  @override
  void onClose() {
    _mockDataTimer?.cancel();
    super.onClose();
  }

  void _generateMockRecords() {
    flightRecords.addAll([
      FlightRecord(
        id: 'FLIGHT-001',
        startTime: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
        duration: const Duration(minutes: 12, seconds: 34),
        payloadLocations: [
          {'lat': 39.9335, 'lon': 32.8598},
        ],
      ),
      FlightRecord(
        id: 'FLIGHT-002',
        startTime: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
        duration: const Duration(minutes: 9, seconds: 5),
        payloadLocations: null,
      ),
      FlightRecord(
        id: 'FLIGHT-003',
        startTime: DateTime.now().subtract(const Duration(hours: 5)),
        duration: const Duration(minutes: 15, seconds: 2),
        payloadLocations: [
          {'lat': 39.9340, 'lon': 32.8602},
          {'lat': 39.9343, 'lon': 32.8599},
        ],
      ),
    ]);
  }

  /// Start generating mock flight data
  void startMockDataGeneration() {
    isConnected.value = true;

    // Update every 50ms for smoother animations (20 FPS data rate)
    _mockDataTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _generateMockData();
    });
  }

  /// Stop mock data generation
  void stopMockDataGeneration() {
    _mockDataTimer?.cancel();
    _mockDataTimer = null;
    isConnected.value = false;
  }

  /// Generate mock flight data
  void _generateMockData() {
    if (!isConnected.value) return;

    final now = DateTime.now();
    final lastData = currentData.value;

    // Smooth random walk for natural movement
    final r = Random();

    // Physics-based movement (Speed in m/s roughly)
    double speedMs = lastData.speed / 3.6; // Assuming kn or km/h, scaling for demo
    if (speedMs < 10) speedMs = 30; // Min speed for demo

    // Move in direction of heading
    // 1 deg Lat ~= 111km -> 111,000m
    double distMoved = speedMs * 0.05; // 50ms interval
    double latChange = (distMoved / 111000.0) * cos(lastData.heading * pi / 180);
    double lngChange = (distMoved / (111000.0 * cos(lastData.latitude * pi / 180))) * sin(lastData.heading * pi / 180);

    double altChange = (r.nextDouble() - 0.5) * 0.2; // Vertical ripple

    // Smooth turn (e.g. 3 degrees per second standard rate)
    // Add sinusoidal turn pattern
    double headingChange = sin(now.millisecondsSinceEpoch / 5000) * 0.5; // Slow gentle turns
    double speedChange = (r.nextDouble() - 0.5) * 0.2;

    // Simulate standard flight dynamics
    double newPitch = sin(now.millisecondsSinceEpoch / 1000) * 15; // +/- 15 degrees pitch (faster)
    double newRoll = cos(now.millisecondsSinceEpoch / 1500) * 30; // +/- 30 degrees roll (faster and wider)
    double newRpm = 2000 + (sin(now.millisecondsSinceEpoch / 5000) * 500) + (r.nextDouble() * 50); // 1500-2500 RPM
    double newEgt = 700 + (sin(now.millisecondsSinceEpoch / 10000) * 100); // 600-800 EGT

    // Simulate Turn Coordinator
    // Simulate Turn Coordinator
    // Turn rate correlated with actual heading change
    // headingChange is per 50ms. Per second = * 20.
    double newTurnRate = (headingChange * 20) * 2.0; // Amplify for visibility
    // Slip: usually near 0, but oscillates slightly
    double newSlip = sin(now.millisecondsSinceEpoch / 1500) * 0.2; // +/- 0.2 slip

    final newData = FlightData(
      timestamp: now,
      latitude: lastData.latitude + latChange,
      longitude: lastData.longitude + lngChange,
      altitude: (lastData.altitude + altChange).clamp(0, 5000), // Clamp altitude
      heading: (lastData.heading + headingChange) % 360,
      speed: (lastData.speed + speedChange).clamp(0, 150),
      verticalSpeed: altChange * 20, // Approx vertical speed based on altitude change
      batteryPercent: max(0, lastData.batteryPercent - 0.001), // Slow drain
      signalStrength: 85 + r.nextDouble() * 15,
      gpsStatus: 'FIX',
      satellites: 12 + r.nextInt(4),
      pitch: newPitch,
      roll: newRoll,
      rpm: newRpm,
      egt: newEgt,
      turnRate: newTurnRate,
      slip: newSlip,
    );

    currentData.value = newData;

    // Add to history for charts/maps
    speedHistory.add(SpeedDataPoint(time: now, speed: newData.speed));
    positionHistory.add(PositionData(latitude: newData.latitude, longitude: newData.longitude));

    // Cleanup old data (Keep last 60 seconds)
    final cutoff = now.subtract(const Duration(seconds: 60));

    while (speedHistory.isNotEmpty && speedHistory.first.time.isBefore(cutoff)) {
      speedHistory.removeAt(0);
    }

    // Update position history (keep last 500 positions)
    if (positionHistory.length > 500) {
      positionHistory.removeAt(0);
    }
  }

  /// Update flight data from external source (WebSocket, etc.)
  void updateFlightData(FlightData data) {
    currentData.value = data;
    speedHistory.add(SpeedDataPoint(time: data.timestamp, speed: data.speed));
    positionHistory.add(PositionData(latitude: data.latitude, longitude: data.longitude));
  }

  /// Connect to real data source
  void connectToDataSource(String url) {
    // TODO: Implement WebSocket connection
  }
}
