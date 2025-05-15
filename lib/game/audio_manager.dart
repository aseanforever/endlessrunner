import '/models/game_settings.dart';
import 'package:flame/flame.dart';
import 'package:flame_audio/flame_audio.dart';
import 'dart:async';

/// This class is the common interface between [DinoRun]
/// and [Flame] engine's audio APIs.
class AudioManager {
  late GameSettings gameSettings;
  AudioManager._internal() {
    _isInitialized = false;
    _bgmPlaying = false;
    _currentBgm = null;
    _audioFocusLostTime = null;
  }

  /// [_instance] represents the single static instance of [AudioManager].
  static final AudioManager _instance = AudioManager._internal();

  /// A getter to access the single instance of [AudioManager].
  static AudioManager get instance => _instance;

  // Add these variables to track audio state
  bool _isInitialized = false;
  bool _bgmPlaying = false;
  String? _currentBgm;
  DateTime? _audioFocusLostTime;
  Timer? _recoveryTimer;

  /// This method is responsible for initializing caching given list of [files],
  /// and initializing settings.
  Future<void> init(List<String> files, GameSettings gameSettings) async {
    this.gameSettings = gameSettings;
    
    try {
      FlameAudio.bgm.initialize();
      await FlameAudio.audioCache.loadAll(files);
      _isInitialized = true;
      
      // Set up audio focus change listener
      _setupAudioFocusListener();
    } catch (e) {
      print('Error initializing audio: $e');
      _isInitialized = false;
    }
  }
  
  // New method to listen for audio focus changes
  void _setupAudioFocusListener() {
    // This would ideally use platform channel to listen to audio focus
    // changes but for now we'll use a simple timer to periodically check
    // and recover audio if needed
    _recoveryTimer = Timer.periodic(Duration(seconds: 5), (_) {
      _checkAndRecoverAudio();
    });
  }
  
  // Check and recover audio playback if needed
  void _checkAndRecoverAudio() {
    if (_audioFocusLostTime != null) {
      // If audio focus was lost more than 2 seconds ago, try to recover
      if (DateTime.now().difference(_audioFocusLostTime!) > Duration(seconds: 2)) {
        _audioFocusLostTime = null;
        if (_bgmPlaying && _currentBgm != null) {
          // Restart the BGM
          _restartBgm();
        }
      }
    }
  }
  
  // Restart the BGM safely
  void _restartBgm() {
    if (!_isInitialized || _currentBgm == null) return;
    
    try {
      stopBgm();
      // Small delay before restarting
      Future.delayed(Duration(milliseconds: 300), () {
        if (gameSettings.bgm && _currentBgm != null) {
          FlameAudio.bgm.play(_currentBgm!, volume: 0.4);
          _bgmPlaying = true;
        }
      });
    } catch (e) {
      print('Error restarting BGM: $e');
    }
  }

  // Safely starts the given audio file as BGM on loop.
  void startBgm(String fileName) {
    if (!_isInitialized) return;
    
    try {
      if (gameSettings.bgm) {
        // Only start if not already playing the same track
        if (!_bgmPlaying || _currentBgm != fileName) {
          // Stop any currently playing BGM first
          stopBgm();
          
          // Small delay to ensure clean playback
          Future.delayed(Duration(milliseconds: 100), () {
            FlameAudio.bgm.play(fileName, volume: 0.4);
            _bgmPlaying = true;
            _currentBgm = fileName;
          });
        }
      }
    } catch (e) {
      print('Error starting BGM: $e');
      _handleAudioError();
    }
  }

  // Safely pauses the currently playing BGM.
  void pauseBgm() {
    if (!_isInitialized) return;
    
    try {
      if (_bgmPlaying) {
        FlameAudio.bgm.pause();
      }
    } catch (e) {
      print('Error pausing BGM: $e');
      _handleAudioError();
    }
  }

  // Safely resumes the paused BGM.
  void resumeBgm() {
    if (!_isInitialized) return;
    
    try {
      if (gameSettings.bgm && _bgmPlaying) {
        FlameAudio.bgm.resume();
      }
    } catch (e) {
      print('Error resuming BGM: $e');
      _handleAudioError();
    }
  }

  // Safely stops the currently playing BGM.
  void stopBgm() {
    if (!_isInitialized) return;
    
    try {
      if (_bgmPlaying) {
        FlameAudio.bgm.stop();
        _bgmPlaying = false;
      }
    } catch (e) {
      print('Error stopping BGM: $e');
    } finally {
      // Force reset the state even if stop fails
      _bgmPlaying = false;
    }
  }

  // Safely plays a one-shot sound effect.
  void playSfx(String fileName) {
    if (!_isInitialized) return;
    
    try {
      if (gameSettings.sfx) {
        FlameAudio.play(fileName, volume: 0.5);
      }
    } catch (e) {
      print('Error playing SFX: $e');
    }
  }
  
  // Handle audio focus change
  void handleAudioFocusChange(bool hasAudioFocus) {
    if (!hasAudioFocus) {
      // Record when audio focus was lost
      _audioFocusLostTime = DateTime.now();
      pauseBgm();
    } else {
      // Audio focus regained
      _audioFocusLostTime = null;
      if (_bgmPlaying) {
        resumeBgm();
      }
    }
  }
  
  // Handle audio system errors
  void _handleAudioError() {
    // If we get too many errors, disable audio temporarily
    if (!_isInitialized) return;
    
    _audioFocusLostTime = DateTime.now();
    
    // Try to recover in a short while
    Future.delayed(Duration(seconds: 3), () {
      if (_currentBgm != null && gameSettings.bgm) {
        _restartBgm();
      }
    });
  }
  
  // Add method for preparing audio during navigation
  void prepareForNavigation() {
    try {
      // First pause any playing audio
      pauseBgm();
      
      // Small delay to ensure audio system can process the pause
      Future.delayed(Duration(milliseconds: 300), () {
        // Then restart the audio system
        resumeBgm();
      });
    } catch (e) {
      print('Error preparing audio for navigation: $e');
    }
  }
  
  // Clean up resources
  void dispose() {
    _recoveryTimer?.cancel();
    stopBgm();
    _isInitialized = false;
  }
}
