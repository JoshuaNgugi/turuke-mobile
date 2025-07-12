import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:turuke_app/models/flock_percentage.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/utils/system_utils.dart';

var logger = Logger();

enum HomeDataStatus { initial, loading, loaded, error }

class HomeProvider with ChangeNotifier {
  HomeDataStatus _status = HomeDataStatus.initial;
  HomeDataStatus get status => _status;

  double _overallEggYieldPercent = 0;
  double get overallEggYieldPercent => _overallEggYieldPercent;

  List<Map<String, dynamic>> _monthlyYield = []; // TODO: add model for this
  List<Map<String, dynamic>> get monthlyYield => _monthlyYield;

  List<FlockPercentage> _flockPercentages = [];
  List<FlockPercentage> get flockPercentages => _flockPercentages;

  Map<String, int> _chickenStatus = {'initial': 0, 'current': 0};
  Map<String, int> get chickenStatus => _chickenStatus;

  String _selectedMonth = DateTime.now().toIso8601String().substring(0, 7);
  String get selectedMonth => _selectedMonth;

  int _flockCount = 0;
  int get flockCount => _flockCount;

  List<String> _availableMonths = SystemUtils.generateAvailableMonths();
  List<String> get availableMonths => _availableMonths;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final AuthProvider _authProvider;

  HomeProvider(this._authProvider);
}
