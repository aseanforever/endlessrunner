import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/room_model.dart';
import '../models/game_session_model.dart';

class MultiplayerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String _roomsCollection = 'rooms';
  static const String _gameSessionsCollection = 'game_sessions';

  // Generate random 4-digit room ID
  static String _generateRoomId() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString();
  }

  // Get current user info
  static String get currentUserId => _auth.currentUser?.uid ?? '';
  static String get currentUserEmail => _auth.currentUser?.email ?? '';
  static String get currentUsername => 
      _auth.currentUser?.displayName ?? 
      _auth.currentUser?.email?.split('@')[0] ?? 
      'Player';

  // Create new room
  static Future<String> createRoom() async {
    String roomId;
    DocumentSnapshot roomDoc;
    
    // Generate unique room ID
    do {
      roomId = _generateRoomId();
      roomDoc = await _firestore.collection(_roomsCollection).doc(roomId).get();
    } while (roomDoc.exists);

    final playerInfo = PlayerInfo(
      userId: currentUserId,
      username: currentUsername,
      isReady: false,
      isHost: true,
    );

    final room = Room(
      roomId: roomId,
      player1: playerInfo,
      player2: null,
      gameState: 'waiting',
      createdAt: DateTime.now(),
    );

    await _firestore.collection(_roomsCollection).doc(roomId).set(room.toMap());
    return roomId;
  }

  // Join existing room
  static Future<bool> joinRoom(String roomId) async {
    try {
      final roomDoc = await _firestore.collection(_roomsCollection).doc(roomId).get();
      
      if (!roomDoc.exists) {
        throw Exception('Room does not exist');
      }

      final room = Room.fromMap(roomDoc.data() as Map<String, dynamic>);
      
      if (room.isFull) {
        throw Exception('Room is full');
      }

      if (room.gameState != 'waiting') {
        throw Exception('Game has already started');
      }

      // Check if current user is already in the room
      if (room.player1?.userId == currentUserId) {
        return true; // Already joined as player1
      }

      final playerInfo = PlayerInfo(
        userId: currentUserId,
        username: currentUsername,
        isReady: false,
        isHost: false,
      );

      await _firestore.collection(_roomsCollection).doc(roomId).update({
        'player2': playerInfo.toMap(),
      });

      return true;
    } catch (e) {
      print('Error joining room: $e');
      return false;
    }
  }

  // Update player ready status
  static Future<void> updatePlayerReady(String roomId, bool isReady) async {
    final roomDoc = await _firestore.collection(_roomsCollection).doc(roomId).get();
    
    if (!roomDoc.exists) {
      throw Exception('Room does not exist');
    }

    final room = Room.fromMap(roomDoc.data() as Map<String, dynamic>);
    final updateField = room.player1?.userId == currentUserId ? 'player1.isReady' : 'player2.isReady';

    await _firestore.collection(_roomsCollection).doc(roomId).update({
      updateField: isReady,
    });
  }

  // Start game (update room state and create game session)
  static Future<void> startGame(String roomId) async {
    final batch = _firestore.batch();

    // Update room state
    final roomRef = _firestore.collection(_roomsCollection).doc(roomId);
    batch.update(roomRef, {'gameState': 'playing'});

    // Get room data to create game session
    final roomDoc = await roomRef.get();
    final room = Room.fromMap(roomDoc.data() as Map<String, dynamic>);

    // Create initial game session with correct starting values
    final gameSession = GameSession(
      roomId: roomId,
      player1Data: PlayerGameData(
        userId: room.player1!.userId,
        lives: 5, // Match game default
        health: 10.0, // Match game default
        status: 'alive',
      ),
      player2Data: PlayerGameData(
        userId: room.player2!.userId,
        lives: 5, // Match game default
        health: 10.0, // Match game default
        status: 'alive',
      ),
      lastUpdated: DateTime.now(),
    );

    final gameSessionRef = _firestore.collection(_gameSessionsCollection).doc(roomId);
    batch.set(gameSessionRef, gameSession.toMap());

    await batch.commit();
  }

  // Listen to room changes
  static Stream<Room?> listenToRoom(String roomId) {
    return _firestore
        .collection(_roomsCollection)
        .doc(roomId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return Room.fromMap(snapshot.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Listen to game session changes
  static Stream<GameSession?> listenToGameSession(String roomId) {
    return _firestore
        .collection(_gameSessionsCollection)
        .doc(roomId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return GameSession.fromMap(snapshot.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Update player game data
  static Future<void> updatePlayerGameData(String roomId, PlayerGameData playerData) async {
    final gameSessionRef = _firestore.collection(_gameSessionsCollection).doc(roomId);
    final gameSessionDoc = await gameSessionRef.get();
    
    if (!gameSessionDoc.exists) {
      throw Exception('Game session does not exist');
    }

    final gameSession = GameSession.fromMap(gameSessionDoc.data() as Map<String, dynamic>);
    final isPlayer1 = gameSession.player1Data.userId == currentUserId;
    
    final updateField = isPlayer1 ? 'player1Data' : 'player2Data';
    
    await gameSessionRef.update({
      updateField: playerData.toMap(),
      'lastUpdated': Timestamp.now(),
    });
  }

  // Leave room
  static Future<void> leaveRoom(String roomId) async {
    final roomDoc = await _firestore.collection(_roomsCollection).doc(roomId).get();
    
    if (!roomDoc.exists) {
      return;
    }

    final room = Room.fromMap(roomDoc.data() as Map<String, dynamic>);
    
    if (room.player1?.userId == currentUserId) {
      if (room.player2 != null) {
        // Promote player2 to player1
        await _firestore.collection(_roomsCollection).doc(roomId).update({
          'player1': room.player2!.toMap(),
          'player2': null,
        });
      } else {
        // Delete room if no other players
        await _firestore.collection(_roomsCollection).doc(roomId).delete();
      }
    } else if (room.player2?.userId == currentUserId) {
      // Remove player2
      await _firestore.collection(_roomsCollection).doc(roomId).update({
        'player2': null,
      });
    }
  }

  // Clean up game session
  static Future<void> cleanupGameSession(String roomId) async {
    await _firestore.collection(_gameSessionsCollection).doc(roomId).delete();
  }

  // End game and clean up
  static Future<void> endGame(String roomId) async {
    final batch = _firestore.batch();

    // Update room state
    final roomRef = _firestore.collection(_roomsCollection).doc(roomId);
    batch.update(roomRef, {'gameState': 'finished'});

    // Delete game session
    final gameSessionRef = _firestore.collection(_gameSessionsCollection).doc(roomId);
    batch.delete(gameSessionRef);

    await batch.commit();
  }
} 