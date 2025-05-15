import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserRepository {
  final CollectionReference usersRef = FirebaseFirestore.instance.collection('users');

  Future<void> registerUser(UserModel user) async {
    final userDoc = usersRef.doc(user.uid);
    if ((await userDoc.get()).exists) {
      throw Exception("Username already exists.");
    }
    await userDoc.set(user.toMap());
  }

  Future<UserModel?> loginUser(String username, String password) async {
    final userDoc = await usersRef.where('username', isEqualTo: username).get();
    if (userDoc.docs.isEmpty) {
      throw Exception("User not found.");
    }
    final userData = userDoc.docs.first.data() as Map<String, dynamic>;
    if (userData['password'] == password) {
      return UserModel.fromMap(userData);
    } else {
      throw Exception("Incorrect password.");
    }
  }


}
