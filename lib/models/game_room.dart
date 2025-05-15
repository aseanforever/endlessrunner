import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

enum RoomStatus {
  waiting,
  playing,
  finished
}

class GameRoom {
  final String id;
  final String hostId;
  final List<String> playerIds;
  final Map<String, bool> readyStatus;
  final Map<String, bool> aliveStatus;
  final Map<String, int> playerScores;
  final RoomStatus status;
  final DateTime? startTime;
  final String? winnerId;

  GameRoom({
    required this.id,
    required this.hostId,
    required this.playerIds,
    required this.readyStatus,
    required this.aliveStatus,
    required this.playerScores,
    required this.status,
    this.startTime,
    this.winnerId,
  });

  factory GameRoom.create(String hostId) {
    final String roomId = _generateRoomId();
    return GameRoom(
      id: roomId,
      hostId: hostId,
      playerIds: [hostId],
      readyStatus: {hostId: false},
      aliveStatus: {hostId: true},
      playerScores: {hostId: 0},
      status: RoomStatus.waiting,
    );
  }

  factory GameRoom.fromMap(Map<String, dynamic> data) {
    return GameRoom(
      id: data['id'],
      hostId: data['hostId'],
      playerIds: List<String>.from(data['playerIds']),
      readyStatus: Map<String, bool>.from(data['readyStatus']),
      aliveStatus: Map<String, bool>.from(data['aliveStatus']),
      playerScores: Map<String, int>.from(data['playerScores']),
      status: RoomStatus.values.byName(data['status']),
      startTime: data['startTime'] != null ? (data['startTime'] as Timestamp).toDate() : null,
      winnerId: data['winnerId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hostId': hostId,
      'playerIds': playerIds,
      'readyStatus': readyStatus,
      'aliveStatus': aliveStatus,
      'playerScores': playerScores,
      'status': status.name,
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'winnerId': winnerId,
    };
  }

  GameRoom copyWith({
    String? id,
    String? hostId,
    List<String>? playerIds,
    Map<String, bool>? readyStatus,
    Map<String, bool>? aliveStatus,
    Map<String, int>? playerScores,
    RoomStatus? status,
    DateTime? startTime,
    String? winnerId,
  }) {
    return GameRoom(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      playerIds: playerIds ?? this.playerIds,
      readyStatus: readyStatus ?? this.readyStatus,
      aliveStatus: aliveStatus ?? this.aliveStatus,
      playerScores: playerScores ?? this.playerScores,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      winnerId: winnerId ?? this.winnerId,
    );
  }

  static String _generateRoomId() {
    // Tạo ID gồm 6 chữ số ngẫu nhiên
    String result = '';
    final random = Random();
    
    // Tạo 6 chữ số ngẫu nhiên từ 0-9
    for (int i = 0; i < 6; i++) {
      result += random.nextInt(10).toString();
    }
    
    return result;
  }
} 