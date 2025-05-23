import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_settings.dart';
import '../game/dino_run.dart';

class SkinSelectorMenu extends StatelessWidget {
  static const id = 'SkinSelectorMenu';
  final DinoRun game;

  const SkinSelectorMenu(this.game, {super.key});

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
                borderRadius: BorderRadius.circular(20)
              ),
              color: Colors.black.withAlpha(100),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 100),
                child: Column(
                  children: [
                    const Text(
                      'Chọn Skin Dino',
                      style: TextStyle(fontSize: 30, color: Colors.white),
                    ),
                    const SizedBox(height: 40),
                    Expanded(
                      child: Consumer<GameSettings>(
                        builder: (context, settings, _) {
                          return GridView.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 20,
                            crossAxisSpacing: 20,
                            children: [
                              'DinoSprites - tard.png',
                              'DinoSprites - doux.png',
                              'DinoSprites - mort.png',
                              'DinoSprites - vita.png',
                            ].map((skin) => GestureDetector(
                              onTap: () {
                                settings.updateDinoSkin(skin);
                                settings.saveToFirestore();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: settings.dinoSkin == skin
                                    ? Border.all(color: Colors.yellow, width: 3)
                                    : null,
                                  color: Colors.black26,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/Dino/$skin',
                                      width: 100,
                                      height: 100,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      skin.replaceAll('DinoSprites - ', '').replaceAll('.png', ''),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            )).toList(),
                          );
                        },
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        game.overlays.remove(SkinSelectorMenu.id);
                        game.overlays.add('SettingsMenu');
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
