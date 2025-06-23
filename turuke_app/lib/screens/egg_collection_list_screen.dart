import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/datasources/egg_collection_datasource.dart';
import 'package:turuke_app/models/flock.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/egg_collection.dart';
import 'package:turuke_app/screens/navigation_drawer.dart';
import 'package:turuke_app/utils/string_utils.dart';
import 'package:turuke_app/utils/system_utils.dart';

var logger = Logger(printer: PrettyPrinter());

class EggCollectionListScreen extends StatefulWidget {
  static const String routeName = '/egg-collection-list';
  const EggCollectionListScreen({super.key});

  @override
  State<EggCollectionListScreen> createState() =>
      _EggCollectionListScreenState();
}

class _EggCollectionListScreenState extends State<EggCollectionListScreen> {
  List<Map<String, dynamic>> _eggCollections = [];
  bool _isLoading = true;
  final int _rowsPerPage = 10;

  List<Flock> _flocksForDropdown = [];
  int? _selectedFlockId; // null means 'All Flocks'
  String _selectedMonth = DateTime.now().toIso8601String().substring(0, 7);
  List<String> _availableMonths = SystemUtils.generateAvailableMonths();

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
      // Fetch flocks
      await _fetchFlocksAndPrepareDropdown(farmId!, headers);

      // Fetch egg collections
      String eggProductionUrl =
          '${Constants.API_BASE_URL}/egg-production?farm_id=$farmId';
      if (_selectedFlockId != null) {
        eggProductionUrl += '&flock_id=$_selectedFlockId';
      }
      if (_selectedMonth.isNotEmpty) {
        eggProductionUrl += '&month=$_selectedMonth';
      }

      final eggRes = await http.get(
        Uri.parse(eggProductionUrl),
        headers: headers,
      );

      if (eggRes.statusCode == 200) {
        _eggCollections = List<Map<String, dynamic>>.from(
          jsonDecode(eggRes.body),
        );
      } else {
        // Offline: Fetch from sqflite
        logger.e(
          'API fetch failed (${eggRes.statusCode}). Falling back to offline data.',
        );
        await _loadOfflineEggCollections();
      }
    } catch (e) {
      // Offline fallback
      logger.e('Error fetching data: $e. Falling back to offline data.');
      await _loadOfflineEggCollections();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchFlocksAndPrepareDropdown(
    int farmId,
    Map<String, String> headers,
  ) async {
    Flock allFlocks = Flock(
      farmId: 0,
      name: 'All Flocks',
      arrivalDate: DateTime.now().toIso8601String(),
      initialCount: 0,
      currentCount: 0,
      ageWeeks: 0,
      status: 0,
      currentAgeWeeks: 0,
    );
    try {
      final flocksRes = await http.get(
        Uri.parse('${Constants.API_BASE_URL}/flocks?farm_id=$farmId'),
        headers: headers,
      );
      List<Flock> flocks = [];
      if (flocksRes.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(flocksRes.body);
        flocks = jsonList.map((json) => Flock.fromJson(json)).toList();

        if (mounted) {
          // Add "All Flocks" option
          _flocksForDropdown = [allFlocks];
          _flocksForDropdown.addAll(flocks.map((flock) => flock));

          // If _selectedFlockId is not yet set (initial load), default to "All Flocks"
          _selectedFlockId ??= null;
        }
      } else {
        logger.e(
          'Failed to fetch flocks (${flocksRes.statusCode}): ${flocksRes.body}',
        );
        // If flocks cannot be fetched, dropdown will only have "All Flocks"
        if (mounted) {
          _flocksForDropdown = [allFlocks];
          _selectedFlockId = null;
        }
      }
    } catch (e) {
      logger.e('Error fetching flocks: $e');
      if (mounted) {
        _flocksForDropdown = [allFlocks];
        _selectedFlockId = null;
      }
    }
  }

  Future<void> _loadOfflineEggCollections() async {
    try {
      final databasePath = await getDatabasesPath();
      final db = await openDatabase(path.join(databasePath, 'turuke.db'));
      final synced = await db.query('egg_production');
      final pending = await db.query('egg_pending');

      List<Map<String, dynamic>> offlineCollections = [...synced, ...pending];

      // Apply in-memory filtering if offline and filters are set
      if (_selectedFlockId != null) {
        offlineCollections =
            offlineCollections
                .where((item) => item['flock_id'] == _selectedFlockId)
                .toList();
      }
      if (_selectedMonth.isNotEmpty) {
        offlineCollections =
            offlineCollections.where((item) {
              final collectionDate = item['collection_date']?.toString();
              return collectionDate != null &&
                  collectionDate.startsWith(_selectedMonth);
            }).toList();
      }

      if (mounted) {
        _eggCollections = offlineCollections;
      }
    } catch (e) {
      logger.e('Error loading offline egg collections: $e');
      if (mounted) {
        _eggCollections = []; // Clear data if offline load fails
      }
    }
  }

  void _onRouteSelected(String route, [Map<String, dynamic>? args]) {
    Navigator.pushNamed(context, route, arguments: args); // Support arguments
  }

  @override
  Widget build(BuildContext context) {
    final dataSource = EggCollectionDataSource(
      eggCollections: _eggCollections,
      onSelect:
          (entry) => _onRouteSelected(
            EggCollectionScreen.routeName,
            {'collection': entry}, // Pass selected collection
          ),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Egg Collections')),
      drawer: AppNavigationDrawer(
        selectedRoute: EggCollectionListScreen.routeName,
        onRouteSelected: _onRouteSelected,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _eggCollections.isEmpty && !_isLoading
              ? const Center(child: Text('No egg collections found'))
              : SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Select Flock',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              value: _selectedFlockId,
                              items:
                                  _flocksForDropdown.map((flock) {
                                    return DropdownMenuItem<int?>(
                                      value: flock.id,
                                      child: Text(flock.name),
                                    );
                                  }).toList(),
                              onChanged: (int? newValue) {
                                if (newValue != _selectedFlockId) {
                                  setState(() {
                                    _selectedFlockId = newValue;
                                  });
                                  _fetchData(); // Re-fetch data with new flock filter
                                }
                              },
                              isExpanded: true,
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
                                  _fetchData(); // Re-fetch data with new month filter
                                }
                              },
                              isExpanded: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width,
                      ),
                      child: PaginatedDataTable(
                        showCheckboxColumn: false,
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Flock',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Date',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Whole Eggs',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Broken Eggs',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Total',
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
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            _flocksForDropdown.isEmpty
                ? null // Disable if no flocks are loaded (even "All")
                : () => _onRouteSelected(EggCollectionScreen.routeName),
        tooltip: 'Add Egg Collection',
        child: const Icon(Icons.add),
      ),
    );
  }
}
