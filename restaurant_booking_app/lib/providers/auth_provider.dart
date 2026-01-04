import 'package:flutter/foundation.dart';
import '../database_helper.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isAuthenticated = false;
  List<User> _allUsers = [];

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  List<User> get allUsers => _allUsers;

  Future<bool> login(String username, String password) async {
    try {
      final user = await DatabaseHelper.instance.getUser(username, password);
      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error during login: $e');
      return false;
    }
  }

  Future<bool> register(
    String username,
    String password,
    String email,
    String phone,
  ) async {
    try {
      // Check if username already exists
      final existingUser = await DatabaseHelper.instance.getUserByUsername(
        username,
      );
      if (existingUser != null) {
        return false;
      }

      // Create new user with 'user' role
      final newUser = User(
        username: username,
        password: password,
        role: 'user',
        email: email,
        phone: phone,
      );

      final id = await DatabaseHelper.instance.insertUser(newUser);
      if (id > 0) {
        _currentUser = newUser.copyWith(id: id);
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error during registration: $e');
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> fetchAllUsers() async {
    try {
      _allUsers = await DatabaseHelper.instance.getAllUsers();
      notifyListeners();
    } catch (e) {
      print('Error fetching all users: $e');
      _allUsers = [];
      notifyListeners();
    }
  }

  Future<bool> deleteUser(int id) async {
    try {
      final result = await DatabaseHelper.instance.deleteUser(id);
      if (result > 0) {
        await fetchAllUsers();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  Future<bool> updateUser(User user) async {
    try {
      final result = await DatabaseHelper.instance.updateUser(user);
      if (result > 0) {
        await fetchAllUsers();
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }
}
