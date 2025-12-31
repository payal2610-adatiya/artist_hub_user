import 'package:flutter/material.dart';
import 'package:artist_hub/core/constants/api_endpoints.dart';
import 'package:artist_hub/core/services/api_service.dart';
import 'package:http/http.dart';

class ProfileProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Future<Map<String, dynamic>> updateUserProfile({
    required String id,
    required String name,
    required String phone,
    required String address,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.updateUser(
        id: int.parse(id),
        name: name,
        phone: phone,
        address: address,
      );

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {
        'status': false,
        'message': 'Failed to update profile',
      };
    }
  }


  void clearError() {
    _error = null;
    notifyListeners();
  }
}