import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_room.dart';

class GameRoomRepository {
  final CollectionReference _roomsCollection = 
      FirebaseFirestore.instance.collection('game_rooms');

  // Create a new game room
  Future<GameRoom> createRoom(String hostId) async {
    final GameRoom room = GameRoom.create(hostId);
    await _roomsCollection.doc(room.id).set(room.toMap());
    return room;
  }

  // Get a game room by its ID
  Future<GameRoom?> getRoom(String roomId) async {
    final DocumentSnapshot doc = await _roomsCollection.doc(roomId).get();
    if (doc.exists) {
      return GameRoom.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Join an existing game room
  Future<bool> joinRoom(String roomId, String playerId) async {
    final room = await getRoom(roomId);
    if (room == null || room.status != RoomStatus.waiting) {
      return false;
    }

    if (room.playerIds.contains(playerId)) {
      return true; // Player already in room
    }

    final List<String> updatedPlayerIds = List.from(room.playerIds)..add(playerId);
    final Map<String, bool> updatedReadyStatus = Map.from(room.readyStatus)..addAll({playerId: false});
    final Map<String, bool> updatedAliveStatus = Map.from(room.aliveStatus)..addAll({playerId: true});
    final Map<String, int> updatedPlayerScores = Map.from(room.playerScores)..addAll({playerId: 0});

    await _roomsCollection.doc(roomId).update({
      'playerIds': updatedPlayerIds,
      'readyStatus': updatedReadyStatus,
      'aliveStatus': updatedAliveStatus,
      'playerScores': updatedPlayerScores,
    });

    return true;
  }

  // Update player ready status
  Future<void> updateReadyStatus(String roomId, String playerId, bool isReady) async {
    await _roomsCollection.doc(roomId).update({
      'readyStatus.$playerId': isReady,
    });

    // Check if all players are ready and start the game
    final room = await getRoom(roomId);
    if (room != null && room.status == RoomStatus.waiting) {
      bool allReady = room.readyStatus.values.every((status) => status == true);
      
      if (allReady && room.playerIds.length >= 2) {
        // Set game status to playing and record start time
        await _roomsCollection.doc(roomId).update({
          'status': RoomStatus.playing.name,
          'startTime': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // Report player death
  Future<void> reportPlayerDeath(String roomId, String playerId) async {
    await _roomsCollection.doc(roomId).update({
      'aliveStatus.$playerId': false,
    });

    // Check if the game is over (only one player alive)
    final room = await getRoom(roomId);
    if (room != null && room.status == RoomStatus.playing) {
      final alivePlayers = room.aliveStatus.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key)
          .toList();

      if (alivePlayers.length == 1) {
        // Game over, set winner
        await _roomsCollection.doc(roomId).update({
          'status': RoomStatus.finished.name,
          'winnerId': alivePlayers.first,
        });
      } else if (alivePlayers.isEmpty) {
        // All players died (tie)
        await _roomsCollection.doc(roomId).update({
          'status': RoomStatus.finished.name,
        });
      }
    }
  }

  // Update player score
  Future<void> updatePlayerScore(String roomId, String playerId, int score) async {
    await _roomsCollection.doc(roomId).update({
      'playerScores.$playerId': score,
    });
  }

  // Listen to room updates
  Stream<GameRoom> listenToRoom(String roomId) {
    return _roomsCollection.doc(roomId).snapshots().map((snapshot) {
      return GameRoom.fromMap(snapshot.data() as Map<String, dynamic>);
    });
  }

  // Leave a room
  Future<void> leaveRoom(String roomId, String playerId) async {
    final room = await getRoom(roomId);
    if (room == null) return;

    if (room.hostId == playerId && room.playerIds.length > 1) {
      // Transfer host status to another player
      String newHostId = room.playerIds.firstWhere((id) => id != playerId);
      
      final List<String> updatedPlayerIds = List.from(room.playerIds)..remove(playerId);
      final Map<String, bool> updatedReadyStatus = Map.from(room.readyStatus)..remove(playerId);
      final Map<String, bool> updatedAliveStatus = Map.from(room.aliveStatus)..remove(playerId);
      final Map<String, int> updatedPlayerScores = Map.from(room.playerScores)..remove(playerId);

      await _roomsCollection.doc(roomId).update({
        'hostId': newHostId,
        'playerIds': updatedPlayerIds,
        'readyStatus': updatedReadyStatus,
        'aliveStatus': updatedAliveStatus,
        'playerScores': updatedPlayerScores,
      });
    } else if (room.hostId == playerId) {
      // Host is leaving and is the only player, delete the room
      await _roomsCollection.doc(roomId).delete();
    } else {
      // Regular player leaving
      final List<String> updatedPlayerIds = List.from(room.playerIds)..remove(playerId);
      final Map<String, bool> updatedReadyStatus = Map.from(room.readyStatus)..remove(playerId);
      final Map<String, bool> updatedAliveStatus = Map.from(room.aliveStatus)..remove(playerId);
      final Map<String, int> updatedPlayerScores = Map.from(room.playerScores)..remove(playerId);

      await _roomsCollection.doc(roomId).update({
        'playerIds': updatedPlayerIds,
        'readyStatus': updatedReadyStatus,
        'aliveStatus': updatedAliveStatus,
        'playerScores': updatedPlayerScores,
      });
    }
  }

  // Update room status (used by host to start game)
  Future<void> updateRoomStatus(String roomId, RoomStatus status) async {
    await _roomsCollection.doc(roomId).update({
      'status': status.name,
      'startTime': status == RoomStatus.playing ? FieldValue.serverTimestamp() : null,
    });
  }
} 