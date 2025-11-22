import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/user.dart';

class AuthProvider with ChangeNotifier {
  final Map<String, User> _users = {};
  final Map<String, String> _usernameToEmail = {};
  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  AuthProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final usersJson = prefs.getString('users');
    if (usersJson != null) {
      final Map<String, dynamic> decoded = json.decode(usersJson);
      decoded.forEach((email, userData) {
        final user = User.fromJson(userData);
        _users[email] = user;
        _usernameToEmail[user.username] = email;
      });
    }

    final currentUserEmail = prefs.getString('currentUserEmail');
    if (currentUserEmail != null && _users.containsKey(currentUserEmail)) {
      _currentUser = _users[currentUserEmail];
      notifyListeners();
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final Map<String, dynamic> usersMap = {};
    _users.forEach((email, user) {
      usersMap[email] = user.toJson();
    });
    await prefs.setString('users', json.encode(usersMap));

    if (_currentUser != null) {
      await prefs.setString('currentUserEmail', _currentUser!.email);
    } else {
      await prefs.remove('currentUserEmail');
    }
  }

  Future<void> login(String usernameOrEmail, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    String? email;
    if (_users.containsKey(usernameOrEmail)) {
      email = usernameOrEmail;
    } else if (_usernameToEmail.containsKey(usernameOrEmail)) {
      email = _usernameToEmail[usernameOrEmail];
    }

    if (email == null || !_users.containsKey(email)) {
      throw 'User does not exist. Please sign up.';
    }

    final user = _users[email]!;
    if (user.password != password) {
      throw 'Incorrect password. Please try again.';
    }

    _currentUser = user;
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String username,
    required String email,
    required String password,
    String? phone,
    String? gender,
    String? country,
    String? profileImageUrl,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    if (_users.containsKey(email)) {
      throw 'An account with this email already exists.';
    }

    if (_usernameToEmail.containsKey(username)) {
      throw 'This username is already taken.';
    }

    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      username: username,
      email: email,
      password: password,
      profileImageUrl: profileImageUrl,
      phone: phone,
      gender: gender,
      country: country,
      createdAt: DateTime.now().toIso8601String(), 
    );

    _users[email] = newUser;
    _usernameToEmail[username] = email;
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> updateUserProfileImage(String imagePath) async {
    if (_currentUser != null) {
      _currentUser!.profileImageUrl = imagePath;
      _users[_currentUser!.email] = _currentUser!;
      await _saveToPrefs();
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? name,
    String? username,
    String? email,
    String? profileImageUrl,
    String? phone,
    String? gender,
    String? country,
  }) async {
    if (_currentUser == null) return;

    final oldEmail = _currentUser!.email;
    final oldUsername = _currentUser!.username;

    if (username != null && username != oldUsername) {
      if (_usernameToEmail.containsKey(username) &&
          _usernameToEmail[username] != oldEmail) {
        throw 'This username is already taken by another user.';
      }
    }

    if (email != null && email != oldEmail) {
      if (_users.containsKey(email)) {
        throw 'This email is already in use by another account.';
      }
    }

    if (name != null) {
      _currentUser!.name = name;
    }
    if (username != null && username != oldUsername) {
      _usernameToEmail.remove(oldUsername);
      _currentUser!.username = username;
      _usernameToEmail[username] = email ?? oldEmail;
    }
    if (email != null && email != oldEmail) {
      _users.remove(oldEmail);
      _currentUser!.email = email;
      _users[email] = _currentUser!;
      _usernameToEmail[_currentUser!.username] = email;
    } else {
      _users[oldEmail] = _currentUser!;
    }
    if (profileImageUrl != null) {
      _currentUser!.profileImageUrl = profileImageUrl;
    }
    if (phone != null) {
      _currentUser!.phone = phone;
    }
    if (gender != null) {
      _currentUser!.gender = gender;
    }
    if (country != null) {
      _currentUser!.country = country;
    }

    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      throw 'No user is currently logged in.';
    }

    if (_currentUser!.password != currentPassword) {
      throw 'Current password is incorrect.';
    }

    if (currentPassword == newPassword) {
      throw 'New password must be different from current password.';
    }

    _currentUser!.password = newPassword;
    _users[_currentUser!.email] = _currentUser!;

    await _saveToPrefs();
    notifyListeners();
  }
}
