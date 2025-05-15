

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../respository/user_respository.dart';


class UserViewModel extends ChangeNotifier {
  final UserRepository _userRepository = UserRepository();
  UserModel? _currentUser;
  String? errorMessage;

  UserModel? get currentUser => _currentUser;

  Future<void> register(String email, String password, String displayName) async {
    try {
      final newUser = UserModel(email: email, password: password, displayName: displayName, uid: '');
      await _userRepository.registerUser(newUser);
      _currentUser = newUser;
      errorMessage = null;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> login(String username, String password) async {
    try {
      _currentUser = await _userRepository.loginUser(username, password);
      errorMessage = null;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }


}
