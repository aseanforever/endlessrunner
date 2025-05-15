import 'package:cloud_firestore/cloud_firestore.dart';

class AppSettings {
  final String uid;
  final bool bgm;
  final bool sfx;

  AppSettings({
    required this.uid,
    this.bgm = true,
    this.sfx = true,
  });

  factory AppSettings.fromMap(Map<String, dynamic> data) {
    return AppSettings(
      uid: data['uid'],
      bgm: data['bgm'] ?? true,
      sfx: data['sfx'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'bgm': bgm,
      'sfx': sfx,
    };
  }

  Future<void> saveToFirestore() async {
    await FirebaseFirestore.instance
        .collection('settings')
        .doc(uid)
        .set(toMap());
  }

  static Future<AppSettings?> getSettingsByUid(String uid) async {
    final settingsDoc =
        await FirebaseFirestore.instance.collection('settings').doc(uid).get();
    if (settingsDoc.exists) {
      return AppSettings.fromMap(settingsDoc.data()!);
    }
    return null;
  }
}
