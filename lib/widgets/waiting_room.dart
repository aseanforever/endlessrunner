import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:flame/camera.dart';
import '../models/room_model.dart';
import '../respository/multiplayer_service.dart';
import '../game/dino_run.dart';
import 'multiplayer_hud.dart';
import 'multiplayer_game_over_menu.dart';
import 'multiplayer_lobby.dart';

class WaitingRoom extends StatefulWidget {
  static const id = 'WaitingRoom';
  
  final DinoRun game;

  const WaitingRoom(this.game, {super.key});

  @override
  State<WaitingRoom> createState() => _WaitingRoomState();
}

class _WaitingRoomState extends State<WaitingRoom> {
  bool _isReady = false;
  bool _isStarting = false;

  @override
  void dispose() {
    // Leave room when disposing
    if (widget.game.tempRoomId != null) {
      MultiplayerService.leaveRoom(widget.game.tempRoomId!);
    }
    super.dispose();
  }

  Future<void> _toggleReady() async {
    try {
      final newReadyState = !_isReady;
      await MultiplayerService.updatePlayerReady(widget.game.tempRoomId!, newReadyState);
      setState(() {
        _isReady = newReadyState;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating ready state: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startGame() async {
    setState(() {
      _isStarting = true;
    });

    try {
      await MultiplayerService.startGame(widget.game.tempRoomId!);
      
      if (mounted) {
        // Enable multiplayer mode on the existing game instance
        widget.game.enableMultiplayerMode(widget.game.tempRoomId!);
        
        // Remove waiting room overlay and start game
        widget.game.overlays.remove(WaitingRoom.id);
        widget.game.startGamePlay();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting game: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isStarting = false;
        });
      }
    }
  }

  void _copyRoomId() {
    Clipboard.setData(ClipboardData(text: widget.game.tempRoomId!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Room ID copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: StreamBuilder<Room?>(
        stream: MultiplayerService.listenToRoom(widget.game.tempRoomId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator(color: Colors.white);
          }

          if (snapshot.hasError) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    widget.game.overlays.remove(WaitingRoom.id);
                    widget.game.overlays.add(MultiplayerLobby.id);
                  },
                  child: const Text('Back to Lobby'),
                ),
              ],
            );
          }

          final room = snapshot.data;

          if (room == null) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning,
                  color: Colors.white,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Room not found',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    widget.game.overlays.remove(WaitingRoom.id);
                    widget.game.overlays.add(MultiplayerLobby.id);
                  },
                  child: const Text('Back to Lobby'),
                ),
              ],
            );
          }

          // Check if both players are ready and start game automatically
          if (room.bothPlayersReady && !_isStarting) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _startGame();
            });
          }

          final currentUserId = MultiplayerService.currentUserId;
          final isCurrentUserPlayer1 = room.player1?.userId == currentUserId;
          final currentPlayer = isCurrentUserPlayer1 ? room.player1 : room.player2;

          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: Colors.black.withAlpha(100),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Room ID Header - Compact
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Room ID: ',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          GestureDetector(
                            onTap: _copyRoomId,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.game.tempRoomId!,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.copy,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Players Info - Compact
                      _buildPlayerCard(
                        'Player 1',
                        room.player1,
                        isCurrentUserPlayer1,
                      ),

                      const SizedBox(height: 12),

                      _buildPlayerCard(
                        'Player 2',
                        room.player2,
                        !isCurrentUserPlayer1 && room.player2?.userId == currentUserId,
                      ),

                      const SizedBox(height: 20),

                      // Ready Button - Compact
                      if (currentPlayer != null)
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: _isStarting ? null : _toggleReady,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              backgroundColor: currentPlayer.isReady
                                  ? Colors.orange
                                  : Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              currentPlayer.isReady ? 'Not Ready' : 'Ready',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Game Status - Compact
                      if (_isStarting)
                        const Column(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Starting game...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      else if (room.bothPlayersReady)
                        const Text(
                          'Both players ready! Starting game...',
                          style: TextStyle(
                            color: Colors.lightGreenAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        )
                      else if (room.isFull)
                        const Text(
                          'Waiting for both players to be ready...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        )
                      else
                        const Text(
                          'Waiting for another player to join...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),

                      const SizedBox(height: 16),

                      // Leave Room Button - Compact
                      TextButton(
                        onPressed: _isStarting ? null : () {
                          widget.game.overlays.remove(WaitingRoom.id);
                          widget.game.overlays.add(MultiplayerLobby.id);
                        },
                        child: const Text(
                          'Leave Room',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayerCard(String title, PlayerInfo? player, bool isCurrentUser) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isCurrentUser ? Colors.blue : Colors.white30,
          width: isCurrentUser ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isCurrentUser ? Colors.blue.withOpacity(0.1) : null,
      ),
      child: Column(
        children: [
          Text(
            '$title${isCurrentUser ? ' (You)' : ''}',
            style: TextStyle(
              fontSize: 16,
              color: isCurrentUser ? Colors.lightBlueAccent : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          if (player != null) ...[
            Text(
              player.username,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: player.isReady ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    player.isReady ? 'Ready' : 'Not Ready',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (player.isHost) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.star,
                    color: Colors.yellow,
                    size: 14,
                  ),
                ],
              ],
            ),
          ] else
            const Text(
              'Waiting...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
} 