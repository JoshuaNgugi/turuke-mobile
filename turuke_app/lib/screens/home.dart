import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:turuke_app/screens/egg_collection.dart';
import 'package:turuke_app/screens/login.dart';
import 'package:turuke_app/screens/navigation_drawer.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _yieldPercent = 0.0;
  List<FlSpot> _monthlyYield = [];
  Map<String, int> _chickenStatus = {'initial': 0, 'current': 0};
  String _selectedMonth = DateTime.now().toIso8601String().substring(0, 7);

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {}

  void _onRouteSelected(String route) {
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Turuke - Farm Stats'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              Navigator.pushReplacementNamed(context, LoginScreen.routeName);
            },
          ),
        ],
      ),
      drawer: AppNavigationDrawer(
        selectedRoute: HomeScreen.routeName,
        onRouteSelected: _onRouteSelected,
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('Previous Day Yield', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 16),
                  Text(
                    '${_yieldPercent.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 32),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('Monthly Yield', style: TextStyle(fontSize: 18)),
                  DropdownButton<String>(
                    value: _selectedMonth,
                    onChanged: (value) {
                      setState(() => _selectedMonth = value!);
                      _fetchStats();
                    },
                    items:
                        ['2025-04', '2025-03']
                            .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)),
                            )
                            .toList(),
                  ),
                  SizedBox(height: 16),
                  Container(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(show: true),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _monthlyYield,
                            isCurved: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('Chicken Status', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 16),
                  Container(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: _chickenStatus['current']!.toDouble(),
                            title: 'Current',
                            color: Colors.green,
                          ),
                          PieChartSectionData(
                            value:
                                (_chickenStatus['initial']! -
                                        _chickenStatus['current']!)
                                    .toDouble(),
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
          ),
        ],
      ),
    );
  }
}
