import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/models/egg_data.dart';
import 'package:turuke_app/models/flock.dart';
import 'package:turuke_app/models/flock_percentage.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/utils/string_utils.dart';
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

  Future<void> fetchHomeStats({String? month}) async {
    _status = HomeDataStatus.loading;
    _errorMessage = null; // Clear previous errors
    notifyListeners();

    // Session validation should ideally happen before or be handled by HttpClient
    // For simplicity here, assuming HttpClient or AuthProvider handles token refresh/logout.
    // If not, you might want to call authProvider.validateSession() here.
    final tokenExpiresAt = _authProvider.tokenExpiresAt;
    final token = _authProvider.token;

    DateTime? expiresAt = DateTime.tryParse(tokenExpiresAt ?? '');

    if (expiresAt == null ||
        token == null ||
        DateTime.now().isAfter(expiresAt)) {
      await _authProvider.logout();
      _status = HomeDataStatus.error;
      _errorMessage = 'Session expired. Please log in again.';
      notifyListeners();
      // Handle navigation to login screen in the UI layer
      return;
    }

    try {
      final headers = await _authProvider.getHeaders();
      final farmId = _authProvider.user!.farmId;
      final yesterday = DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String()
          .substring(0, 10);
      final monthToFetch = month ?? _selectedMonth;

      // Update selected month if provided
      if (month != null && month != _selectedMonth) {
        _selectedMonth = month;
      }

      await _fetchOverallEggYield(farmId!, headers, yesterday);
      await _fetchFlockDataAndPercentages(farmId, headers, yesterday);
      await _fetchMonthlyYield(farmId, headers, monthToFetch);
      await _fetchChickenStatus(farmId, headers);

      _status = HomeDataStatus.loaded;
    } catch (e) {
      logger.e('Error fetching home stats: $e');
      _errorMessage = 'Failed to load data: ${e.toString()}';
      _status = HomeDataStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> _fetchOverallEggYield(
    int farmId,
    Map<String, String> headers,
    String date,
  ) async {
    try {
      final eggYieldRes = await http.get(
        Uri.parse(
          '${Constants.LAYERS_API_BASE_URL}/stats/egg-yield?farm_id=$farmId&date=$date',
        ),
        headers: headers,
      );
      if (eggYieldRes.statusCode == 200) {
        _overallEggYieldPercent =
            jsonDecode(eggYieldRes.body)['percent']?.toDouble() ?? 0;
      } else {
        logger.e(
          'Failed to fetch overall egg yield (${eggYieldRes.statusCode}): ${eggYieldRes.body}',
        );
        throw Exception(
          'Failed to fetch overall egg yield',
        ); // Re-throw for parent to catch
      }
    } catch (e) {
      logger.e('Error fetching overall egg yield: $e');
      rethrow; // Re-throw to be caught by fetchHomeStats
    }
  }

  Future<void> _fetchFlockDataAndPercentages(
    int farmId,
    Map<String, String> headers,
    String date,
  ) async {
    try {
      final flocksRes = await http.get(
        Uri.parse('${Constants.LAYERS_API_BASE_URL}/flocks?farm_id=$farmId'),
        headers: headers,
      );
      List<Flock> flocks = [];
      if (flocksRes.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(flocksRes.body);
        flocks =
            jsonList
                .map((json) => Flock.fromJson(json))
                .where((flock) => flock.status == 1)
                .toList();
        _flockCount = flocks.length;
      } else {
        logger.e(
          'Failed to fetch flocks (${flocksRes.statusCode}): ${flocksRes.body}',
        );
        throw Exception('Failed to fetch flocks');
      }

      final eggRes = await http.get(
        Uri.parse(
          '${Constants.LAYERS_API_BASE_URL}/egg-production?farm_id=$farmId&collection_date=$date',
        ),
        headers: headers,
      );
      List<EggData> eggs = [];
      if (eggRes.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(eggRes.body);
        eggs = jsonList.map((json) => EggData.fromJson(json)).toList();
      } else {
        logger.e(
          'Failed to fetch egg production (${eggRes.statusCode}): ${eggRes.body}',
        );
        throw Exception('Failed to fetch egg production');
      }

      _flockPercentages =
          flocks.map((flock) {
            final eggData = eggs.firstWhere(
              (eggData) => eggData.flockId == flock.id!,
              orElse:
                  () =>
                      EggData.empty(), // Ensure EggData.empty() is handled appropriately (e.g., totalEggs = 0)
            );
            final totalEggsCollected = eggData.totalEggs;
            final expectedEggs = flock.currentCount;
            final percentage =
                expectedEggs > 0
                    ? (totalEggsCollected / expectedEggs) * 100
                    : 0.0;
            return FlockPercentage(
              flockId: flock.id ?? 0,
              flockName: flock.name,
              eggPercentage: percentage,
              collectionDate: StringUtils.formatDate(eggData.collectionDate),
              flockAge: flock.currentAgeWeeks,
            );
          }).toList();
    } catch (e) {
      logger.e('Error fetching flock data and percentages: $e');
      rethrow;
    }
  }

  Future<void> _fetchMonthlyYield(
    int farmId,
    Map<String, String> headers,
    String month,
  ) async {
    try {
      final monthlyYieldRes = await http.get(
        Uri.parse(
          '${Constants.LAYERS_API_BASE_URL}/stats/monthly-yield?farm_id=$farmId&month=$month',
        ),
        headers: headers,
      );
      if (monthlyYieldRes.statusCode == 200) {
        _monthlyYield = List<Map<String, dynamic>>.from(
          jsonDecode(monthlyYieldRes.body)['data'],
        );
      } else {
        logger.e(
          'Failed to fetch monthly yield (${monthlyYieldRes.statusCode}): ${monthlyYieldRes.body}',
        );
        throw Exception('Failed to fetch monthly yield');
      }
    } catch (e) {
      logger.e('Error fetching monthly yield: $e');
      rethrow;
    }
  }

  Future<void> _fetchChickenStatus(
    int farmId,
    Map<String, String> headers,
  ) async {
    try {
      final chickenStatusRes = await http.get(
        Uri.parse(
          '${Constants.LAYERS_API_BASE_URL}/stats/chicken-status?farm_id=$farmId',
        ),
        headers: headers,
      );
      if (chickenStatusRes.statusCode == 200) {
        final decoded = jsonDecode(chickenStatusRes.body);
        _chickenStatus = {
          for (var entry in decoded.entries)
            entry.key: int.tryParse(entry.value.toString()) ?? 0,
        };
      } else {
        logger.e(
          'Failed to fetch chicken status (${chickenStatusRes.statusCode}): ${chickenStatusRes.body}',
        );
        throw Exception('Failed to fetch chicken status');
      }
    } catch (e) {
      logger.e('Error fetching chicken status: $e');
      rethrow;
    }
  }
}
