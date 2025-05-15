import 'package:endlessrunner/game/dino.dart';
import 'package:endlessrunner/models/game_room.dart';
import 'package:endlessrunner/respository/game_room_repository.dart';
import 'package:endlessrunner/widgets/game_over_menu.dart';
import 'package:endlessrunner/widgets/hud.dart';
import 'package:endlessrunner/widgets/multiplayer_game_over_menu.dart';
import 'package:endlessrunner/widgets/multiplayer_hud.dart';
import 'package:endlessrunner/widgets/pause_menu.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import '../respository/game_setting_respository.dart';
import '../respository/player_respository.dart';
import '../widgets/main_menu.dart';
import '/models/game_settings.dart';
import '/game/audio_manager.dart';
import '/game/enemy_manager.dart';
import '/models/player_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flame/parallax.dart';
import 'dart:math';

class DinoRun extends FlameGame with TapDetector, HasCollisionDetection {
  DinoRun({super.camera, this.roomId, this.isMultiplayer = false});
  
  static const _imageAssets = [
    'DinoSprites - tard.png',
    'AngryPig/Walk (36x30).png',
    'Bat/Flying (46x30).png',
    'Rino/Run (52x34).png',
    'parallax/plx-1.png',
    'parallax/plx-2.png',
    'parallax/plx-3.png',
    'parallax/plx-4.png',
    'parallax/plx-5.png',
    'parallax/plx-6.png',
  ];

  static const _audioAssets = [
    '8BitPlatformerLoop.wav',
    'hurt7.wav',
    'jump14.wav',
  ];

  late Dino _dino;
  late GameSettings gameSettings;
  late PlayerModel playerModel;
  late EnemyManager _enemyManager;
  
  // Multiplayer related fields
  final bool isMultiplayer;
  final String? roomId;
  GameRoom? gameRoom;
  String? currentPlayerId;
  final GameRoomRepository _roomRepository = GameRoomRepository();
  bool _gameStarted = false;
  DateTime? _multiplayerStartTime;
  
  final PlayerRepository playerRepository = PlayerRepository();
  final GameSettingsRepository settingsRepository = GameSettingsRepository();

  Vector2 get virtualSize => camera.viewport.virtualSize;

  get highscore => null;

  // Add this field
  bool _lowMemoryMode = false;

  @override
  Future<void> onLoad() async {
    await Flame.device.fullScreen();
    await Flame.device.setLandscape();

    playerModel = await _readPlayerData();
    gameSettings = await _readSettings();
    currentPlayerId = playerModel.uid;

    if (isMultiplayer && roomId != null) {
      await _setupMultiplayerGame();
    }

    await AudioManager.instance.init(_audioAssets, gameSettings);
    AudioManager.instance.startBgm('8BitPlatformerLoop.wav');

    await images.loadAll(_imageAssets);
    camera.viewfinder.position = camera.viewport.virtualSize * 0.5;

    final parallaxBackground = await loadParallaxComponent(
      [
        ParallaxImageData('parallax/plx-1.png'),
        ParallaxImageData('parallax/plx-2.png'),
        ParallaxImageData('parallax/plx-3.png'),
        ParallaxImageData('parallax/plx-4.png'),
        ParallaxImageData('parallax/plx-5.png'),
        ParallaxImageData('parallax/plx-6.png'),
      ],
      baseVelocity: Vector2(10, 0),
      velocityMultiplierDelta: Vector2(1.4, 0),
    );

    camera.backdrop.add(parallaxBackground);
    
    if (isMultiplayer) {
      startGamePlay();
    }
  }
  
  Future<void> _setupMultiplayerGame() async {
    if (roomId == null) return;
    
    gameRoom = await _roomRepository.getRoom(roomId!);
    if (gameRoom == null) {
      throw Exception('Game room not found');
    }
    
    // Listen to room updates
    _roomRepository.listenToRoom(roomId!).listen((updatedRoom) {
      gameRoom = updatedRoom;
      
      // Start game when status changes to playing
      if (updatedRoom.status == RoomStatus.playing && 
          updatedRoom.startTime != null && 
          !_gameStarted) {
        _multiplayerStartTime = updatedRoom.startTime;
        _startMultiplayerGame();
      }
      
      // Handle game over
      if (updatedRoom.status == RoomStatus.finished && 
          _gameStarted) {
        _handleMultiplayerGameOver();
      }
    });
  }
  
  void _startMultiplayerGame() {
    _gameStarted = true;
  }
  
  void _handleMultiplayerGameOver() {
    pauseEngine();
    AudioManager.instance.pauseBgm();
    
    if (gameRoom!.winnerId == currentPlayerId) {
      // Player won
      overlays.add('MultiplayerGameOverMenu');
    } else {
      // Player lost
      overlays.add('MultiplayerGameOverMenu');
    }
    
    reset();
  }
  
  // Methods to build overlays for standalone multiplayer game
  Widget buildHud() {
    return isMultiplayer ? MultiplayerHud(this) : Hud(this);
  }
  
  Widget buildPauseMenu(BuildContext context) {
    // Note: Pause menu will never actually be shown in multiplayer
    return PauseMenu(this);
  }
  
  Widget buildGameOverMenu(BuildContext context) {
    return GameOverMenu(this);
  }
  
  Widget buildMultiplayerGameOverMenu(BuildContext context) {
    return MultiplayerGameOverMenu(this);
  }

  Future<PlayerModel> _readPlayerData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    String uid = user.uid;
    PlayerModel? player = await playerRepository.getPlayer(uid);

    if (player == null) {
      player = PlayerModel(uid: uid, highscore: 0);
      await playerRepository.createPlayer(player);
    }

    return player;
  }

  Future<GameSettings> _readSettings() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    String uid = user.uid;
    GameSettings? settings = await settingsRepository.getSettings(uid);

    if (settings == null) {
      settings = GameSettings(uid: uid);
      await settingsRepository.createSettings(settings);
    }

    return settings;
  }

  void startGamePlay() {
    // Reset game state for a fresh start
    playerModel.currentScore = 0;
    playerModel.lives = 5;
    playerModel.health = 10;
    
    // Clear existing components if any
    _disconnectActors();
    
    // Create fresh game actors
    _dino = Dino(images.fromCache('DinoSprites - tard.png'), playerModel);
    _enemyManager = EnemyManager();

    world.add(_dino);
    world.add(_enemyManager);
    
    if (!isMultiplayer) {
      overlays.remove(MainMenu.id);
      overlays.add(Hud.id);
    } else {
      overlays.add(MultiplayerHud.id);
    }
  }

  void _disconnectActors() {
    try {
      // Kiểm tra xem _dino đã được khởi tạo chưa và có trong world không
      if (world.children.whereType<Dino>().isNotEmpty) {
        world.children.whereType<Dino>().forEach((dino) => dino.removeFromParent());
      }
      
      // Kiểm tra xem _enemyManager đã được khởi tạo chưa và có trong world không
      if (world.children.whereType<EnemyManager>().isNotEmpty) {
        world.children.whereType<EnemyManager>().forEach((manager) {
          manager.removeAllEnemies();
          manager.removeFromParent();
        });
      }
    } catch (e) {
      // Xử lý ngoại lệ nếu có
      print('Error in _disconnectActors: $e');
    }
  }

  void reset() {
    _disconnectActors();
    playerModel.currentScore = 0;
    playerModel.lives = 5;
    playerModel.resetPlayerData();
    _gameStarted = false;
  }

  // Add this method to check and optimize for memory
  void _checkMemoryUsage(double dt) {
    // Check every 5 seconds
    if (_gameTime % 5 < dt) {
      // If we've had multiple GC pauses, enable low memory mode
      if (_consecutiveGcPauses > 2) {
        _lowMemoryMode = true;
        _optimizeForLowMemory();
      }
    }
  }

  // Implement memory optimization
  void _optimizeForLowMemory() {
    if (_lowMemoryMode) return; // Already optimized
    
    _lowMemoryMode = true;
    
    // Reduce background layers
    try {
      // Find the ParallaxComponent in the backdrop
      final parallaxComponents = camera.backdrop.children.whereType<ParallaxComponent>();
      if (parallaxComponents.isNotEmpty) {
        final parallaxComponent = parallaxComponents.first;
        // Now we can access the layers
        if (parallaxComponent.parallax != null && 
            parallaxComponent.parallax!.layers.length > 3) {
          // Keep only essential layers (remove layers starting from index 3)
          for (int i = parallaxComponent.parallax!.layers.length - 1; i >= 3; i--) {
            parallaxComponent.parallax!.layers.removeAt(i);
          }
        }
      }
    } catch (e) {
      print('Error optimizing parallax: $e');
    }
    
    // Reduce enemy spawn rate
    if (_enemyManager != null) {
      _enemyManager.setSpawnRateFactor(0.7); // Method approach instead of property
    }
  }

  // Monitor for GC pauses
  int _consecutiveGcPauses = 0;
  double _lastFrameTime = 0;
  double _gameTime = 0;

  @override
  void update(double dt) {
    super.update(dt);
    
    // Detect large frame time gaps that might indicate GC pauses
    if (dt > 0.1) { // More than 100ms between frames
      _consecutiveGcPauses++;
    } else {
      _consecutiveGcPauses = max(0, _consecutiveGcPauses - 1);
    }
    
    _gameTime += dt;
    _lastFrameTime = DateTime.now().millisecondsSinceEpoch / 1000;
    
    // Check memory usage periodically
    _checkMemoryUsage(dt);
    
    try {
      if (isMultiplayer && gameRoom != null && _gameStarted) {
        // Update score in multiplayer room
        if (roomId != null && currentPlayerId != null) {
          _roomRepository.updatePlayerScore(roomId!, currentPlayerId!, playerModel.currentScore);
        }
        
        // Check for player death in multiplayer
        if (playerModel.lives <= 0 && gameRoom!.aliveStatus[currentPlayerId] == true) {
          _reportPlayerDeath();
        }
      } else if (!isMultiplayer && world.children.whereType<Dino>().isNotEmpty && playerModel.lives <= 0) {
        // Single player death
        if (!overlays.isActive(GameOverMenu.id)) {
          pauseEngine();
          AudioManager.instance.pauseBgm();
          overlays.add(GameOverMenu.id);
          reset();
        }
      }
    } catch (e) {
      print('Error in update: $e');
    }
  }
  
  void _reportPlayerDeath() async {
    try {
      if (roomId != null && currentPlayerId != null && 
          gameRoom != null && gameRoom!.aliveStatus[currentPlayerId] == true) {
        await _roomRepository.reportPlayerDeath(roomId!, currentPlayerId!);
      }
    } catch (e) {
      print('Error reporting player death: $e');
    }
  }
  
  Future<void> setPlayerReady(bool ready) async {
    if (roomId != null && currentPlayerId != null) {
      await _roomRepository.updateReadyStatus(roomId!, currentPlayerId!, ready);
    }
  }

  @override
  void onTapDown(TapDownInfo info) {
    // Kiểm tra xem _dino đã được khởi tạo và game không ở trạng thái dừng
    try {
      if ((overlays.isActive(Hud.id) || overlays.isActive(MultiplayerHud.id)) && 
          world.children.whereType<Dino>().isNotEmpty) {
        // Tìm Dino trong world thay vì truy cập _dino trực tiếp
        final dino = world.children.whereType<Dino>().first;
        dino.jump();
      }
    } catch (e) {
      print('Error in onTapDown: $e');
    }
    super.onTapDown(info);
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    // In multiplayer, we don't handle pause/resume the same way as singleplayer
    if (isMultiplayer) {
      switch (state) {
        case AppLifecycleState.resumed:
          resumeEngine();
          break;
        case AppLifecycleState.paused:
        case AppLifecycleState.detached:
        case AppLifecycleState.inactive:
        case AppLifecycleState.hidden:
          pauseEngine();
          break;
      }
    } else {
      // Original pause/resume behavior for singleplayer
      switch (state) {
        case AppLifecycleState.resumed:
          if (!(overlays.isActive(PauseMenu.id)) &&
              !(overlays.isActive(GameOverMenu.id))) {
            resumeEngine();
          }
          break;
        case AppLifecycleState.paused:
        case AppLifecycleState.detached:
        case AppLifecycleState.inactive:
        case AppLifecycleState.hidden:
          if (overlays.isActive(Hud.id)) {
            overlays.remove(Hud.id);
            overlays.add(PauseMenu.id);
          }
          pauseEngine();
          break;
      }
    }
    super.lifecycleStateChange(state);
  }
}
