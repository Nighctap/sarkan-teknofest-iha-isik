// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Camera feed widget with video playback support
class CameraFeedWidget extends StatefulWidget {
  final String? videoAsset;

  const CameraFeedWidget({super.key, this.videoAsset = 'assets/vid1.mp4'});

  @override
  State<CameraFeedWidget> createState() => _CameraFeedWidgetState();
}

class _CameraFeedWidgetState extends State<CameraFeedWidget> {
  late final Player _player;
  late final VideoController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    if (widget.videoAsset != null) {
      try {
        // Handle asset paths for Windows/Desktop
        String source = widget.videoAsset!;
        if (!source.startsWith('http') && !source.startsWith('rtsp') && !source.startsWith('file')) {
            if (source.startsWith('assets/')) {
                 source = 'asset:///$source';
            }
        }
        
        await _player.open(Media(source), play: true);
        await _player.setPlaylistMode(PlaylistMode.loop);
        await _player.setVolume(0); // Mute by default for camera feed feel

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      } catch (e) {
        debugPrint('Video error: $e');
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            children: [
              // Video or placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: const Color(0xFF0d1217),
                  child: _isInitialized 
                      ? RepaintBoundary(child: Video(controller: _controller, fit: BoxFit.cover)) 
                      : _buildPlaceholder(),
                ),
              ),

              // Status badges
              Positioned(
                top: 12,
                left: 12,
                child: Row(
                  children: [
                    _buildStatusBadge(
                      icon: _isInitialized ? Icons.fiber_manual_record : Icons.wifi_off,
                      label: _isInitialized ? 'BAĞLANTI SAĞLANDI' : 'BAĞLANTIYI BEKLİYOR',
                      color: _isInitialized ? const Color(0xFF22c55e) : const Color(0xFFf59e0b),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(icon: Icons.hd, label: '720p', color: const Color(0xFF00d4ff)),
                  ],
                ),
              ),

              // Crosshair overlay
              if (_isInitialized)
                Center(
                  child: CustomPaint(painter: CrosshairPainter(), size: const Size(100, 100)),
                ),

              // Recording indicator
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFef4444).withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFef4444)),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'REC',
                        style: TextStyle(color: Color(0xFFef4444), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              // Corner frame decorations
              ..._buildCornerDecorations(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_hasError ? Icons.error_outline : Icons.videocam_off, color: Colors.white24, size: 48),
          const SizedBox(height: 12),
          Text(
            _hasError ? 'Video yüklenemedi' : 'Kamera bağlantısı bekleniyor...',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 4),
          const Text('Video stream URL\'si ayarlanmadı', style: TextStyle(color: Colors.white24, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 10),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerDecorations() {
    const cornerSize = 20.0;
    const cornerColor = Color(0xFF00d4ff);
    const cornerOpacity = 0.5;

    Widget cornerDecoration(Alignment alignment) {
      return Positioned(
        top: alignment == Alignment.topLeft || alignment == Alignment.topRight ? 8 : null,
        bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight ? 8 : null,
        left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft ? 8 : null,
        right: alignment == Alignment.topRight || alignment == Alignment.bottomRight ? 8 : null,
        child: CustomPaint(
          painter: CornerPainter(alignment: alignment, color: cornerColor.withOpacity(cornerOpacity)),
          size: const Size(cornerSize, cornerSize),
        ),
      );
    }

    return [
      cornerDecoration(Alignment.topLeft),
      cornerDecoration(Alignment.topRight),
      cornerDecoration(Alignment.bottomLeft),
      cornerDecoration(Alignment.bottomRight),
    ];
  }
}

class CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00d4ff).withOpacity(0.6)
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);

    // Horizontal line
    canvas.drawLine(Offset(0, center.dy), Offset(center.dx - 10, center.dy), paint);
    canvas.drawLine(Offset(center.dx + 10, center.dy), Offset(size.width, center.dy), paint);

    // Vertical line
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, center.dy - 10), paint);
    canvas.drawLine(Offset(center.dx, center.dy + 10), Offset(center.dx, size.height), paint);

    // Center circle
    canvas.drawCircle(center, 5, paint..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CornerPainter extends CustomPainter {
  final Alignment alignment;
  final Color color;

  CornerPainter({required this.alignment, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    if (alignment == Alignment.topLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (alignment == Alignment.topRight) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (alignment == Alignment.bottomLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else if (alignment == Alignment.bottomRight) {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
