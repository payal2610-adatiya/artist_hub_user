import 'package:flutter/cupertino.dart';

import '../core/services/api_service.dart';
import '../models/user_model.dart';

class CustomerProvider extends ChangeNotifier {
  List<UserModel> _customers = [];
  bool _isLoading = false;
  String? _error;

  List<UserModel> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> getCustomers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.getCustomers();

      if (response['status'] == true) {
        final List data = response['data'];
        _customers = data.map((e) => UserModel.fromJson(e)).toList();
      } else {
        _error = response['message'];
      }
    } catch (e) {
      _error = 'Failed to load customers';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
