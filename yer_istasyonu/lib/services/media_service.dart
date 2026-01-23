import 'package:media_kit/media_kit.dart';

class MediaService {
  MediaService._internal();
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;

  final Player player = Player();
  bool isPlaying = false;
  double volume = 0.5;

  Future<void> playUrl(String url) async {
    try {
      await player.open(Media(url));
      await player.setVolume(volume);
      await player.play();
      isPlaying = true;
    } catch (e) {
      // ignore errors for now
    }
  }

  Future<void> stop() async {
    try {
      await player.stop();
      isPlaying = false;
    } catch (e) {
      // ignore errors for now
    }
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    try {
      await player.setVolume(volume);
      // ignore: empty_catches
    } catch (e) {}
  }
}
