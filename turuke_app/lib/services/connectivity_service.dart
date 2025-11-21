import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

var logger = Logger(printer: PrettyPrinter());

class ConnectivityService with ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;

  ConnectivityService._internal() {
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  List<ConnectivityResult> get connectionStatus => _connectionStatus;

  bool get hasInternetConnection =>
      !_connectionStatus.contains(ConnectivityResult.none) ||
      !_connectionStatus.contains(ConnectivityResult.bluetooth);

  Future<void> _initConnectivity() async {
    late List<ConnectivityResult> result;
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      logger.e("Couldn't check connectivity status: $e");
      // Fallback in case of an error getting the initial status
      result = [ConnectivityResult.none];
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    _connectionStatus = result;
    logger.i('Connectivity changed: $_connectionStatus');
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
