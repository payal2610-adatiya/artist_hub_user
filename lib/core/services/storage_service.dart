import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_hub/models/user_model.dart';

class StorageService {
  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userRoleKey = 'user_role';
  static const String _firstLaunchKey = 'first_launch';

  // Initialize SharedPreferences
  Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // Save user data
  Future<bool> saveUser(UserModel user) async {
    try {
      final prefs = await _prefs;
      final userJson = json.encode(user.toJson());

      await prefs.setString(_userKey, userJson);
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userRoleKey, user.role ?? '');

      // Save token if available
      if (user.token != null && user.token!.isNotEmpty) {
        await prefs.setString(_tokenKey, user.token!);
      }

      return true;
    } catch (e) {
      print('Error saving user: $e');
      return false;
    }
  }

  // Get user data
  Future<UserModel?> getUser() async {
    try {
      final prefs = await _prefs;
      final userJson = prefs.getString(_userKey);

      if (userJson != null && userJson.isNotEmpty) {
        final userMap = json.decode(userJson) as Map<String, dynamic>;
        return UserModel.fromJson(userMap);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Save token
  Future<bool> saveToken(String token) async {
    try {
      final prefs = await _prefs;
      return await prefs.setString(_tokenKey, token);
    } catch (e) {
      print('Error saving token: $e');
      return false;
    }
  }

  // Get token
  Future<String?> getToken() async {
    try {
      final prefs = await _prefs;
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await _prefs;
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Get user role
  Future<String?> getUserRole() async {
    try {
      final prefs = await _prefs;
      return prefs.getString(_userRoleKey);
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // Clear all storage data
  Future<bool> clearStorage() async {
    try {
      final prefs = await _prefs;
      await prefs.remove(_userKey);
      await prefs.remove(_tokenKey);
      await prefs.remove(_isLoggedInKey);
      await prefs.remove(_userRoleKey);
      return true;
    } catch (e) {
      print('Error clearing storage: $e');
      return false;
    }
  }

  // Update user data
  Future<bool> updateUser(UserModel user) async {
    try {
      final prefs = await _prefs;
      final userJson = json.encode(user.toJson());
      return await prefs.setString(_userKey, userJson);
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  // Check if first launch
  Future<bool> isFirstLaunch() async {
    try {
      final prefs = await _prefs;
      return prefs.getBool(_firstLaunchKey) ?? true;
    } catch (e) {
      return true;
    }
  }

  // Set first launch completed
  Future<bool> setFirstLaunchCompleted() async {
    try {
      final prefs = await _prefs;
      return await prefs.setBool(_firstLaunchKey, false);
    } catch (e) {
      return false;
    }
  }

  // Save specific user preference
  Future<bool> savePreference(String key, dynamic value) async {
    try {
      final prefs = await _prefs;

      if (value is String) {
        return await prefs.setString(key, value);
      } else if (value is int) {
        return await prefs.setInt(key, value);
      } else if (value is double) {
        return await prefs.setDouble(key, value);
      } else if (value is bool) {
        return await prefs.setBool(key, value);
      } else if (value is List<String>) {
        return await prefs.setStringList(key, value);
      }

      return false;
    } catch (e) {
      print('Error saving preference: $e');
      return false;
    }
  }

  // Get specific user preference
  Future<dynamic> getPreference(String key) async {
    try {
      final prefs = await _prefs;
      return prefs.get(key);
    } catch (e) {
      print('Error getting preference: $e');
      return null;
    }
  }
}