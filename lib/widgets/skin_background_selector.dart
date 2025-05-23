import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_settings.dart';

class SkinBackgroundSelector extends StatelessWidget {
  final List<String> dinoSkins;
  final Map<String, List<String>> backgrounds;

  const SkinBackgroundSelector({
    super.key,
    required this.dinoSkins,
    required this.backgrounds,
  });

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<GameSettings>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chọn Skin Dino:', style: TextStyle(fontSize: 20, color: Colors.white)),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dinoSkins.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final skin = dinoSkins[index];
              return GestureDetector(
                onTap: () => settings.updateDinoSkin(skin),
                child: Container(
                  decoration: BoxDecoration(
                    border: settings.dinoSkin == skin
                        ? Border.all(color: Colors.yellow, width: 3)
                        : null,
                  ),
                  child: Image.asset(
                    'assets/images/Dino/$skin',
                    width: 64,
                    height: 64,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        const Text('Chọn Background:', style: TextStyle(fontSize: 20, color: Colors.white)),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: backgrounds.entries.expand((entry) {
              final theme = entry.key;
              final images = entry.value;
              return [
                GestureDetector(
                  onTap: () => settings.updateBackground(theme),
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      border: settings.background == theme
                          ? Border.all(color: Colors.yellow, width: 3)
                          : null,
                    ),
                    child: Row(
                      children: images.take(3).map((img) => Image.asset(
                        'assets/images/parallax/$theme/$img',
                        width: 32,
                        height: 64,
                        fit: BoxFit.cover,
                      )).toList(),
                    ),
                  ),
                )
              ];
            }).toList(),
          ),
        ),
      ],
    );
  }
}
