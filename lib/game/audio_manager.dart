import '/models/game_settings.dart';
import 'package:flame/flame.dart';
import 'package:flame_audio/flame_audio.dart';

/// This class is the common interface between [DinoRun]
/// and [Flame] engine's audio APIs.
class AudioManager {
  late GameSettings gameSettings;
  AudioManager._internal();

  /// [_instance] represents the single static instance of [AudioManager].
  static final AudioManager _instance = AudioManager._internal();

  /// A getter to access the single instance of [AudioManager].
  static AudioManager get instance => _instance;

  /// This method is responsible for initializing caching given list of [files],
  /// and initilizing settings.
  Future<void> init(List<String> files, GameSettings gameSettings) async {
    this.gameSettings = gameSettings;
    FlameAudio.bgm.initialize();
    await FlameAudio.audioCache.loadAll(files);
  }

  // Starts the given audio file as BGM on loop.
  void startBgm(String fileName) {
    if (gameSettings.bgm) {
      FlameAudio.bgm.play(fileName, volume: 0.4);
    }
  }

  // Pauses currently playing BGM if any.
  void pauseBgm() {
    if (gameSettings.bgm) {
      FlameAudio.bgm.pause();
    }
  }

  // Resumes currently paused BGM if any.
  void resumeBgm() {
    if (gameSettings.bgm) {
      FlameAudio.bgm.resume();
    }
  }

  // Stops currently playing BGM if any.
  void stopBgm() {
    FlameAudio.bgm.stop();
  }

  // Plays the given audio file once.
  void playSfx(String fileName) {
    if (gameSettings.sfx) {
      FlameAudio.play(fileName);
    }
  }
}
