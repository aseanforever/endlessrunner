import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/camera.dart';
import 'package:provider/provider.dart';

import '../game/dino_run.dart';
import '../models/player_model.dart';
import '../models/game_settings.dart';
import 'game_over_menu.dart';
import 'hud.dart';
import 'main_menu.dart';
import 'pause_menu.dart';
import 'settings_menu.dart';
import 'multiplayer_lobby.dart';
import 'waiting_room.dart';
import 'multiplayer_hud.dart';
import 'multiplayer_game_over_menu.dart';
import 'skin_selector_menu.dart';
import 'background_selector_menu.dart';

class MainMenuWrapper extends StatelessWidget {
  const MainMenuWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget<DinoRun>.controlled(
        loadingBuilder: (context) => const Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: CircularProgressIndicator(),
          ),
        ),
        overlayBuilderMap: {
          Hud.id: (_, game) => Hud(game),
          MainMenu.id: (_, game) => MainMenu(game),
          PauseMenu.id: (_, game) => PauseMenu(game),
          GameOverMenu.id: (_, game) => GameOverMenu(game),
          SettingsMenu.id: (_, game) => SettingsMenu(game),
          MultiplayerLobby.id: (_, game) => MultiplayerLobby(game),
          WaitingRoom.id: (_, game) => WaitingRoom(game),
          MultiplayerHud.id: (_, game) => MultiplayerHud(game),
          MultiplayerGameOverMenu.id: (_, game) => MultiplayerGameOverMenu(game: game, isWinner: game.hasWon),
          SkinSelectorMenu.id: (_, game) => SkinSelectorMenu(game),
          BackgroundSelectorMenu.id: (_, game) => BackgroundSelectorMenu(game),
        },
        initialActiveOverlays: const [MainMenu.id],
        gameFactory: () => DinoRun(
          camera: CameraComponent.withFixedResolution(
            width: 360,
            height: 180,
          ),
        ),
      ),
    );
  }
}
