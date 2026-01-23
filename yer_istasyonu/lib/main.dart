import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'controllers/flight_data_controller.dart';
import 'screens/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  // Ensure controller is available before the app builds
  Get.put(FlightDataController(), permanent: true);
  runApp(const YerIstasyonuApp());
}

class YerIstasyonuApp extends StatelessWidget {
  const YerIstasyonuApp({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FlightDataController>();
    return Obx(() {
      // Compute scaffold background color based on themeBrightness (dark -> lighter)
      final double t = controller.themeBrightness.value.clamp(0.0, 1.0);
      final Color base = const Color(0xFF0a0e14);
      final Color bg = Color.lerp(base, Colors.grey.shade800, t * 0.6)!;

      return GetMaterialApp(
        title: 'SARKAN İHA - Yer İstasyonu',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: t > 0.6 ? Brightness.light : Brightness.dark,
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF00d4ff),
            secondary: const Color(0xFF7c3aed),
            surface: bg,
            error: const Color(0xFFef4444),
          ),
          scaffoldBackgroundColor: bg,
        ),
        // Controller is already registered above before runApp(),
        // so no initialBinding registration is necessary here.
        home: const MainScreen(),
      );
    });
  }
}
