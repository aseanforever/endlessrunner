import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerInfo {
  final String userId;
  final String username;
  final bool isReady;
  final bool isHost;

  PlayerInfo({
    required this.userId,
    required this.username,
    required this.isReady,
    required this.isHost,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'isReady': isReady,
      'isHost': isHost,
    };
  }

  factory PlayerInfo.fromMap(Map<String, dynamic> map) {
    return PlayerInfo(
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      isReady: map['isReady'] ?? false,
      isHost: map['isHost'] ?? false,
    );
  }
}

class Room {
  final String roomId;
  final PlayerInfo? player1;
  final PlayerInfo? player2;
  final String gameState; // "waiting", "playing", "finished"
  final DateTime createdAt;

  Room({
    required this.roomId,
    this.player1,
    this.player2,
    required this.gameState,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'player1': player1?.toMap(),
      'player2': player2?.toMap(),
      'gameState': gameState,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      roomId: map['roomId'] ?? '',
      player1: map['player1'] != null ? PlayerInfo.fromMap(map['player1']) : null,
      player2: map['player2'] != null ? PlayerInfo.fromMap(map['player2']) : null,
      gameState: map['gameState'] ?? 'waiting',
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  bool get isFull => player1 != null && player2 != null;
  bool get bothPlayersReady => 
      player1?.isReady == true && player2?.isReady == true;
} 