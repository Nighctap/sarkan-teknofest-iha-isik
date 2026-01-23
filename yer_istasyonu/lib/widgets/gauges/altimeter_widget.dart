import 'package:flutter/material.dart';
import 'generic_gauge.dart';

class AltimeterWidget extends StatelessWidget {
  final double altitude; // in meters or feet

  const AltimeterWidget({super.key, required this.altitude});

  @override
  Widget build(BuildContext context) {
    // Basic single needle altimeter for now
    // In real aviation, it has 3 hands. Here simplicity is preferred first.
    // 0-1000m loop or similar? 
    // Let's make it 0-5000 absolute for now with the generic gauge
    // Or better: show "ALTITUDE" text clearly
    
    return GenericLikelyGauge(
      label: 'ALTITUDE',
      value: altitude,
      minValue: 0,
      maxValue: 500, // Dynamic max?
      units: 'm',
      primaryColor: const Color(0xFFeab308),
    );
  }
}
