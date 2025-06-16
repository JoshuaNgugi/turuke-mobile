import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/models/egg_data.dart';
import 'package:turuke_app/models/flock.dart';
import 'package:turuke_app/models/flock_percentage.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/login.dart';
import 'package:turuke_app/screens/navigation_drawer.dart';
import 'package:turuke_app/utils/http_client.dart' show HttpClient;
import 'package:turuke_app/utils/string_utils.dart';

var logger = Logger(printer: PrettyPrinter());

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _overallEggYieldPercent = 0;
  List<Map<String, dynamic>> _monthlyYield = [];
  List<FlockPercentage> _flockPercentages = [];
  Map<String, int> _chickenStatus = {'initial': 0, 'current': 0};
  String _selectedMonth = DateTime.now().toIso8601String().substring(0, 7);
  bool _isLoading = true;
  int _flockCount = 0;
  List<String> _availableMonths = [];

  @override
  void initState() {
    super.initState();
    _generateAvailableMonths();
    _validateSessionAndFetchStats();
  }

  void _generateAvailableMonths() {
    final now = DateTime.now();
    _availableMonths = [];
    for (int i = 0; i < 12; i++) {
      // For the last 12 months including current
      final monthDateTime = DateTime(now.year, now.month - i, 1);
      // Format as YYYY-MM
      _availableMonths.add(
        '${monthDateTime.year}-${monthDateTime.month.toString().padLeft(2, '0')}',
      );
    }
  }

  Future<void> _validateSessionAndFetchStats() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final tokenExpiresAt = authProvider.tokenExpiresAt;
    final token = authProvider.token;

    DateTime? expiresAt = DateTime.tryParse(tokenExpiresAt ?? '');

    if (expiresAt == null ||
        token == null ||
        DateTime.now().isAfter(expiresAt)) {
      await authProvider.logout();
      Navigator.pushNamedAndRemoveUntil(
        context,
        LoginScreen.routeName,
        (route) => false,
      );
      return;
    }

    await _fetchStats();
  }

  Future<void> _fetchStats({String? selectedMonth}) async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final headers = await authProvider.getHeaders();
    final farmId = authProvider.user!.farmId;
    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);
    final monthToFetch = selectedMonth ?? _selectedMonth;
    try {
      await _fetchOverallEggYield(farmId!, headers, yesterday);
      await _fetchFlockDataAndPercentages(farmId, headers, yesterday);
      await _fetchMonthlyYield(farmId, headers, monthToFetch);
      await _fetchChickenStatus(farmId, headers);
    } catch (e) {
      logger.e('Error during _fetchStats coordinator: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchOverallEggYield(
    int farmId,
    Map<String, String> headers,
    String date,
  ) async {
    try {
      final eggYieldRes = await HttpClient.get(
        context,
        Uri.parse(
          '${Constants.API_BASE_URL}/stats/egg-yield?farm_id=$farmId&date=$date',
        ),
        headers: headers,
      );
      if (eggYieldRes.statusCode == 200) {
        if (mounted) {
          _overallEggYieldPercent =
              jsonDecode(eggYieldRes.body)['percent']?.toDouble() ?? 0;
        }
      } else {
        logger.e(
          'Failed to fetch overall egg yield (${eggYieldRes.statusCode}): ${eggYieldRes.body}',
        );
      }
    } catch (e) {
      logger.e('Error fetching overall egg yield: $e');
      // No need to re-throw, _fetchStats catches it
    }
  }

  // Fetches flock data, egg production, and calculates percentages
  Future<void> _fetchFlockDataAndPercentages(
    int farmId,
    Map<String, String> headers,
    String date,
  ) async {
    try {
      // Fetch flocks
      final flocksRes = await http.get(
        Uri.parse('${Constants.API_BASE_URL}/flocks?farm_id=$farmId'),
        headers: headers,
      );
      List<Flock> flocks = [];
      if (flocksRes.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(flocksRes.body);
        flocks = jsonList.map((json) => Flock.fromJson(json)).toList();
        flocks = flocks.where((flock) => flock.status == 1).toList();
        if (mounted) {
          _flockCount = flocks.length;
        }
      } else {
        logger.e(
          'Failed to fetch flocks (${flocksRes.statusCode}): ${flocksRes.body}',
        );
      }

      // Fetch egg collections for the specific date
      final eggRes = await http.get(
        Uri.parse(
          '${Constants.API_BASE_URL}/egg-production?farm_id=$farmId&collection_date=$date',
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
      }

      // Calculate percentages
      if (mounted) {
        _flockPercentages =
            flocks.map((flock) {
              final eggData = eggs.firstWhere(
                (eggData) => eggData.flockId == flock.id!,
                orElse: () => EggData.empty(),
              );
              final totalEggsCollected = eggData.totalEggs;
              final expectedEggs = flock.currentCount;
              final percentage =
                  expectedEggs > 0
                      ? (totalEggsCollected / expectedEggs) * 100
                      : 0.0;
              FlockPercentage flockPercentage = FlockPercentage(
                flockId: flock.id ?? 0,
                flockName: flock.name,
                eggPercentage: percentage,
                collectionDate: StringUtils.formatDate(eggData.collectionDate),
                flockAge: flock.currentAgeWeeks,
              );
              return flockPercentage;
            }).toList();
      }
    } catch (e) {
      logger.e('Error fetching flock data and percentages: $e');
    }
  }

  // Fetche monthly egg yield data
  Future<void> _fetchMonthlyYield(
    int farmId,
    Map<String, String> headers,
    String month,
  ) async {
    try {
      final monthlyYieldRes = await http.get(
        Uri.parse(
          '${Constants.API_BASE_URL}/stats/monthly-yield?farm_id=$farmId&month=$month',
        ),
        headers: headers,
      );
      if (monthlyYieldRes.statusCode == 200) {
        if (mounted) {
          _monthlyYield = List<Map<String, dynamic>>.from(
            jsonDecode(monthlyYieldRes.body)['data'],
          );
        }
      } else {
        logger.e(
          'Failed to fetch monthly yield (${monthlyYieldRes.statusCode}): ${monthlyYieldRes.body}',
        );
      }
    } catch (e) {
      logger.e('Error fetching monthly yield: $e');
    }
  }

  // Fetche chicken status data
  Future<void> _fetchChickenStatus(
    int farmId,
    Map<String, String> headers,
  ) async {
    try {
      final chickenStatusRes = await http.get(
        Uri.parse(
          '${Constants.API_BASE_URL}/stats/chicken-status?farm_id=$farmId',
        ),
        headers: headers,
      );
      if (chickenStatusRes.statusCode == 200) {
        if (mounted) {
          final decoded = jsonDecode(chickenStatusRes.body);
          _chickenStatus = {
            for (var entry in decoded.entries)
              entry.key: int.tryParse(entry.value.toString()) ?? 0,
          };
        }
      } else {
        logger.e(
          'Failed to fetch chicken status (${chickenStatusRes.statusCode}): ${chickenStatusRes.body}',
        );
      }
    } catch (e) {
      logger.e('Error fetching chicken status: $e');
    }
  }

  void _onRouteSelected(String route) {
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    return Scaffold(
      appBar: AppBar(title: Text('Farm Stats')),
      drawer: AppNavigationDrawer(
        selectedRoute: HomeScreen.routeName,
        onRouteSelected: _onRouteSelected,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .center, // centers horizontally
                            children: [
                              const Text(
                                'Overall Previous Day Egg Yield',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_overallEggYieldPercent.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 32,
                                  color: Color.fromARGB(255, 103, 2, 121),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_flockCount > 1)
                      // Replaced Row with GridView.builder for a grid layout
                      GridView.builder(
                        shrinkWrap:
                            true, // Important: to make GridView work inside a SingleChildScrollView
                        physics:
                            const NeverScrollableScrollPhysics(), // Important: to prevent GridView from having its own scroll
                        itemCount: _flockPercentages.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3, // Number of items in each row
                              crossAxisSpacing:
                                  8.0, // Horizontal spacing between items
                              mainAxisSpacing:
                                  8.0, // Vertical spacing between rows
                              childAspectRatio:
                                  0.9, // Adjust this ratio to control card height relative to width
                            ),
                        itemBuilder: (context, index) {
                          final flockPercentage = _flockPercentages[index];
                          return Card(
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center, // Center content vertically
                                children: [
                                  Text(
                                    flockPercentage.flockName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${flockPercentage.eggPercentage.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Color.fromARGB(255, 103, 2, 121),
                                    ),
                                  ),
                                  Text(flockPercentage.collectionDate),
                                  Text(
                                    'Weeks Old: ${flockPercentage.flockAge}',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    // --- Monthly Egg Yield Chart with Dropdown ---
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0.0,
                      ), // Adjust horizontal padding as needed
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween, // Distribute space between items
                        children: [
                          const Text(
                            'Monthly Egg Yield',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            // Allow the dropdown to take available horizontal space
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Select Month',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ), // Adjust padding
                              ),
                              value: _selectedMonth,
                              items:
                                  _availableMonths.map((String month) {
                                    return DropdownMenuItem<String>(
                                      value: month,
                                      child: Text(
                                        StringUtils.formatMonthDisplay(month),
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null &&
                                    newValue != _selectedMonth) {
                                  setState(() {
                                    _selectedMonth = newValue;
                                  });
                                  _fetchStats(
                                    selectedMonth: newValue,
                                  ); // Re-fetch data for the new month
                                }
                              },
                              isExpanded:
                                  true, // Make dropdown expand to fill available width
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          lineBarsData: [
                            LineChartBarData(
                              spots:
                                  _monthlyYield.map((entry) {
                                    final day = int.parse(
                                      entry['collection_date']
                                          .split('-')[2]
                                          .split('T')[0],
                                    );
                                    final totalEggs = double.tryParse(
                                      (entry['total_eggs'] ?? 0),
                                    );
                                    return FlSpot(day.toDouble(), totalEggs!);
                                  }).toList(),
                              dotData: FlDotData(show: true),
                            ),
                          ],
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, met) {
                                  final day = value.toInt();
                                  day >= 1 && day <= daysInMonth ? '$day' : '';
                                  return Text('${value.toInt() + 1}');
                                },
                                reservedSize: 22,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget:
                                    (value, meta) => Text('${value.toInt()}'),
                                reservedSize: 28,
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(show: true),
                          borderData: FlBorderData(show: true),
                          minX: 1,
                          maxX: daysInMonth.toDouble(),
                          minY: 0,
                          maxY:
                              (_monthlyYield
                                          .map(
                                            (e) => int.parse(
                                              e['total_eggs'] ?? '0',
                                            ),
                                          )
                                          .fold(0, (a, b) => a > b ? a : b)
                                          .toDouble() *
                                      1.2)
                                  .ceilToDouble(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Chicken Status',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            if (_chickenStatus != null)
                              PieChartSectionData(
                                value:
                                    _chickenStatus!['current']?.toDouble() ?? 0,
                                title: 'Current',
                                color: Colors.blue,
                              ),
                            if (_chickenStatus != null)
                              PieChartSectionData(
                                value:
                                    (_chickenStatus!['initial']?.toDouble() ??
                                        0) -
                                    (_chickenStatus!['current']?.toDouble() ??
                                        0),
                                title: 'Lost',
                                color: Colors.red,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
    );
  }
}
