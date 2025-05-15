import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_model.dart';

class PlayerRepository {
  final CollectionReference playersRef =
      FirebaseFirestore.instance.collection('players');

  Future<void> createPlayer(PlayerModel player) async {
    final playerDoc = playersRef.doc(player.uid);
    if ((await playerDoc.get()).exists) {
      throw Exception("Player already exists.");
    }
    await playerDoc.set(player.toMap());
  }

  Future<PlayerModel?> getPlayer(String uid) async {
    final playerDoc = await playersRef.doc(uid).get();
    if (playerDoc.exists) {
      return PlayerModel.fromMap(playerDoc.data() as Map<String, dynamic>);
    }
    return null;
  }
}
