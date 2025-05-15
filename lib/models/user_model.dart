import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String password;
  final String displayName;


  UserModel({
    required this.uid,
    required this.email,
    required this.password,
    required this.displayName,

  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'],
      email: data['email'],
      password: data['password'],
      displayName: data['display_name'],

    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'password': password,
      'display_name': displayName,

    };
  }

  Future<void> saveToFirestore() async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set(toMap());
  }

  static Future<UserModel?> getUserByEmail(String email) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).get();
    if (userDoc.docs.isNotEmpty) {
      return UserModel.fromMap(userDoc.docs.first.data());
    }
    return null;
  }


}
