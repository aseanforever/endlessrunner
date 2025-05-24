import 'package:flutter/material.dart';
import '../game/dino_run.dart';
import '../models/game_session_model.dart';
import '../respository/multiplayer_service.dart';

class MultiplayerHud extends StatefulWidget {
  static const id = 'MultiplayerHud';

  final DinoRun game;

  const MultiplayerHud(this.game, {super.key});

  @override
  State<MultiplayerHud> createState() => _MultiplayerHudState();
}

class _MultiplayerHudState extends State<MultiplayerHud> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 30,
      left: 20,
      right: 20,
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Player stats
            _buildPlayerStats(),
            // Opponent stats
            _buildOpponentStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerStats() {
    return ListenableBuilder(
      listenable: widget.game.playerModel,
      builder: (context, child) {
        final player = widget.game.playerModel;
        
        Color borderColor = Colors.blue;
        Color statusColor = Colors.lightBlueAccent;
        
        if (player.lives <= 0) {
          borderColor = Colors.red;
          statusColor = Colors.red;
        } else if (player.lives <= 1) {
          borderColor = Colors.yellow;
          statusColor = Colors.yellow;
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(
                    Icons.favorite,
                    color: player.lives > 2 ? Colors.red : 
                           player.lives > 0 ? Colors.orange : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${player.lives}',
                    style: TextStyle(
                      color: player.lives > 0 ? Colors.white : Colors.grey,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(
                    Icons.health_and_safety,
                    color: player.health > 7 ? Colors.green :
                           player.health > 3 ? Colors.yellow : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${player.health}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Text(
                  player.lives <= 0 ? 'DEAD' : 
                  player.lives <= 1 ? 'CRITICAL' : 'ALIVE',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOpponentStats() {
    if (!widget.game.isMultiplayerMode || widget.game.currentRoomId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<GameSession?>(
      stream: MultiplayerService.listenToGameSession(widget.game.currentRoomId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.orange, width: 2),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Opponent',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Connecting...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        final gameSession = snapshot.data!;
        final currentUserId = MultiplayerService.currentUserId;
        final opponentData = gameSession.getOpponentData(currentUserId);

        Color borderColor = Colors.orange;
        Color statusColor = Colors.orange;
        
        if (opponentData.status == 'dead') {
          borderColor = Colors.red;
          statusColor = Colors.red;
        } else if (opponentData.lives <= 1) {
          borderColor = Colors.yellow;
          statusColor = Colors.yellow;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Opponent',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(
                    Icons.favorite,
                    color: opponentData.lives > 2 ? Colors.red : 
                           opponentData.lives > 0 ? Colors.orange : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${opponentData.lives}',
                    style: TextStyle(
                      color: opponentData.lives > 0 ? Colors.white : Colors.grey,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(
                    Icons.health_and_safety,
                    color: opponentData.health > 7 ? Colors.green :
                           opponentData.health > 3 ? Colors.yellow : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${opponentData.health.toInt()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Text(
                  opponentData.status == 'dead' ? 'DEAD' : 
                  opponentData.lives <= 1 ? 'CRITICAL' : 'ALIVE',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 