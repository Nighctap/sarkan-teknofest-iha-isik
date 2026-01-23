import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/flight_data_controller.dart';
import '../services/media_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final controller = Get.find<FlightDataController>();
  final media = MediaService();
  final TextEditingController _connCtrl = TextEditingController();
  final TextEditingController _musicUrlCtrl = TextEditingController();
  double _volume = 0.5;
  final List<Map<String, String>> _musicPresets = [
    {'label': 'Lo-Fi Beat', 'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'},
    {'label': 'Ambient Piano', 'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3'},
    {'label': 'Cinematic', 'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3'},
  ];
  String? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _connCtrl.text = controller.connectionUrl;
    _volume = media.volume;
  }

  @override
  void dispose() {
    _connCtrl.dispose();
    _musicUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0e14),
      appBar: AppBar(
        title: const Text(
          'Ayarlar',
          style: TextStyle(color: Colors.white, fontFamily: 'monospace'),
        ),
        backgroundColor: const Color(0xFF151c25),
        iconTheme: const IconThemeData(color: Color(0xFF00d4ff)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Bağlantı Ayarları', style: _sectionTitle()),
            const SizedBox(height: 8),
            // Allow selecting a COM port or entering a data source URL
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('COM Port:', style: TextStyle(color: Colors.white)),
                    const SizedBox(width: 12),
                    Obx(() {
                      return DropdownButton<String>(
                        value: controller.selectedComPort.value.isEmpty ? null : controller.selectedComPort.value,
                        dropdownColor: const Color(0xFF0d1217),
                        hint: const Text('Seçiniz', style: TextStyle(color: Colors.white)),
                        items: controller.comPorts.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: (v) {
                          controller.selectedComPort.value = v ?? '';
                          setState(() {});
                        },
                      );
                    }),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _connCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Veri Kaynağı URL (isteğe bağlı)',
                          labelStyle: TextStyle(color: Color(0xFF00d4ff)),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (controller.isConnected.value) {
                          controller.disconnectDataSource();
                          setState(() {});
                        } else {
                          // Prefer COM port if selected, otherwise use URL
                          if (controller.selectedComPort.value.isNotEmpty) {
                            controller.connectToMockDataSource('COM:${controller.selectedComPort.value}');
                          } else {
                            controller.connectToMockDataSource(_connCtrl.text.trim());
                          }
                          setState(() {});
                        }
                      },
                      child: Obx(() => Text(controller.isConnected.value ? 'Bağlantıyı Kes' : 'Bağlan')),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Görsellik', style: _sectionTitle()),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Tema Parlaklığı', style: TextStyle(color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(value: 0.5, min: 0, max: 1, onChanged: (v) {}, activeColor: const Color(0xFF00d4ff)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Arka Plan Müzik', style: _sectionTitle()),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Müzik Seçimi',
                          labelStyle: TextStyle(color: Color(0xFF00d4ff)),
                        ),
                        dropdownColor: const Color(0xFF0d1217),
                        value: _selectedPreset,
                        items: _musicPresets
                            .map((p) => DropdownMenuItem(value: p['url'], child: Text(p['label']!)))
                            .toList(),
                        onChanged: (val) {
                          _selectedPreset = val;
                          _musicUrlCtrl.text = val ?? '';
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _musicUrlCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Müzik URL (özel)',
                          labelStyle: TextStyle(color: Color(0xFF00d4ff)),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final url = _musicUrlCtrl.text.trim();
                    if (media.isPlaying) {
                      await media.stop();
                    } else if (url.isNotEmpty) {
                      await media.playUrl(url);
                    }
                    setState(() {});
                  },
                  child: Text(media.isPlaying ? 'Durdur' : 'Çal'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Ses Seviyesi', style: TextStyle(color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: _volume,
                    min: 0,
                    max: 1,
                    divisions: 20,
                    onChanged: (v) async {
                      _volume = v;
                      await media.setVolume(v);
                      setState(() {});
                    },
                    activeColor: const Color(0xFF00d4ff),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _sectionTitle() => const TextStyle(color: Color(0xFF00d4ff), fontSize: 16, fontWeight: FontWeight.bold);
}
