import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_settings.dart';

class GameSettingsRepository {
  final CollectionReference settingsRef =
      FirebaseFirestore.instance.collection('settings');

  Future<void> createSettings(GameSettings settings) async {
    final settingsDoc = settingsRef.doc(settings.uid);
    if ((await settingsDoc.get()).exists) {
      throw Exception("Settings already exist.");
    }
    await settingsDoc.set(settings.toMap());
  }

  Future<GameSettings?> getSettings(String uid) async {
    final settingsDoc = await settingsRef.doc(uid).get();
    if (settingsDoc.exists) {
      return GameSettings.fromMap(
          settingsDoc.data() as Map<String, dynamic>, uid);
    }
    return null;
  }
}
