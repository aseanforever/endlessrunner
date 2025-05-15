import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GameSettings extends ChangeNotifier {
  final String uid;
  bool bgm;
  bool sfx;

  GameSettings({
    required this.uid,
    this.bgm = true,
    this.sfx = true,
  });

  factory GameSettings.fromMap(Map<String, dynamic> data, String uid) {
    return GameSettings(
      uid: uid,
      bgm: data['bgm'] ?? true,
      sfx: data['sfx'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bgm': bgm,
      'sfx': sfx,
    };
  }

  Future<void> saveToFirestore() async {
    await FirebaseFirestore.instance.collection('settings').doc(uid).set(toMap());
  }

  static Future<GameSettings?> getSettings(String uid) async {
    final settingsDoc = await FirebaseFirestore.instance.collection('settings').doc(uid).get();
    if (settingsDoc.exists) {
      return GameSettings.fromMap(settingsDoc.data()!, uid);
    }
    return null;
  }

  void updateBgm(bool value) {
    bgm = value;
    notifyListeners();
  }

  void updateSfx(bool value) {
    sfx = value;
    notifyListeners();
  }
}
