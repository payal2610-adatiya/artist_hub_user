import 'package:artist_hub/core/constants/api_endpoints.dart';
import 'package:artist_hub/core/services/shared_pref.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  // Check if user is logged in
  static bool isLoggedIn() {
    return SharedPref.isLoggedIn();
  }

  // Get user role
  static String getUserRole() {
    return SharedPref.getUserRole();
  }

  // Get user ID
  static String getUserId() {
    return SharedPref.getUserId();
  }

  // Get user name
  static String getUserName() {
    return SharedPref.getUserName();
  }

  // Check if artist is approved
  static bool isArtistApproved() {
    return SharedPref.isArtistApproved();
  }

  // Logout
  static Future<void> logout() async {
    await SharedPref.clearUserData();
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateProfile({
    required int id,
    required String name,
    required String phone,
    required String address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.updateUser),
        body: {
          'id': id.toString(),
          'name': name,
          'phone': phone,
          'address': address,
        },
      );

      final data = json.decode(response.body);

      if (data['status'] == true) {
        // Update local storage
        final userData = SharedPref.getUserData();
        userData['name'] = name;
        userData['phone'] = phone;
        userData['address'] = address;
        await SharedPref.saveUserData(userData);

        return {
          'success': true,
          'message': data['message'] ?? 'Profile updated successfully',
          'data': data['data'] ?? data,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to update profile',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }
}