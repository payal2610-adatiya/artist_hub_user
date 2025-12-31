import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_hub/core/services/api_service.dart';
import 'package:artist_hub/core/services/storage_service.dart';
import 'package:artist_hub/models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  UserModel? get user => _currentUser; // Add this for compatibility
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    _loadUserFromStorage();
  }
  Future<void> initialize() async {
    await _loadUserFromStorage();
  }


  // ================= Login =================
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.login(
        email: email,
        password: password,
        role: role,
      );

      _isLoading = false;

      if (response['status'] == true) {
        final userData = response['data'];
        if (userData != null) {
          // Check if artist is approved
          if (role == 'artist' && userData['is_approved'] == 0) {
            return {
              'status': false,
              'message': 'Your account is pending admin approval',
              'data': null,
            };
          }

          await _handleLoginSuccess(UserModel.fromJson(userData));
          return response;
        }
      }

      return response;
    } catch (e) {
      _isLoading = false;
      _error = 'Login failed: $e';
      notifyListeners();
      return {
        'status': false,
        'message': 'Login failed: $e',
        'data': null,
      };
    }
  }

  // ================= Register =================
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        address: address,
        role: role,
      );

      _isLoading = false;

      if (response['status'] == true) {
        final userData = response['data'];
        if (userData != null) {
          await _handleLoginSuccess(UserModel.fromJson(userData));
        }
      }

      return response;
    } catch (e) {
      _isLoading = false;
      _error = 'Registration failed: $e';
      notifyListeners();
      return {
        'status': false,
        'message': 'Registration failed: $e',
        'data': null,
      };
    }
  }

  // ================= Check Auth Status =================
  Future<bool> checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (isLoggedIn) {
        await _loadUserFromStorage();
        return _currentUser != null;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ================= Load User From Storage =================
  Future<void> _loadUserFromStorage() async {
    try {
      final user = await _storageService.getUser();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user from storage: $e');
      }
    }
  }

  // ================= Update Profile =================
  Future<Map<String, dynamic>> updateProfile({
    required String id,
    required String name,
    required String phone,
    required String address,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.updateUser(
        id: int.parse(id),
        name: name,
        phone: phone,
        address: address,
      );

      _isLoading = false;

      if (response['status'] == true) {
        if (_currentUser != null) {
          final updatedUser = _currentUser!.copyWith(
            name: name,
            phone: phone,
            address: address,
          );
          _currentUser = updatedUser;
          await _storageService.saveUser(updatedUser);
          notifyListeners();
        }
      }

      return response;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to update profile: $e';
      notifyListeners();
      return {
        'status': false,
        'message': 'Failed to update profile: $e',
        'data': null,
      };
    }
  }

  // ================= Logout =================
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Clear local storage
      await _storageService.clearStorage();

      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      _currentUser = null;
      _error = null;
    } catch (e) {
      // Even if API fails, clear local storage
      await _storageService.clearStorage();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ================= Delete Account =================
  Future<Map<String, dynamic>> deleteAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_currentUser == null) {
        throw Exception('No user logged in');
      }

      // Note: You don't have a deleteUser method in ApiService
      // You might need to add it or implement it differently
      final response = {
        'status': false,
        'message': 'Delete account not implemented',
      };

      _isLoading = false;

      if (response['status'] == true) {
        await logout();
      }

      return response;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to delete account: $e';
      notifyListeners();
      return {
        'status': false,
        'message': 'Failed to delete account: $e',
        'data': null,
      };
    }
  }

  // ================= Helpers =================
  Future<void> _handleLoginSuccess(UserModel user) async {
    _currentUser = user;
    _error = null;

    // Save to local storage
    await _storageService.saveUser(user);

    // Save to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userEmail', user.email.toString());
    await prefs.setString('userRole', user.role.toString());
    await prefs.setString('userId', user.id.toString());

    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Getters for user status
  bool get isArtist => _currentUser?.role == 'artist';
  bool get isCustomer => _currentUser?.role == 'customer';
  bool get isArtistApproved => isArtist && (_currentUser?.isApproved == 1);
  bool get isActive => _currentUser?.isActive == 1;
  int? get userId => _currentUser?.id;

  // Update user in provider (e.g., after profile update)
  Future<void> updateUser(UserModel user) async {
    _currentUser = user;
    await _storageService.saveUser(user);
    notifyListeners();
  }

  // Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  // Get user token (if using JWT)
  Future<String?> getToken() async {
    return await _storageService.getToken();
  }
}