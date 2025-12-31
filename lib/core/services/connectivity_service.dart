import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController =
  StreamController<bool>.broadcast();

  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  ConnectivityService() {
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus as void Function(List<ConnectivityResult> event)?);
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      await _updateConnectionStatus(result as ConnectivityResult);
    } catch (e) {
      if (kDebugMode) {
        print('Could not check connectivity: $e');
      }
    }
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    final hasConnection = await _hasInternetConnection(result);
    _connectionStatusController.add(hasConnection);
  }

  Future<bool> _hasInternetConnection(ConnectivityResult result) async {
    switch (result) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.mobile:
      case ConnectivityResult.ethernet:
        return true;
      case ConnectivityResult.vpn:
      // VPN might have connection
        return true;
      case ConnectivityResult.bluetooth:
      case ConnectivityResult.other:
        return false;
      case ConnectivityResult.none:
        return false;
    }
  }

  Future<bool> checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    return await _hasInternetConnection(result as ConnectivityResult);
  }

  void dispose() {
    _connectionStatusController.close();
  }
}