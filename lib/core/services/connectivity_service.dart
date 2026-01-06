import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller =
  StreamController<bool>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Stream<bool> get connectionStream => _controller.stream;

  /// Init connectivity listener
  Future<void> init() async {
    final result = await _connectivity.checkConnectivity();
    _controller.add(_hasConnection(result));

    _subscription =
        _connectivity.onConnectivityChanged.listen((results) {
          _controller.add(_hasConnection(results));
        });
  }

  bool _hasConnection(dynamic result) {
    if (result is List<ConnectivityResult>) {
      return !result.contains(ConnectivityResult.none);
    }
    return result != ConnectivityResult.none;
  }

  /// Manual retry check
  Future<bool> checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    return _hasConnection(result);
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
