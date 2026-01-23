class FlightRecord {
  final String id;
  final DateTime startTime;
  final Duration duration;
  final List<Map<String, double>>? payloadLocations; // [{"lat":..., "lon":...}, ...]

  FlightRecord({
    required this.id,
    required this.startTime,
    required this.duration,
    this.payloadLocations,
  });
}
