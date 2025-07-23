import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/datasources/mortality_datasource.dart';
import 'package:turuke_app/models/flock.dart';
import 'package:turuke_app/models/mortality.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/add_edit_mortality_screen.dart';
import 'package:turuke_app/screens/navigation_drawer_screen.dart';
import 'package:turuke_app/utils/system_utils.dart';

var logger = Logger(printer: PrettyPrinter());

class MortalityListScreen extends StatefulWidget {
  static const String routeName = '/mortality-list';
  const MortalityListScreen({super.key});

  @override
  State<MortalityListScreen> createState() => _MortalityListScreenState();
}

class _MortalityListScreenState extends State<MortalityListScreen> {
  bool _isLoading = true;
  final int _rowsPerPage = 10;

  List<Mortality> _mortalityList = [];
  List<Flock> _flocks = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final headers = await authProvider.getHeaders();
    final farmId = authProvider.user?.farmId;
    if (farmId == null) {
      logger.e('Farm ID is null. Cannot fetch data.');
      if (mounted) {
        SystemUtils.showSnackBar(
          context,
          'Error: Farm ID not found. Please re-login.',
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      final flocksRes = await http.get(
        Uri.parse('${Constants.LAYERS_API_BASE_URL}/flocks?farm_id=$farmId'),
        headers: headers,
      );
      if (flocksRes.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(flocksRes.body);
        if (mounted) {
          setState(() {
            _flocks = jsonList.map((json) => Flock.fromJson(json)).toList();
          });
        }
      } else {
        logger.w(
          'Failed to fetch flocks (${flocksRes.statusCode}): ${flocksRes.body}',
        );
        if (mounted) {
          SystemUtils.showSnackBar(context, 'Failed to load flocks.');
        }
      }

      String mortalityUrl =
          '${Constants.LAYERS_API_BASE_URL}/mortality?farm_id=$farmId';

      final mortalityRes = await http.get(
        Uri.parse(mortalityUrl),
        headers: headers,
      );

      if (mortalityRes.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(mortalityRes.body);
        _mortalityList =
            jsonList.map((json) => Mortality.fromJson(json)).toList();

        if (mounted) {
          setState(() {});
        }
      } else {
        logger.e(
          'API fetch failed (${mortalityRes.statusCode}): ${mortalityRes.body}',
        );
        if (mounted) {
          SystemUtils.showSnackBar(
            context,
            'Failed to load mortality records.',
          );
        }
      }
    } catch (e) {
      logger.e('Error fetching data: $e');
      if (mounted) {
        SystemUtils.showSnackBar(
          context,
          'Network error. Could not fetch data.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onRouteSelected(String route, [Map<String, dynamic>? args]) {
    Navigator.pushNamed(context, route, arguments: args).then((_) {
      _fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataSource = MortalityDataSource(
      mortality: _mortalityList,
      onSelect:
          (entry) => _onRouteSelected(AddEditMortalityScreen.routeName, {
            'mortality': entry,
          }),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mortality Records',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Constants.kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: AppNavigationDrawer(
        selectedRoute: MortalityListScreen.routeName,
        onRouteSelected: _onRouteSelected,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: Constants.kPrimaryColor,
        child:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Constants.kPrimaryColor,
                    ),
                  ),
                )
                : _mortalityList.isEmpty
                ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No mortality records found. Tap the + button to add one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ),
                )
                : SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width,
                    ),
                    child: PaginatedDataTable(
                      showCheckboxColumn: false,
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Recorded Date',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Flock',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Count',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          numeric: true,
                        ),
                      ],
                      source: dataSource,
                      rowsPerPage: _rowsPerPage,
                      columnSpacing: 16,
                      horizontalMargin: 16,
                    ),
                  ),
                ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onRouteSelected(AddEditMortalityScreen.routeName),
        tooltip: 'Record Mortality',
        backgroundColor: Constants.kPrimaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
