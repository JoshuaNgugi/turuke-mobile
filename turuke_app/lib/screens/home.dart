import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/egg_collection.dart';
import 'package:turuke_app/screens/login.dart';
import 'package:turuke_app/screens/navigation_drawer.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:turuke_app/utils/string_utils.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _overallEggYieldPercent = 0;
  List<Map<String, dynamic>> _monthlyYield = [];
  List<Map<String, dynamic>> _flockPercentages = [];
  Map<String, int> _chickenStatus = {'initial': 0, 'current': 0};
  String _selectedMonth = DateTime.now().toIso8601String().substring(0, 7);
  bool _isLoading = true;
  int _flockCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final headers = await authProvider.getHeaders();
    final farmId = authProvider.user!['farm_id'];
    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);

    try {
      // Egg yield overall stat
      final eggYieldRes = await http.get(
        Uri.parse(
          '${Constants.API_BASE_URL}/stats/egg-yield?farm_id=$farmId&date=$yesterday',
        ),
        headers: headers,
      );
      if (eggYieldRes.statusCode == 200) {
        _overallEggYieldPercent =
            jsonDecode(eggYieldRes.body)['percent']?.toDouble() ?? 0;
      }

      // Fetch egg collections for yesterday
      final eggRes = await http.get(
        Uri.parse(
          '${Constants.API_BASE_URL}/egg-production?farm_id=$farmId&collection_date=$yesterday',
        ),
        headers: headers,
      );
      List<Map<String, dynamic>> eggs = [];
      if (eggRes.statusCode == 200) {
        eggs = List<Map<String, dynamic>>.from(jsonDecode(eggRes.body));
      }

      // Fetch flocks
      final flocksRes = await http.get(
        Uri.parse('${Constants.API_BASE_URL}/flocks?farm_id=$farmId'),
        headers: headers,
      );
      List<Map<String, dynamic>> flocks = [];
      if (flocksRes.statusCode == 200) {
        flocks =
            List<Map<String, dynamic>>.from(
              jsonDecode(flocksRes.body),
            ).where((f) => f['status'] == 1).toList();
        _flockCount = flocks.length;
      }

      // Calculate percentages
      double totalWholeEggs = 0.0;
      double totalExpectedEggs = 0.0;
      _flockPercentages =
          flocks.map((flock) {
            final eggData = eggs.firstWhere(
              (e) => e['flock_id'] == flock['id'],
              orElse: () => {'total_eggs': 0},
            );
            final totalEggsCollected =
                double.tryParse(eggData['total_eggs']) ?? 0;
            final expectedEggs = (flock['current_count'] ?? 0).toDouble();
            final percentage =
                expectedEggs > 0
                    ? (totalEggsCollected / expectedEggs) * 100
                    : 0.0;
            totalWholeEggs += totalEggsCollected;
            totalExpectedEggs += expectedEggs;
            String age = flock['current_age_weeks'].toString();
            return {
              'id': flock['id'],
              'breed': flock['breed'],
              'percentage': percentage,
              'date': StringUtils.formatDate(eggData['collection_date']),
              'age': age,
            };
          }).toList();

      // Monthly Yield
      final monthlyYieldRes = await http.get(
        Uri.parse(
          '${Constants.API_BASE_URL}/stats/monthly-yield?farm_id=$farmId&month=$_selectedMonth',
        ),
        headers: headers,
      );
      if (monthlyYieldRes.statusCode == 200) {
        _monthlyYield = List<Map<String, dynamic>>.from(
          jsonDecode(monthlyYieldRes.body)['data'],
        );
      }

      // Chicken Status
      final chickenStatusRes = await http.get(
        Uri.parse(
          '${Constants.API_BASE_URL}/stats/chicken-status?farm_id=$farmId',
        ),
        headers: headers,
      );
      if (chickenStatusRes.statusCode == 200) {
        final decoded = jsonDecode(chickenStatusRes.body);
        _chickenStatus = {
          for (var entry in decoded.entries)
            entry.key: int.tryParse(entry.value.toString()) ?? 0,
        };
      }
    } catch (e) {
      // Handle offline or errors
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onRouteSelected(String route) {
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width / _flockPercentages.length - 16;
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children:
                            _flockPercentages.map((flock) {
                              return SizedBox(
                                width: cardWidth,
                                height: 110,
                                child: Card(
                                  elevation: 3,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      children: [
                                        Text(
                                          flock['breed'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          '${flock['percentage'].toStringAsFixed(1)}%',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            color: Color.fromARGB(
                                              255,
                                              103,
                                              2,
                                              121,
                                            ),
                                          ),
                                        ),
                                        Text(flock['date']),
                                        Text('Weeks Old: ${flock['age']}'),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Monthly Egg Yield',
                        style: TextStyle(fontSize: 18),
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
                  ],
                ),
              ),
    );
  }
}
