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

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _eggYieldPercent = 0;
  List<Map<String, dynamic>> _monthlyYield = [];
  Map<String, int> _chickenStatus = {'initial': 0, 'current': 0};
  String _selectedMonth = DateTime.now().toIso8601String().substring(0, 7);
  bool _isLoading = true;

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
      // Egg Yield
      final eggYieldRes = await http.get(
        Uri.parse(
          '${Constants.API_BASE_URL}/stats/egg-yield?farm_id=$farmId&date=$yesterday',
        ),
        headers: headers,
      );
      if (eggYieldRes.statusCode == 200) {
        _eggYieldPercent =
            jsonDecode(eggYieldRes.body)['percent']?.toDouble() ?? 0;
      }

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
        _chickenStatus = jsonDecode(chickenStatusRes.body);
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
    return Scaffold(
      appBar: AppBar(title: Text('Turuke - Farm Stats')),
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
                    const Text(
                      'Previous Day Egg Yield',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(
                      height: 100,
                      child: Center(
                        child: Text('${_eggYieldPercent.toStringAsFixed(1)}%'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Monthly Egg Yield',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          lineBarsData: [
                            LineChartBarData(
                              spots:
                                  _monthlyYield
                                      .asMap()
                                      .entries
                                      .map(
                                        (e) => FlSpot(
                                          e.key.toDouble(),
                                          double.tryParse(e.value['yield']) ??
                                              0,
                                        ),
                                      )
                                      .toList(),
                              isCurved: true,
                            ),
                          ],
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget:
                                    (value, meta) =>
                                        Text('${value.toInt() + 1}'),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Chicken Status',
                      style: TextStyle(fontSize: 18),
                    ),
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
