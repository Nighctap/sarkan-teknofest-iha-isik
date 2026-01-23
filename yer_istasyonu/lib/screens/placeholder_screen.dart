import 'package:flutter/material.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0e14),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white, fontFamily: 'monospace')),
        backgroundColor: const Color(0xFF151c25),
        iconTheme: const IconThemeData(color: Color(0xFF00d4ff)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00d4ff).withOpacity(0.1),
                border: Border.all(color: const Color(0xFF00d4ff).withOpacity(0.3)),
              ),
              child: Icon(icon, size: 64, color: const Color(0xFF00d4ff)),
            ),
            const SizedBox(height: 24),
            Text(
              '$title Yapım Aşamasında',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Bu özellik yakında eklenecektir.',
              style: TextStyle(color: Color(0xFF8b949e), fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
