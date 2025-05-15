import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../game/dino_run.dart';
import '../models/player_model.dart';
import '../respository/player_respository.dart';

class MultiplayerGameOverMenu extends StatelessWidget {
  static const id = 'MultiplayerGameOverMenu';
  final DinoRun game;

  const MultiplayerGameOverMenu(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    bool isWinner = game.gameRoom?.winnerId == game.currentPlayerId;
    int finalScore = game.playerModel.currentScore;
    bool isHighScore = finalScore > game.playerModel.highscore;

    if (isHighScore) {
      _updateHighScore(game.playerModel, finalScore);
    }

    return Center(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: Colors.black.withAlpha(100),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 100),
              child: Wrap(
                direction: Axis.vertical,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                children: [
                  Text(
                    isWinner ? 'You Win!' : 'You Lose!',
                    style: const TextStyle(
                      fontSize: 50,
                      color: Colors.white,
                    ),
                  ),
                  isHighScore
                      ? const Text(
                          'New High Score!',
                          style: TextStyle(
                            fontSize: 30,
                            color: Colors.amber,
                          ),
                        )
                      : const SizedBox.shrink(),
                  Text(
                    'Score: $finalScore',
                    style: const TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      game.overlays.clear();
                      game.reset();
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Return to Lobby',
                      style: TextStyle(
                        fontSize: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateHighScore(PlayerModel playerModel, int newScore) async {
    if (newScore > playerModel.highscore) {
      playerModel.highscore = newScore;
      playerModel.highScoreDateTime = DateTime.now();
      await playerModel.saveToFirestore();
    }
  }
} 