import 'package:endlessrunner/game/dino.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import '../respository/game_setting_respository.dart';
import '../respository/player_respository.dart';
import '../respository/multiplayer_service.dart';
import '../models/game_session_model.dart';
import '../widgets/game_over_menu.dart';
import '../widgets/hud.dart';
import '../widgets/multiplayer_hud.dart';
import '../widgets/multiplayer_game_over_menu.dart';
import '../widgets/main_menu.dart';
import '../widgets/pause_menu.dart';
import '/models/game_settings.dart';
import '/game/audio_manager.dart';
import '/game/enemy_manager.dart';
import '/models/player_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flame/parallax.dart';
import 'dart:async';

class DinoRun extends FlameGame with TapDetector, HasCollisionDetection {

  // Multiplayer properties
  final bool isMultiplayer;
  final String? roomId;
  String? tempRoomId; // Temporary storage for room ID during overlay navigation
  StreamSubscription<GameSession?>? _gameSessionSubscription;
  DateTime? _lastGameDataUpdate;
  static const _gameDataUpdateInterval = Duration(milliseconds: 500); // Update every 500ms
  bool _hasWon = false;
  bool _hasLost = false;

  // For enabling multiplayer on existing instance
  bool _dynamicMultiplayer = false;
  String? _dynamicRoomId;

  DinoRun({super.camera, this.isMultiplayer = false, this.roomId});
  
  static const _imageAssets = [
    'Dino/DinoSprites - tard.png',
    'AngryPig/Walk (36x30).png',
    'Bat/Flying (46x30).png',
    'Rino/Run (52x34).png',
    'parallax/default/plx-1.png',
    'parallax/default/plx-2.png',
    'parallax/default/plx-3.png',
    'parallax/default/plx-4.png',
    'parallax/default/plx-5.png',
    'parallax/default/plx-6.png',
  ];

  static const _audioAssets = [
    '8BitPlatformerLoop.wav',
    'hurt7.wav',
    'jump14.wav',
  ];

  late Dino _dino;
  bool _dinoInitialized = false;
  late GameSettings gameSettings;
  late PlayerModel playerModel;
  late EnemyManager _enemyManager;

  final PlayerRepository playerRepository = PlayerRepository();
  final GameSettingsRepository settingsRepository = GameSettingsRepository();

  Vector2 get virtualSize => camera.viewport.virtualSize;

  // Multiplayer getters
  int get lives => playerModel.lives;
  double get health => playerModel.health.toDouble();
  bool get hasWon => _hasWon;

  // Dynamic multiplayer properties  
  bool get isMultiplayerMode => isMultiplayer || _dynamicMultiplayer;
  String? get currentRoomId => roomId ?? _dynamicRoomId;

  @override
  Future<void> onLoad() async {
    await Flame.device.fullScreen();
    await Flame.device.setLandscape();

    playerModel = await _readPlayerData();
    gameSettings = await _readSettings();

    await AudioManager.instance.init(_audioAssets, gameSettings);
    AudioManager.instance.startBgm('8BitPlatformerLoop.wav');

    // Load all required assets first
    await images.loadAll([
      'Dino/DinoSprites - tard.png',
      'Dino/DinoSprites - doux.png',
      'Dino/DinoSprites - mort.png',
      'Dino/DinoSprites - vita.png',
      'AngryPig/Walk (36x30).png',
      'Bat/Flying (46x30).png',
      'Rino/Run (52x34).png',
    ]);

    // Load background assets for all themes
    for (final theme in ['default', 'desert', 'forest']) {
      await images.loadAll(
        _getBackgroundImages(theme).map((path) => path).toList(),
      );
    }

    camera.viewfinder.position = camera.viewport.virtualSize * 0.5;

    final parallaxBackground = await loadParallaxComponent(
      _getBackgroundImages(gameSettings.background).map((e) => ParallaxImageData(e)).toList(),
      baseVelocity: Vector2(10, 0),
      velocityMultiplierDelta: Vector2(1.4, 0),
    );

    camera.backdrop.add(parallaxBackground);

    // Setup multiplayer if enabled
    if (isMultiplayerMode && currentRoomId != null) {
      _setupMultiplayer();
      // Auto-start gameplay in multiplayer mode
      startGamePlay();
    } else {
      // In singleplayer, show main menu
      overlays.add(MainMenu.id);
    }
  }

  List<String> _getBackgroundImages(String theme) {
    switch (theme) {
      case 'desert':
        return [
          'parallax/desert/plx-1.png',
          'parallax/desert/plx-2.png',
          'parallax/desert/plx-3.png',
          'parallax/desert/plx-4.png',
          'parallax/desert/plx-5.png',
        ];
      case 'forest':
        return [
          'parallax/forest/plx-1.png',
          'parallax/forest/plx-2.png',
          'parallax/forest/plx-3.png',
          'parallax/forest/plx-4.png',
          'parallax/forest/plx-5.png',
        ];
      case 'default':
      default:
        return [
          'parallax/default/plx-1.png',
          'parallax/default/plx-2.png',
          'parallax/default/plx-3.png',
          'parallax/default/plx-4.png',
          'parallax/default/plx-5.png',
          'parallax/default/plx-6.png',
        ];
    }
  }

  void _setupMultiplayer() {
    // Reset multiplayer state
    _hasWon = false;
    _hasLost = false;
    
    // Listen to game session changes
    _gameSessionSubscription = MultiplayerService.listenToGameSession(currentRoomId!)
        .listen((gameSession) {
      if (gameSession != null && !_hasWon && !_hasLost) {
        _handleGameSessionUpdate(gameSession);
      }
    });
  }

  void _handleGameSessionUpdate(GameSession gameSession) {
    final currentUserId = MultiplayerService.currentUserId;
    final opponentData = gameSession.getOpponentData(currentUserId);
    
    // Check if opponent is dead and we're still alive
    if (opponentData.status == 'dead' && playerModel.lives > 0 && !_hasWon) {
      _handleMultiplayerWin();
    }
  }

  void _handleMultiplayerWin() {
    if (_hasWon || _hasLost) return;
    _hasWon = true;
    
    pauseEngine();
    AudioManager.instance.pauseBgm();
    overlays.remove(MultiplayerHud.id);
    overlays.add(MultiplayerGameOverMenu.id);
    _disconnectActors();
  }

  void _handleMultiplayerLoss() {
    if (_hasWon || _hasLost) return;
    _hasLost = true;
    
    pauseEngine();
    AudioManager.instance.pauseBgm();
    overlays.remove(MultiplayerHud.id);
    overlays.add(MultiplayerGameOverMenu.id);
    _disconnectActors();
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

  Future<void> reloadBackground() async {
    // Xóa background cũ
    camera.backdrop.removeAll(camera.backdrop.children);
    
    // Load và thêm background mới
    final parallaxBackground = await loadParallaxComponent(
      _getBackgroundImages(gameSettings.background).map((e) => ParallaxImageData(e)).toList(),
      baseVelocity: Vector2(10, 0),
      velocityMultiplierDelta: Vector2(1.4, 0),
    );

    camera.backdrop.add(parallaxBackground);
  }

  Future<void> reloadDino() async {
    if (!_dinoInitialized) return; // Don't reload if dino hasn't been created yet
    
    await images.load('Dino/${gameSettings.dinoSkin}');
    _dino.reload(images.fromCache('Dino/${gameSettings.dinoSkin}'));
  }

  void startGamePlay() {
    // Set multiplayer mode for player model
    playerModel.setMultiplayerMode(isMultiplayerMode);
    
    // Listen to player model changes for immediate updates
    if (isMultiplayerMode) {
      playerModel.addListener(_onPlayerDataChanged);
    }
    
    // Remove any existing overlays
    overlays.remove(MainMenu.id);
    overlays.remove(Hud.id);
    overlays.remove(MultiplayerHud.id);
    
    // Create and add game components
    _dino = Dino(images.fromCache('Dino/${gameSettings.dinoSkin}'), playerModel);
    _dinoInitialized = true;
    _enemyManager = EnemyManager();

    world.add(_dino);
    world.add(_enemyManager);
    
    if (isMultiplayerMode) {
      overlays.add(MultiplayerHud.id);
      // Reset multiplayer state for new game
      _hasWon = false;
      _hasLost = false;
    } else {
      overlays.add(Hud.id);
    }

    // Ensure the game is running
    resumeEngine();
  }

  void _onPlayerDataChanged() {
    if (isMultiplayerMode && currentRoomId != null && !_hasWon && !_hasLost) {
      // Force immediate update when player data changes
      _lastGameDataUpdate = null;
      _updateMultiplayerGameData();
    }
  }

  void _disconnectActors() {
    _dino.removeFromParent();
    _dinoInitialized = false;
    _enemyManager.removeAllEnemies();
    _enemyManager.removeFromParent();
  }

  void reset() {
    _disconnectActors();
    if (!isMultiplayerMode) {
      // Only reset score in singleplayer mode
      playerModel.currentScore = 0;
    }
    playerModel.lives = 5;
    playerModel.resetPlayerData();
  }

  void _updateMultiplayerGameData() async {
    if (!isMultiplayerMode || currentRoomId == null || _hasWon || _hasLost) return;
    
    final now = DateTime.now();
    if (_lastGameDataUpdate != null && 
        now.difference(_lastGameDataUpdate!) < _gameDataUpdateInterval) {
      return;
    }
    
    _lastGameDataUpdate = now;
    
    try {
      final playerData = PlayerGameData(
        userId: MultiplayerService.currentUserId,
        lives: playerModel.lives,
        health: playerModel.health.toDouble(),
        status: playerModel.lives <= 0 ? 'dead' : 'alive',
      );
      
      await MultiplayerService.updatePlayerGameData(currentRoomId!, playerData);
      print('Updated multiplayer data: lives=${playerModel.lives}, health=${playerModel.health}');
    } catch (e) {
      print('Error updating multiplayer game data: $e');
    }
  }

  @override
  void update(double dt) {
    // Update multiplayer data if needed
    if (isMultiplayerMode && currentRoomId != null) {
      _updateMultiplayerGameData();
    }

    // Handle game over condition
    if (playerModel.lives <= 0) {
      if (isMultiplayerMode) {
        // In multiplayer, handle death differently
        if (!overlays.isActive(MultiplayerGameOverMenu.id) && !_hasLost) {
          _handleMultiplayerLoss();
        }
      } else {
        // Single player logic
        if (!overlays.isActive(GameOverMenu.id)) {
          pauseEngine();
          AudioManager.instance.pauseBgm();
          overlays.add(GameOverMenu.id);
          reset();
        }
      }
    }
    super.update(dt);
  }

  @override
  void onTapDown(TapDownInfo info) {
    if (overlays.isActive(Hud.id) || overlays.isActive(MultiplayerHud.id)) {
      _dino.jump();
    }
    super.onTapDown(info);
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!(overlays.isActive(PauseMenu.id)) &&
            !(overlays.isActive(GameOverMenu.id)) &&
            !(overlays.isActive(MultiplayerGameOverMenu.id))) {
          resumeEngine();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        if (overlays.isActive(Hud.id) || overlays.isActive(MultiplayerHud.id)) {
          if (!isMultiplayerMode) {
            // Only pause in singleplayer - remove HUD and show pause menu
            overlays.remove(Hud.id);
            overlays.add(PauseMenu.id);
            pauseEngine();
          }
          // In multiplayer, keep the game running to maintain real-time competition
        }
        break;
    }
    super.lifecycleStateChange(state);
  }

  @override
  void onRemove() {
    _gameSessionSubscription?.cancel();
    
    // Remove listener if in multiplayer mode
    if (isMultiplayerMode) {
      playerModel.removeListener(_onPlayerDataChanged);
    }
    
    super.onRemove();
  }

  void enableMultiplayerMode(String roomId) {
    _dynamicMultiplayer = true;
    _dynamicRoomId = roomId;
    _setupMultiplayer();
  }
}
