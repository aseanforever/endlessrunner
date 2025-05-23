import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_settings.dart';
import '../game/dino_run.dart';

class BackgroundSelectorMenu extends StatelessWidget {
  static const id = 'BackgroundSelectorMenu';
  final DinoRun game;

  const BackgroundSelectorMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    final backgrounds = {
      'default': [
        'plx-1.png',
        'plx-2.png',
        'plx-3.png',
        'plx-4.png',
        'plx-5.png',
        'plx-6.png',
      ],
      'desert': [
        'plx-1.png',
        'plx-2.png',
        'plx-3.png',
        'plx-4.png',
        'plx-5.png',
      ],
      'forest': [
        'plx-1.png',
        'plx-2.png',
        'plx-3.png',
        'plx-4.png',
        'plx-5.png',
      ],
    };

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
                      'Chọn Background',
                      style: TextStyle(fontSize: 30, color: Colors.white),
                    ),
                    const SizedBox(height: 40),
                    Expanded(
                      child: Consumer<GameSettings>(
                        builder: (context, settings, _) {
                          return ListView.separated(
                            itemCount: backgrounds.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 20),
                            itemBuilder: (context, index) {
                              final theme = backgrounds.keys.elementAt(index);
                              final images = backgrounds[theme]!;
                              return GestureDetector(                                onTap: () async {
                                  settings.updateBackground(theme);
                                  await settings.saveToFirestore();
                                  await game.reloadBackground();
                                },
                                child: Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    border: settings.background == theme
                                      ? Border.all(color: Colors.yellow, width: 3)
                                      : null,
                                    color: Colors.black26,
                                  ),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: images.take(3).map((img) => Expanded(
                                            child: Image.asset(
                                              'assets/images/parallax/$theme/$img',
                                              fit: BoxFit.cover,
                                            ),
                                          )).toList(),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          theme.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
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
                    ),                    TextButton(
                      onPressed: () async {
                        await game.reloadBackground();
                        game.overlays.remove(BackgroundSelectorMenu.id);
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
