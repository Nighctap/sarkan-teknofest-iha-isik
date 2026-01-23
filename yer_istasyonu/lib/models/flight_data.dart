/// Flight data model for UAV telemetry
class FlightData {
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double altitude;
  final double heading;
  final double speed;
  final double verticalSpeed;
  final double batteryPercent;
  final double signalStrength;
  final String gpsStatus;
  final int satellites;
  // Cockpit Fields
  final double pitch;
  final double roll; 
  final double rpm;
  final double egt;
  final double turnRate; // Degrees per second
  final double slip; // -1.0 to 1.0 (Skid/Slip)

  FlightData({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.heading,
    required this.speed,
    required this.verticalSpeed,
    required this.batteryPercent,
    required this.signalStrength,
    required this.gpsStatus,
    required this.satellites,
    this.pitch = 0.0,
    this.roll = 0.0,
    this.rpm = 0.0,
    this.egt = 0.0,
    this.turnRate = 0.0,
    this.slip = 0.0,
  });

  factory FlightData.empty() {
    return FlightData(
      timestamp: DateTime.now(),
      latitude: 39.9334,
      longitude: 32.8597,
      altitude: 0,
      heading: 0,
      speed: 0,
      verticalSpeed: 0,
      batteryPercent: 100,
      signalStrength: 100,
      gpsStatus: 'NO FIX',
      satellites: 0,
      pitch: 0,
      roll: 0,
      rpm: 0,
      egt: 0,
      turnRate: 0,
      slip: 0,
    );
  }

  factory FlightData.fromJson(Map<String, dynamic> json) {
    return FlightData(
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      latitude: (json['latitude'] ?? 39.9334).toDouble(),
      longitude: (json['longitude'] ?? 32.8597).toDouble(),
      altitude: (json['altitude'] ?? 0).toDouble(),
      heading: (json['heading'] ?? 0).toDouble(),
      speed: (json['speed'] ?? 0).toDouble(),
      verticalSpeed: (json['verticalSpeed'] ?? 0).toDouble(),
      batteryPercent: (json['batteryPercent'] ?? 100).toDouble(),
      signalStrength: (json['signalStrength'] ?? 100).toDouble(),
      gpsStatus: json['gpsStatus'] ?? 'NO FIX',
      satellites: json['satellites'] ?? 0,
      pitch: (json['pitch'] ?? 0).toDouble(),
      roll: (json['roll'] ?? 0).toDouble(),
      rpm: (json['rpm'] ?? 0).toDouble(),
      egt: (json['egt'] ?? 0).toDouble(),
      turnRate: (json['turnRate'] ?? 0).toDouble(),
      slip: (json['slip'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'heading': heading,
      'speed': speed,
      'verticalSpeed': verticalSpeed,
      'batteryPercent': batteryPercent,
      'signalStrength': signalStrength,
      'gpsStatus': gpsStatus,
      'satellites': satellites,
      'pitch': pitch,
      'roll': roll,
      'rpm': rpm,
      'egt': egt,
      'turnRate': turnRate,
      'slip': slip,
    };
  }
}

/// Speed data point for chart
class SpeedDataPoint {
  final DateTime time;
  final double speed;

  SpeedDataPoint({required this.time, required this.speed});
}

/// Position data for flight path
class PositionData {
  final double latitude;
  final double longitude;

  PositionData({required this.latitude, required this.longitude});
}
