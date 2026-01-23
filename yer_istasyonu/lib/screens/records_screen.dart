import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/flight_data_controller.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FlightDataController>();

    return Scaffold(
      backgroundColor: const Color(0xFF0a0e14),
      appBar: AppBar(
        title: const Text(
          'Kayıtlar',
          style: TextStyle(color: Colors.white, fontFamily: 'monospace'),
        ),
        backgroundColor: const Color(0xFF151c25),
        iconTheme: const IconThemeData(color: Color(0xFF00d4ff)),
        actions: [
          TextButton.icon(
            onPressed: () {
              // Confirm before clearing
              Get.dialog(
                AlertDialog(
                  backgroundColor: const Color(0xFF151c25),
                  title: const Text('Kayıtları Temizle', style: TextStyle(color: Colors.white)),
                  content: const Text(
                    'Tüm uçuş kayıtlarını silmek istediğinize emin misiniz?',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Vazgeç', style: TextStyle(color: Colors.white70)),
                    ),
                    TextButton(
                      onPressed: () {
                        controller.clearFlightRecords();
                        Get.back();
                        Get.snackbar('Kayıtlar', 'Tüm kayıtlar temizlendi', snackPosition: SnackPosition.BOTTOM);
                      },
                      child: const Text('Temizle', style: TextStyle(color: Color(0xFFef4444))),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.delete_sweep, color: Color(0xFFef4444), size: 20),
            label: const Text('Temizle', style: TextStyle(color: Color(0xFFef4444))),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() {
          final records = controller.flightRecords;
          if (records.isEmpty) {
            return const Center(
              child: Text('Kayıt bulunamadı', style: TextStyle(color: Colors.white)),
            );
          }

          return ListView.separated(
            itemCount: records.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final r = records[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10151A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00d4ff).withOpacity(0.12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          r.id,
                          style: const TextStyle(color: Color(0xFF00d4ff), fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text('${r.startTime.toLocal()}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Süre: ',
                          style: const TextStyle(color: Color(0xFF00d4ff), fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${r.duration.inMinutes}m ${r.duration.inSeconds % 60}s',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (r.payloadLocations != null && r.payloadLocations!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'Faydalı Yük Konumları:',
                            style: const TextStyle(color: Color(0xFF00d4ff), fontWeight: FontWeight.bold),
                          ),
                          ...r.payloadLocations!.map(
                            (p) => Text(
                              '• ${p['lat']?.toStringAsFixed(6)}, ${p['lon']?.toStringAsFixed(6)}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
