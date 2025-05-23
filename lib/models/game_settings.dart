import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GameSettings extends ChangeNotifier {
  final String uid;
  bool bgm;
  bool sfx;
  String dinoSkin;
  String background;

  GameSettings({
    required this.uid,
    this.bgm = true,
    this.sfx = true,
    this.dinoSkin = 'DinoSprites - tard.png',
    this.background = 'default',
  });

  factory GameSettings.fromMap(Map<String, dynamic> data, String uid) {
    return GameSettings(
      uid: uid,
      bgm: data['bgm'] ?? true,
      sfx: data['sfx'] ?? true,
      dinoSkin: data['dinoSkin'] ?? 'DinoSprites - tard.png',
      background: data['background'] ?? 'default',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bgm': bgm,
      'sfx': sfx,
      'dinoSkin': dinoSkin,
      'background': background,
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

  void updateDinoSkin(String value) {
    dinoSkin = value;
    notifyListeners();
  }

  void updateBackground(String value) {
    background = value;
    notifyListeners();
  }
}
