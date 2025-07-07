import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/datasources/mortality_datasource.dart';
import 'package:turuke_app/models/mortality.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/egg_collection_screen.dart';
import 'package:turuke_app/screens/home_screen.dart';
import 'package:turuke_app/screens/navigation_drawer_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final headers = await authProvider.getHeaders();
    final farmId = authProvider.user!.farmId;

    try {
      // Fetch egg collections
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
      } else {
        logger.e('API fetch failed (${mortalityRes.statusCode}).');
      }
    } catch (e) {
      logger.e('Error fetching data: $e.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onRouteSelected(String route, [Map<String, dynamic>? args]) {
    Navigator.pushNamed(context, route, arguments: args); // Support arguments
  }

  @override
  Widget build(BuildContext context) {
    final dataSource = MortalityDataSource(
      mortality: _mortalityList,
      onSelect:
          (entry) => _onRouteSelected(
            HomeScreen.routeName,
            {'collection': entry}, // Pass selected collection
          ),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Mortality')),
      drawer: AppNavigationDrawer(
        selectedRoute: MortalityListScreen.routeName,
        onRouteSelected: _onRouteSelected,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _mortalityList.isEmpty
              ? const Center(child: Text('No mortality recorded.'))
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
                          'Date',
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
                      ),
                    ],
                    source: dataSource,
                    rowsPerPage: _rowsPerPage,
                    columnSpacing: 16,
                    horizontalMargin: 16,
                  ),
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onRouteSelected(EggCollectionScreen.routeName),
        tooltip: 'Record Mortality',
        child: const Icon(Icons.add),
      ),
    );
  }
}
