import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerGameData {
  final String userId;
  final int lives;
  final double health;
  final String status; // "alive", "dead"

  PlayerGameData({
    required this.userId,
    required this.lives,
    required this.health,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'lives': lives,
      'health': health,
      'status': status,
    };
  }

  factory PlayerGameData.fromMap(Map<String, dynamic> map) {
    return PlayerGameData(
      userId: map['userId'] ?? '',
      lives: map['lives'] ?? 0,
      health: (map['health'] ?? 0).toDouble(),
      status: map['status'] ?? 'alive',
    );
  }

  PlayerGameData copyWith({
    String? userId,
    int? lives,
    double? health,
    String? status,
  }) {
    return PlayerGameData(
      userId: userId ?? this.userId,
      lives: lives ?? this.lives,
      health: health ?? this.health,
      status: status ?? this.status,
    );
  }
}

class GameSession {
  final String roomId;
  final PlayerGameData player1Data;
  final PlayerGameData player2Data;
  final DateTime lastUpdated;

  GameSession({
    required this.roomId,
    required this.player1Data,
    required this.player2Data,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'player1Data': player1Data.toMap(),
      'player2Data': player2Data.toMap(),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  factory GameSession.fromMap(Map<String, dynamic> map) {
    return GameSession(
      roomId: map['roomId'] ?? '',
      player1Data: PlayerGameData.fromMap(map['player1Data'] ?? {}),
      player2Data: PlayerGameData.fromMap(map['player2Data'] ?? {}),
      lastUpdated: map['lastUpdated'] != null 
          ? (map['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  PlayerGameData getPlayerData(String userId) {
    if (player1Data.userId == userId) {
      return player1Data;
    } else if (player2Data.userId == userId) {
      return player2Data;
    }
    throw Exception('Player not found in game session');
  }

  PlayerGameData getOpponentData(String userId) {
    if (player1Data.userId == userId) {
      return player2Data;
    } else if (player2Data.userId == userId) {
      return player1Data;
    }
    throw Exception('Player not found in game session');
  }

  GameSession updatePlayerData(String userId, PlayerGameData newData) {
    if (player1Data.userId == userId) {
      return GameSession(
        roomId: roomId,
        player1Data: newData,
        player2Data: player2Data,
        lastUpdated: DateTime.now(),
      );
    } else if (player2Data.userId == userId) {
      return GameSession(
        roomId: roomId,
        player1Data: player1Data,
        player2Data: newData,
        lastUpdated: DateTime.now(),
      );
    }
    throw Exception('Player not found in game session');
  }
} 