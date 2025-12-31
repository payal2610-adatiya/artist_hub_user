import 'dart:convert';
import 'package:artist_hub/core/services/api_service.dart';
import 'package:artist_hub/core/services/auth_storage_service.dart';
import 'package:artist_hub/models/user_model.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await ApiService.login(
        email: email,
        password: password,
        role: role,
      );

      // Handle API response
      if (response['status'] == true) {
        final data = response['data'] ?? {};

        if (data is Map<String, dynamic> && data.isNotEmpty) {
          // Create UserModel from response
          final user = UserModel.fromJson(data);

          // Check if artist is approved
          if (user.role == 'artist' && user.isApproved == 0) {
            return {
              'success': false,
              'message': 'Your account is pending admin approval',
              'data': null,
            };
          }

          // Save user to local storage
          await AuthStorageService.saveUser(user);

          return {
            'success': true,
            'message': response['message'] ?? 'Login successful',
            'data': user,
          };
        } else {
          return {
            'success': false,
            'message': 'Invalid response data format',
            'data': null,
          };
        }
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Login failed',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Login failed: $e',
        'data': null,
      };
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String role,
  }) async {
    try {
      final response = await ApiService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        address: address,
        role: role,
      );

      if (response['status'] == true) {
        final data = response['data'] ?? {};

        if (data is Map<String, dynamic> && data.isNotEmpty) {
          final user = UserModel.fromJson(data);
          await AuthStorageService.saveUser(user);

          String message = response['message'] ?? 'Registration successful';
          if (role == 'artist') {
            message = 'Registration successful. Please wait for admin approval';
          }

          return {
            'success': true,
            'message': message,
            'data': user,
          };
        } else {
          return {
            'success': false,
            'message': 'Invalid response data format',
            'data': null,
          };
        }
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Registration failed',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration failed: $e',
        'data': null,
      };
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      await AuthStorageService.clearAuthData();
      return {
        'success': true,
        'message': 'Logged out successfully',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Logout failed: $e',
        'data': null,
      };
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      return await AuthStorageService.getUser();
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      return await AuthStorageService.isLoggedIn();
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> updateUserProfile({
    required int id,
    required String name,
    required String phone,
    required String address,
  }) async {
    try {
      final response = await ApiService.updateUser(
        id: id,
        name: name,
        phone: phone,
        address: address,
      );

      if (response['status'] == true) {
        final data = response['data'] ?? {};

        if (data is Map<String, dynamic> && data.isNotEmpty) {
          // Update local user data
          final currentUser = await getCurrentUser();
          if (currentUser != null && currentUser.id == id) {
            final updatedUser = UserModel.fromJson(data);
            await AuthStorageService.updateUserData(updatedUser);

            return {
              'success': true,
              'message': 'Profile updated successfully',
              'data': updatedUser,
            };
          }
        }
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Profile update failed',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Profile update failed: $e',
        'data': null,
      };
    }
  }

  // Get user role
  Future<String?> getUserRole() async {
    final user = await getCurrentUser();
    return user?.role;
  }

  // Check if user is artist
  Future<bool> isArtist() async {
    final user = await getCurrentUser();
    return user?.role == 'artist';
  }

  // Check if user is customer
  Future<bool> isCustomer() async {
    final user = await getCurrentUser();
    return user?.role == 'customer';
  }

  // Check if artist is approved
  Future<bool> isArtistApproved() async {
    final user = await getCurrentUser();
    return user?.role == 'artist' && user?.isApproved == 1;
  }

  // Clear user session
  Future<void> clearSession() async {
    await AuthStorageService.clearAuthData();
  }

  // Check authentication state
  Future<Map<String, dynamic>> checkAuthState() async {
    try {
      final isLoggedIn = await this.isLoggedIn();
      final user = await getCurrentUser();

      if (!isLoggedIn || user == null) {
        return {
          'success': false,
          'isAuthenticated': false,
          'message': 'User not logged in',
          'data': null,
        };
      }

      // Check if artist account is approved
      if (user.role == 'artist' && user.isApproved == 0) {
        return {
          'success': false,
          'isAuthenticated': false,
          'message': 'Artist account pending approval',
          'data': user,
        };
      }

      return {
        'success': true,
        'isAuthenticated': true,
        'message': 'User is authenticated',
        'data': user,
      };
    } catch (e) {
      return {
        'success': false,
        'isAuthenticated': false,
        'message': 'Authentication check failed: $e',
        'data': null,
      };
    }
  }

  // Validate session token
  Future<bool> validateSession() async {
    try {
      final user = await getCurrentUser();
      if (user == null) return false;

      // Check if user data is valid
      if (user.id == null || user.id == 0) return false;
      if (user.email == null || user.email!.isEmpty) return false;

      // Additional validation can be added here
      // e.g., check token expiry, validate with server

      return true;
    } catch (e) {
      return false;
    }
  }
}