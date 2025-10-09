import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:turuke_app/providers/home_provider.dart';
import 'package:turuke_app/screens/login/login_screen.dart';
import 'package:turuke_app/screens/navigation/navigation_drawer_screen.dart';
import 'package:turuke_app/utils/string_utils.dart';

var logger = Logger(printer: PrettyPrinter());

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _primaryColor = Color.fromARGB(255, 103, 2, 121);
  static const Color _secondaryColor = Color.fromARGB(255, 150, 50, 170);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    await homeProvider.fetchHomeStats();

    if (!mounted) return;

    if (homeProvider.status == HomeDataStatus.error) {
      if (homeProvider.errorMessage ==
          'Session expired. Please log in again.') {
        _showSessionExpiredDialog(context);
      } else if (homeProvider.errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(homeProvider.errorMessage!)));
      }
    }
  }

  void _showSessionExpiredDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Session Expired'),
          content: const Text('Your session has expired. Please log in again.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  LoginScreen.routeName,
                  (route) => false,
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _onRouteSelected(String route) {
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Farm Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 0,
      ),
      drawer: AppNavigationDrawer(
        selectedRoute: HomeScreen.routeName,
        onRouteSelected: _onRouteSelected,
      ),
      body: Consumer<HomeProvider>(
        builder: (context, homeProvider, child) {
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
                  : 31; // Fallback to 31 days if parsing fails

          if (homeProvider.status == HomeDataStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(color: _primaryColor),
            );
          } else if (homeProvider.status == HomeDataStatus.error &&
              homeProvider.monthlyYield.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade400,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${homeProvider.errorMessage ?? "Could not load data."}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _fetchData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tap to Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          } else {
            return RefreshIndicator(
              onRefresh: _fetchData,
              color: _primaryColor,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverallYieldCard(homeProvider.overallEggYieldPercent),
                    const SizedBox(height: 16),

                    if (homeProvider.flockCount > 0)
                      _buildFlockPercentagesGrid(homeProvider.flockPercentages),
                    const SizedBox(height: 16),

                    _buildMonthlyYieldChart(
                      homeProvider.availableMonths,
                      homeProvider.selectedMonth,
                      homeProvider.monthlyYield,
                      actualDaysInMonth,
                      homeProvider.fetchHomeStats,
                    ),
                    const SizedBox(height: 16),

                    _buildChickenStatusChart(homeProvider.chickenStatus),

                    const SizedBox(height: 50),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildOverallYieldCard(double yieldPercent) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Overall Previous Day Egg Yield',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${yieldPercent.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'as of ${StringUtils.formatDateDisplay(DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T')[0])}', // Dynamic date
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlockPercentagesGrid(List<dynamic> flockPercentages) {
    if (flockPercentages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Text(
            'Flock Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: flockPercentages.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, index) {
            final flockData = flockPercentages[index];
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      flockData.flockName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${flockData.eggPercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'As of ${StringUtils.formatDateDisplay(flockData.collectionDate.split('T')[0])}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Age: ${flockData.flockAge} Weeks',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMonthlyYieldChart(
    List<String> availableMonths,
    String selectedMonth,
    List<dynamic> monthlyYield,
    int actualDaysInMonth,
    Function refreshCallback,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly Egg Yield Trend',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.purple.shade50,
                    labelText: 'Select Month',
                    labelStyle: const TextStyle(color: _primaryColor),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  value: selectedMonth,
                  items:
                      availableMonths.map((String month) {
                        return DropdownMenuItem<String>(
                          value: month,
                          child: Text(
                            StringUtils.formatMonthDisplay(month),
                            style: const TextStyle(color: Colors.black87),
                          ),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null && newValue != selectedMonth) {
                      refreshCallback(month: newValue);
                    }
                  },
                  isExpanded: true,
                  dropdownColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) {
                      return const FlLine(color: Colors.grey, strokeWidth: 0.5);
                    },
                    getDrawingVerticalLine: (value) {
                      return const FlLine(color: Colors.grey, strokeWidth: 0.5);
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          final day = value.toInt();
                          if (day < 1 || day > actualDaysInMonth) {
                            return const Text('');
                          }
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              '$day',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval:
                            (monthlyYield.isNotEmpty
                                    ? (monthlyYield
                                            .map(
                                              (e) => int.parse(
                                                e['total_eggs']?.toString() ??
                                                    '0',
                                              ),
                                            )
                                            .reduce((a, b) => a > b ? a : b)) /
                                        4
                                    : 10)
                                .ceilToDouble(),
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: const Color(0xff37434d),
                      width: 1,
                    ),
                  ),
                  minX: 1,
                  maxX: actualDaysInMonth.toDouble(),
                  minY: 0,
                  maxY:
                      monthlyYield.isNotEmpty
                          ? (monthlyYield
                                  .map(
                                    (e) => int.parse(
                                      e['total_eggs']?.toString() ?? '0',
                                    ),
                                  )
                                  .reduce((a, b) => a > b ? a : b)).toDouble() *
                              1.2
                          : 10,
                  lineBarsData: [
                    LineChartBarData(
                      spots:
                          monthlyYield.map((entry) {
                            final day = int.parse(
                              entry['collection_date']
                                  .split('-')[2]
                                  .split('T')[0],
                            );
                            final totalEggs =
                                double.tryParse(
                                  (entry['total_eggs'] ?? 0).toString(),
                                ) ??
                                0.0;
                            return FlSpot(day.toDouble(), totalEggs);
                          }).toList(),
                      isCurved: true,
                      color: _primaryColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter:
                            (spot, percent, bar, index) => FlDotCirclePainter(
                              radius: 3,
                              color: _primaryColor,
                              strokeWidth: 1,
                              strokeColor: Colors.white,
                            ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            _primaryColor.withOpacity(0.3),
                            _primaryColor.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChickenStatusChart(Map<String, dynamic> chickenStatus) {
    final current = chickenStatus['current']?.toDouble() ?? 0.0;
    final initial = chickenStatus['initial']?.toDouble() ?? 0.0;
    final lost = (initial - current).clamp(0.0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Text(
            'Chicken Population Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 250,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            color: Colors.green.shade600,
                            value: current,
                            title: '${current.toInt()} Current',
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            badgeWidget: Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 20,
                            ),
                            badgePositionPercentageOffset: 1.0,
                          ),
                          PieChartSectionData(
                            color: Colors.red.shade600,
                            value: lost,
                            title: '${lost.toInt()} Lost',
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            badgeWidget: Icon(
                              Icons.remove_circle,
                              color: Colors.white,
                              size: 20,
                            ),
                            badgePositionPercentageOffset: 1.0,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(
                        Colors.green.shade600,
                        'Current Chickens: ${current.toInt()}',
                      ),
                      const SizedBox(height: 8),
                      _buildLegendItem(
                        Colors.red.shade600,
                        'Lost Chickens: ${lost.toInt()}',
                      ),
                      const SizedBox(height: 8),
                      _buildLegendItem(
                        Colors.grey.shade400,
                        'Initial Chickens: ${initial.toInt()}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87)),
      ],
    );
  }
}
