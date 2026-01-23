import 'package:flutter/material.dart';
import 'generic_gauge.dart';

class AirspeedIndicator extends StatelessWidget {
  final double speed; // in knots or m/s

  const AirspeedIndicator({super.key, required this.speed});

  @override
  Widget build(BuildContext context) {
    return GenericLikelyGauge(
      label: 'AIRSPEED',
      value: speed,
      minValue: 0,
      maxValue: 100, // Max speed
      units: 'm/s',
      primaryColor: const Color(0xFF22c55e),
    );
  }
}
