import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_settings.dart';
import '../game/dino_run.dart';

class SkinSelectorMenu extends StatelessWidget {
  static const id = 'SkinSelectorMenu';
  final DinoRun game;
  
  SkinSelectorMenu(this.game, {super.key});
  
  final Map<String, String> skinPreviews = {
    'DinoSprites - tard.png': 'DinoSprites_tard.gif',
    'DinoSprites - doux.png': 'DinoSprites_doux.gif',
    'DinoSprites - mort.png': 'DinoSprites_mort.gif',
    'DinoSprites - vita.png': 'DinoSprites_vita.gif',
  };

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
                      'Choose Skin Dino',
                      style: TextStyle(fontSize: 30, color: Colors.white),
                    ),
                    const SizedBox(height: 40),
                    Expanded(
                      child: Consumer<GameSettings>(
                        builder: (context, settings, _) {
                          return GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                            ),
                            itemCount: skinPreviews.length,
                            itemBuilder: (context, index) {
                              final skin = skinPreviews.keys.elementAt(index);
                              final gifName = skinPreviews[skin]!;
                              
                              return GestureDetector(
                                onTap: () async {
                                  settings.updateDinoSkin(skin);
                                  await settings.saveToFirestore();
                                  await game.reloadDino();
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: settings.dinoSkin == skin
                                      ? Border.all(color: Colors.yellow, width: 3)
                                      : null,
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Animated GIF preview
                                      Image.asset(
                                        'assets/images/Dino/$gifName',
                                        width: 120,
                                        height: 100,
                                        fit: BoxFit.contain,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        skin.replaceAll('DinoSprites - ', '').replaceAll('.png', ''),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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