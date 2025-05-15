import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/game_room.dart';
import '../respository/game_room_repository.dart';
import '../game/dino_run.dart';
import 'package:flame/game.dart';
import 'package:flame/camera.dart';
import 'package:flutter/services.dart';
import '../widgets/multiplayer_game_over_menu.dart';
import '../widgets/multiplayer_hud.dart';
import '../widgets/game_over_menu.dart';
import '../widgets/pause_menu.dart';
import 'dart:async';

class MultiplayerLobby extends StatefulWidget {
  const MultiplayerLobby({super.key});

  @override
  State<MultiplayerLobby> createState() => _MultiplayerLobbyState();
}

class _MultiplayerLobbyState extends State<MultiplayerLobby> {
  final GameRoomRepository _roomRepository = GameRoomRepository();
  final TextEditingController _roomIdController = TextEditingController();
  String? _currentRoomId;
  GameRoom? _currentRoom;
  String? _currentUserId;
  bool _isReady = false;
  
  // Stream subscription for room updates
  StreamSubscription? _roomSubscription;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  @override
  void dispose() {
    _roomIdController.dispose();
    _leaveRoom();
    
    // Cancel stream subscription
    _roomSubscription?.cancel();
    
    super.dispose();
  }

  Future<void> _getCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
    }
  }

  Future<void> _createRoom() async {
    if (_currentUserId == null) return;
    
    try {
      final room = await _roomRepository.createRoom(_currentUserId!);
      if (mounted) {
        setState(() {
          _currentRoomId = room.id;
          _currentRoom = room;
        });
        
        _listenToRoomUpdates(room.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating room: $e')),
        );
      }
    }
  }

  Future<void> _joinRoom() async {
    if (_currentUserId == null || _roomIdController.text.isEmpty) return;
    
    try {
      final roomId = _roomIdController.text.trim();
      final success = await _roomRepository.joinRoom(roomId, _currentUserId!);
      
      if (success && mounted) {
        setState(() {
          _currentRoomId = roomId;
        });
        
        _listenToRoomUpdates(roomId);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Room not found or already in progress')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining room: $e')),
        );
      }
    }
  }

  void _listenToRoomUpdates(String roomId) {
    // Cancel existing subscription
    _roomSubscription?.cancel();
    
    _roomSubscription = _roomRepository.listenToRoom(roomId).listen((room) {
      if (mounted) {
        setState(() {
          _currentRoom = room;
        });
        
        // If game starts, navigate to game screen with a new game instance
        if (room.status == RoomStatus.playing && room.startTime != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  body: GameWidget(
                    game: DinoRun(
                      camera: CameraComponent.withFixedResolution(
                        width: 360,
                        height: 180,
                      ),
                      roomId: roomId,
                      isMultiplayer: true,
                    ),
                    overlayBuilderMap: {
                      MultiplayerHud.id: (context, game) => (game as DinoRun).buildHud(),
                      PauseMenu.id: (context, game) => (game as DinoRun).buildPauseMenu(context),
                      GameOverMenu.id: (context, game) => (game as DinoRun).buildGameOverMenu(context),
                      MultiplayerGameOverMenu.id: (context, game) => (game as DinoRun).buildMultiplayerGameOverMenu(context),
                    },
                  ),
                ),
              ),
            );
          });
        }
      }
    });
  }

  Future<void> _toggleReady() async {
    if (_currentRoomId == null || _currentUserId == null) return;
    
    setState(() {
      _isReady = !_isReady;
    });
    
    await _roomRepository.updateReadyStatus(
      _currentRoomId!,
      _currentUserId!,
      _isReady,
    );
  }

  Future<void> _leaveRoom() async {
    if (_currentRoomId != null && _currentUserId != null) {
      await _roomRepository.leaveRoom(_currentRoomId!, _currentUserId!);
      setState(() {
        _currentRoomId = null;
        _currentRoom = null;
        _isReady = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiplayer Lobby'),
        actions: [
          if (_currentRoomId != null)
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: _leaveRoom,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _currentRoomId == null
            ? _buildJoinCreateRoom()
            : _buildRoomDetails(),
      ),
    );
  }

  Widget _buildJoinCreateRoom() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Multiplayer Dino Run',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _createRoom,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 50),
            ),
            child: const Text('Create Room', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 20),
          const Text('OR', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          SizedBox(
            width: 200,
            child: TextField(
              controller: _roomIdController,
              decoration: const InputDecoration(
                labelText: 'Room ID',
                border: OutlineInputBorder(),
                hintText: '6 digits code',
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _joinRoom,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 50),
            ),
            child: const Text('Join Room', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomDetails() {
    if (_currentRoom == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final bool allReady = _currentRoom!.readyStatus.values.every((ready) => ready);
    final bool canStart = allReady && _currentRoom!.playerIds.length >= 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Text(
          'Room ID: ${_currentRoom!.id}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          'Share this code with friends to join',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        const SizedBox(height: 30),
        const Text(
          'Players:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: _currentRoom!.playerIds.length,
            itemBuilder: (context, index) {
              final playerId = _currentRoom!.playerIds[index];
              final isHost = playerId == _currentRoom!.hostId;
              final isCurrentPlayer = playerId == _currentUserId;
              final isReady = _currentRoom!.readyStatus[playerId] ?? false;

              return ListTile(
                leading: Icon(
                  isReady ? Icons.check_circle : Icons.circle_outlined,
                  color: isReady ? Colors.green : Colors.grey,
                ),
                title: Text(
                  'Player ${index + 1}${isCurrentPlayer ? ' (You)' : ''}',
                  style: const TextStyle(fontSize: 18),
                ),
                trailing: isHost
                    ? const Chip(
                        label: Text('Host'),
                        backgroundColor: Colors.blue,
                        labelStyle: TextStyle(color: Colors.white),
                      )
                    : null,
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _toggleReady,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isReady ? Colors.green : Colors.grey,
                minimumSize: const Size(150, 50),
              ),
              child: Text(
                _isReady ? 'Ready' : 'Not Ready',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: 20),
            if (_currentRoom!.hostId == _currentUserId)
              ElevatedButton(
                onPressed: canStart ? () async {
                  if (_currentRoomId != null) {
                    // Update room status to playing
                    await _roomRepository.updateRoomStatus(_currentRoomId!, RoomStatus.playing);
                  }
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(150, 50),
                ),
                child: const Text(
                  'Start Game',
                  style: TextStyle(fontSize: 18),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          canStart
              ? 'Waiting for host to start...'
              : 'Waiting for all players to be ready...',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }
} 