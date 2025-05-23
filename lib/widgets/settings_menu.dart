import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/dino_run.dart';
import '/widgets/main_menu.dart';
import '/game/audio_manager.dart';
import '/models/game_settings.dart';
import 'skin_selector_menu.dart';
import 'background_selector_menu.dart';
import 'skin_background_selector.dart';

class SettingsMenu extends StatelessWidget {
  static const id = 'SettingsMenu';
  final DinoRun game;

  const SettingsMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: game.gameSettings,
      child: Center(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              color: Colors.black.withAlpha(100),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 100),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Selector<GameSettings, bool>(
                      selector: (_, settings) => settings.bgm,
                      builder: (context, bgm, __) {
                        return SwitchListTile(
                          title: const Text(
                            'Music',
                            style: TextStyle(
                              fontSize: 30,
                              color: Colors.white,
                            ),
                          ),
                          value: bgm,
                          onChanged: (bool value) {
                            Provider.of<GameSettings>(context, listen: false).updateBgm(value);
                            if (value) {
                              AudioManager.instance.startBgm('8BitPlatformerLoop.wav');
                            } else {
                              AudioManager.instance.stopBgm();
                            }
                          },
                        );
                      },
                    ),
                    Selector<GameSettings, bool>(
                      selector: (_, settings) => settings.sfx,
                      builder: (context, sfx, __) {
                        return SwitchListTile(
                          title: const Text(
                            'Effects',
                            style: TextStyle(
                              fontSize: 30,
                              color: Colors.white,
                            ),
                          ),
                          value: sfx,
                          onChanged: (bool value) {
                            Provider.of<GameSettings>(context, listen: false).updateSfx(value);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        game.overlays.remove(SettingsMenu.id);
                        game.overlays.add(SkinSelectorMenu.id);
                      },
                      child: const Text(
                        'Chọn Skin Dino',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        game.overlays.remove(SettingsMenu.id);
                        game.overlays.add(BackgroundSelectorMenu.id);
                      },
                      child: const Text(
                        'Chọn Background',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        game.overlays.remove(SettingsMenu.id);
                        game.overlays.add(MainMenu.id);
                      },
                      child: const Icon(Icons.arrow_back_ios_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
