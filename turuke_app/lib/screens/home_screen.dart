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
import 'package:turuke_app/providers/home_provider.dart';
import 'package:turuke_app/screens/login_screen.dart';
import 'package:turuke_app/screens/navigation_drawer_screen.dart';
import 'package:turuke_app/utils/http_client.dart' show HttpClient;
import 'package:turuke_app/utils/string_utils.dart';
import 'package:turuke_app/utils/system_utils.dart';

var logger = Logger(printer: PrettyPrinter());

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data using the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      homeProvider.fetchHomeStats().then((_) {
        if (homeProvider.status == HomeDataStatus.error &&
            homeProvider.errorMessage ==
                'Session expired. Please log in again.') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            LoginScreen.routeName,
            (route) => false,
          );
        } else if (homeProvider.status == HomeDataStatus.error &&
            homeProvider.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(homeProvider.errorMessage!)));
        }
      });
    });
  }

  void _onRouteSelected(String route) {
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the HomeProvider
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        final now = DateTime.now();
        final daysInMonth =
            DateTime(
              now.year,
              now.month + 1,
              0,
            ).day; // This might need adjustment based on _selectedMonth
        final currentSelectedMonthDate = DateTime.tryParse(
          '${homeProvider.selectedMonth}-01',
        );
        final actualDaysInMonth =
            currentSelectedMonthDate != null
                ? DateTime(
                  currentSelectedMonthDate.year,
                  currentSelectedMonthDate.month + 1,
                  0,
                ).day
                : 31;

        return Scaffold(
          appBar: AppBar(title: Text('Farm Stats')),
          drawer: AppNavigationDrawer(
            selectedRoute: HomeScreen.routeName,
            onRouteSelected: _onRouteSelected,
          ),
          body:
              homeProvider.status == HomeDataStatus.loading
                  ? const Center(child: CircularProgressIndicator())
                  : homeProvider.status == HomeDataStatus.error &&
                      homeProvider.monthlyYield.isEmpty
                  ? Center(
                    child: Text(
                      'Error: ${homeProvider.errorMessage ?? "Could not load data."}\nPull to refresh?',
                    ),
                  ) // Show error, maybe a refresh button
                  : RefreshIndicator(
                    // Add pull-to-refresh
                    onRefresh: () => homeProvider.fetchHomeStats(),
                    child: SingleChildScrollView(
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
                                  crossAxisAlignment: CrossAxisAlignment.center,
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
                                      '${homeProvider.overallEggYieldPercent.toStringAsFixed(1)}%',
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
                          if (homeProvider.flockCount > 1)
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: homeProvider.flockPercentages.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8.0,
                                    mainAxisSpacing: 8.0,
                                    childAspectRatio: 0.9,
                                  ),
                              itemBuilder: (context, index) {
                                final flockPercentage =
                                    homeProvider.flockPercentages[index];
                                return Card(
                                  elevation: 3,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                            color: Color.fromARGB(
                                              255,
                                              103,
                                              2,
                                              121,
                                            ),
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
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 0.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  child: DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: 'Select Month',
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    value: homeProvider.selectedMonth,
                                    items:
                                        homeProvider.availableMonths.map((
                                          String month,
                                        ) {
                                          return DropdownMenuItem<String>(
                                            value: month,
                                            child: Text(
                                              StringUtils.formatMonthDisplay(
                                                month,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null &&
                                          newValue !=
                                              homeProvider.selectedMonth) {
                                        homeProvider.fetchHomeStats(
                                          month: newValue,
                                        ); // Trigger fetch with new month
                                      }
                                    },
                                    isExpanded: true,
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
                                        homeProvider.monthlyYield.map((entry) {
                                          final day = int.parse(
                                            entry['collection_date']
                                                .split('-')[2]
                                                .split('T')[0],
                                          );
                                          final totalEggs =
                                              double.tryParse(
                                                (entry['total_eggs'] ?? 0)
                                                    .toString(),
                                              ) ??
                                              0.0; // Ensure type safety
                                          return FlSpot(
                                            day.toDouble(),
                                            totalEggs,
                                          );
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
                                        if (day < 1 || day > actualDaysInMonth)
                                          return const Text(
                                            '',
                                          ); // Ensure day is within month range
                                        return Text(
                                          '$day',
                                        ); // Only show day if it's within the month
                                      },
                                      reservedSize: 22,
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget:
                                          (value, meta) =>
                                              Text('${value.toInt()}'),
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
                                maxX: actualDaysInMonth.toDouble(),
                                minY: 0,
                                maxY:
                                    (homeProvider.monthlyYield
                                                .map(
                                                  (e) => int.parse(
                                                    e['total_eggs']
                                                            ?.toString() ??
                                                        '0',
                                                  ),
                                                ) // Ensure toString() and handle null
                                                .fold(
                                                  0,
                                                  (a, b) => a > b ? a : b,
                                                )
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
                                  // Use null-aware operators directly from the provider
                                  PieChartSectionData(
                                    value:
                                        homeProvider.chickenStatus['current']
                                            ?.toDouble() ??
                                        0,
                                    title: 'Current',
                                    color: Colors.blue,
                                  ),
                                  PieChartSectionData(
                                    value:
                                        (homeProvider.chickenStatus['initial']
                                                ?.toDouble() ??
                                            0) -
                                        (homeProvider.chickenStatus['current']
                                                ?.toDouble() ??
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
                  ),
        );
      },
    );
  }
}
