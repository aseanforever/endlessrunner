import 'package:flutter/material.dart';
import '../game/dino_run.dart';
import '../respository/multiplayer_service.dart';

class MultiplayerGameOverMenu extends StatelessWidget {
  static const id = 'MultiplayerGameOverMenu';

  final DinoRun game;
  final bool isWinner;

  const MultiplayerGameOverMenu({
    super.key,
    required this.game,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.black.withAlpha(100),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 100),
            child: Wrap(
              direction: Axis.vertical,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              children: [
                Text(
                  isWinner ? 'You Win!' : 'You Lose!',
                  style: TextStyle(
                    fontSize: 50,
                    color: isWinner ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isWinner 
                      ? 'Congratulations! Your opponent has been defeated!'
                      : 'Better luck next time!',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Clean up and return to main menu
                    if (game.roomId != null) {
                      MultiplayerService.endGame(game.roomId!);
                    }
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/main_menu',
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Back to Main Menu',
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 