import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/datasources/egg_collection_datasource.dart';
import 'package:turuke_app/models/egg_data.dart';
import 'package:turuke_app/models/flock.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/egg_collection_screen.dart';
import 'package:turuke_app/screens/navigation_drawer_screen.dart';
import 'package:turuke_app/utils/http_client.dart';
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
  bool _isLoading = true;
  bool _isOfflineMode = false;
  final int _rowsPerPage = 10;

  List<EggData> _eggCollections = [];
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
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _isOfflineMode = false;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final headers = await authProvider.getHeaders();
    final farmId = authProvider.user?.farmId;

    if (farmId == null) {
      logger.e('Farm ID is null. Cannot fetch data.');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _eggCollections = [];
          _flocksForDropdown = [_createAllFlocksOption()];
        });
      }
      SystemUtils.showSnackBar(
        context,
        'Error: Farm ID not found. Please re-login.',
      );
      return;
    }

    try {
      await _fetchFlocksAndPrepareDropdown(farmId, headers);

      String eggProductionUrl =
          '${Constants.LAYERS_API_BASE_URL}/egg-production?farm_id=$farmId';
      if (_selectedFlockId != null) {
        eggProductionUrl += '&flock_id=$_selectedFlockId';
      }
      if (_selectedMonth.isNotEmpty) {
        eggProductionUrl += '&month=$_selectedMonth';
      }

      final eggRes = await HttpClient.get(
        Uri.parse(eggProductionUrl),
        headers: headers,
      );

      if (eggRes.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(eggRes.body);
        if (mounted) {
          setState(() {
            _eggCollections =
                jsonList.map((json) => EggData.fromJson(json)).toList();
          });
        }
      } else {
        logger.w(
          'API fetch failed (${eggRes.statusCode}). Status: ${eggRes.reasonPhrase}. Falling back to offline data.',
        );
        if (mounted) {
          setState(() {
            _isOfflineMode = true;
          });
        }
        await _loadOfflineEggCollections();
      }
    } catch (e) {
      logger.e('Error fetching data: $e. Falling back to offline data.');
      if (mounted) {
        setState(() {
          _isOfflineMode = true;
        });
      }
      await _loadOfflineEggCollections();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Flock _createAllFlocksOption() {
    return Flock(
      id: null,
      farmId: 0,
      name: 'All Flocks',
      arrivalDate: DateTime.now().toIso8601String(),
      initialCount: 0,
      currentCount: 0,
      ageWeeks: 0,
      status: 0,
      currentAgeWeeks: 0,
    );
  }

  Future<void> _fetchFlocksAndPrepareDropdown(
    int farmId,
    Map<String, String> headers,
  ) async {
    Flock allFlocks = _createAllFlocksOption();

    try {
      final flocksRes = await HttpClient.get(
        Uri.parse('${Constants.LAYERS_API_BASE_URL}/flocks?farm_id=$farmId'),
        headers: headers,
      );
      List<Flock> flocks = [];
      if (flocksRes.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(flocksRes.body);
        flocks = jsonList.map((json) => Flock.fromJson(json)).toList();
      } else {
        logger.w(
          'Failed to fetch flocks (${flocksRes.statusCode}): ${flocksRes.body}',
        );
      }

      if (mounted) {
        setState(() {
          _flocksForDropdown = [allFlocks];
          _flocksForDropdown.addAll(flocks);

          if (_selectedFlockId != null &&
              !_flocksForDropdown.any(
                (f) => f.id == _selectedFlockId && f.id != null,
              )) {
            _selectedFlockId = null;
          } else {
            _selectedFlockId ??= null;
          }
        });
      }
    } catch (e) {
      logger.e('Error fetching flocks: $e');
      if (mounted) {
        setState(() {
          _flocksForDropdown = [allFlocks];
          _selectedFlockId = null;
        });
      }
      SystemUtils.showSnackBar(
        context,
        'Could not load flocks. Showing all flocks by default.',
      );
    }
  }

  Future<void> _loadOfflineEggCollections() async {
    try {
      final databasePath = await getDatabasesPath();
      final db = await openDatabase(path.join(databasePath, 'turuke.db'));
      final List<Map<String, Object?>> synced = await db.query(
        'egg_production',
      );
      final List<Map<String, Object?>> pending = await db.query('egg_pending');

      List<EggData> syncedEggData =
          synced.map((map) => EggData.fromJson(map)).toList();
      List<EggData> pendingEggData =
          pending.map((map) => EggData.fromJson(map)).toList();

      List<EggData> offlineCollections = [...syncedEggData, ...pendingEggData];

      if (_selectedFlockId != null) {
        offlineCollections =
            offlineCollections
                .where((eggData) => eggData.flockId == _selectedFlockId)
                .toList();
      }
      if (_selectedMonth.isNotEmpty) {
        offlineCollections =
            offlineCollections.where((eggData) {
              final collectionDate = eggData.collectionDate;
              return collectionDate.startsWith(_selectedMonth);
            }).toList();
      }

      if (mounted) {
        setState(() {
          _eggCollections = offlineCollections;
          _isOfflineMode = true;
        });
      }
    } catch (e) {
      logger.e('Error loading offline egg collections: $e');
      if (mounted) {
        _eggCollections = [];
        _isOfflineMode = true;
        SystemUtils.showSnackBar(
          context,
          'Failed to load offline data. Please check connection.',
        );
      }
    }
  }

  void _onRouteSelected(String route, [Object? args]) async {
    if (ModalRoute.of(context)?.settings.name != route) {
      final result = await Navigator.pushNamed(context, route, arguments: args);
      if (result == true) {
        _fetchData();
      }
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pass EggData directly as argument to _onRouteSelected
    final dataSource = EggCollectionDataSource(
      eggCollections: _eggCollections,
      onSelect:
          (entry) => _onRouteSelected(EggCollectionScreen.routeName, entry),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Egg Collections',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Constants.kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: AppNavigationDrawer(
        selectedRoute: EggCollectionListScreen.routeName,
        onRouteSelected: _onRouteSelected,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: Constants.kPrimaryColor,
        child:
            _isLoading
                ? _buildLoadingState()
                : Column(
                  children: [
                    _buildFilterOptions(),
                    if (_isOfflineMode) _buildOfflineModeBanner(),
                    Expanded(
                      child:
                          _eggCollections.isEmpty
                              ? _buildNoDataState()
                              : _buildDataTable(dataSource),
                    ),
                  ],
                ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            _flocksForDropdown.isEmpty
                ? null
                : () => _onRouteSelected(
                  EggCollectionScreen.routeName,
                ), // No argument for new entry
        tooltip: 'Add Egg Collection',
        backgroundColor: Constants.kPrimaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Constants.kPrimaryColor),
      ),
    );
  }

  Widget _buildNoDataState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'No egg collections found for the selected filters. Add a new entry.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ),
    );
  }

  Widget _buildOfflineModeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      color: Colors.orange.shade100,
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing offline data. Connect to update.',
              style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(EggCollectionDataSource dataSource) {
    return SingleChildScrollView(
      child: ConstrainedBox(
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
          columnSpacing: 24,
          horizontalMargin: 16,
        ),
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int?>(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Select Flock',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Constants.kPrimaryColor,
                    width: 2.0,
                  ),
                ),
                labelStyle: TextStyle(color: Constants.kPrimaryColor),
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
                  _fetchData();
                }
              },
              isExpanded: true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Select Month',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Constants.kPrimaryColor,
                    width: 2.0,
                  ),
                ),
                labelStyle: TextStyle(color: Constants.kPrimaryColor),
              ),
              value: _selectedMonth,
              items:
                  _availableMonths.map((String month) {
                    return DropdownMenuItem<String>(
                      value: month,
                      child: Text(StringUtils.formatMonthDisplay(month)),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null && newValue != _selectedMonth) {
                  setState(() {
                    _selectedMonth = newValue;
                  });
                  _fetchData();
                }
              },
              isExpanded: true,
            ),
          ),
        ],
      ),
    );
  }
}
