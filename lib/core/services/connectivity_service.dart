import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  ConnectivityResult _currentStatus = ConnectivityResult.none;

  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  Future<void> init() async {
    // Check initial connectivity
    _currentStatus = (await _connectivity.checkConnectivity()) as ConnectivityResult;
    _connectionController.add(_currentStatus != ConnectivityResult.none);

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
          (result) {
        _currentStatus = result as ConnectivityResult;
        final bool isConnected = result != ConnectivityResult.none;
        _connectionController.add(isConnected);

        // Show snackbar when connectivity changes
        if (!isConnected) {
          _showNoInternetSnackbar();
        }
      },
    ) as StreamSubscription<ConnectivityResult>?;
  }

  Future<bool> checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  ConnectivityResult get currentStatus => _currentStatus;

  bool get isConnected => _currentStatus != ConnectivityResult.none;

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionController.close();
  }

  void _showNoInternetSnackbar() {
    // This can be implemented in the UI layer
  }
}

// Helper widget to show connectivity status
class ConnectivityWidget extends StatelessWidget {
  final Widget child;
  final Widget? offlineWidget;

  const ConnectivityWidget({
    super.key,
    required this.child,
    this.offlineWidget,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityService().connectionStream,
      initialData: true,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? true;

        if (!isConnected) {
          return offlineWidget ?? _defaultOfflineWidget();
        }

        return child;
      },
    );
  }

  Widget _defaultOfflineWidget() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Internet Connection',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your internet connection',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final isConnected = await ConnectivityService().checkConnection();
                if (!isConnected) {
                  // Still no connection
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// Snackbar helper for connectivity
class ConnectivitySnackbar {
  static void showNoInternet(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white),
            SizedBox(width: 12),
            Text('No Internet Connection'),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static void showConnected(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi, color: Colors.white),
            SizedBox(width: 12),
            Text('Back Online'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

