import 'package:endlessrunner/widgets/pause_menu.dart';
import 'package:endlessrunner/widgets/settings_menu.dart';
import 'package:endlessrunner/widgets/skin_selector_menu.dart';
import 'package:endlessrunner/widgets/background_selector_menu.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/camera.dart';

import '../game/dino_run.dart';
import 'game_over_menu.dart';
import 'hud.dart';
import 'main_menu.dart';

class MainMenuWrapper extends StatelessWidget {
  const MainMenuWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget<DinoRun>.controlled(
        loadingBuilder: (context) => const Center(
          child: SizedBox(
            width: 200,
            child: LinearProgressIndicator(),
          ),
        ),
        overlayBuilderMap: {
          MainMenu.id: (_, game) => MainMenu(game),
          PauseMenu.id: (_, game) => PauseMenu(game),
          Hud.id: (_, game) => Hud(game),
          GameOverMenu.id: (_, game) => GameOverMenu(game),
          SettingsMenu.id: (_, game) => SettingsMenu(game),
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
