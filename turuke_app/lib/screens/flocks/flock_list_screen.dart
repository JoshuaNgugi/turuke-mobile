import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/models/flock.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/flocks/flock_management_screen.dart';
import 'package:turuke_app/screens/navigation/navigation_drawer_screen.dart';
import 'package:turuke_app/utils/http_client.dart';
import 'package:turuke_app/utils/string_utils.dart';
import 'package:turuke_app/utils/system_utils.dart';

var logger = Logger(printer: PrettyPrinter());

class FlockListScreen extends StatefulWidget {
  static const String routeName = '/flock-list';

  const FlockListScreen({super.key});

  @override
  State<FlockListScreen> createState() => _FlockListScreenState();
}

class _FlockListScreenState extends State<FlockListScreen> {
  List<Flock> _flocks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
    });
    await _fetchFlocks();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchFlocks() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final farmId = authProvider.user?.farmId;

    if (farmId == null) {
      logger.e('Farm ID is null. Cannot fetch flocks.');
      if (mounted) {
        SystemUtils.showSnackBar(
          context,
          'Farm ID not available. Cannot load flocks.',
        );
      }
      return;
    }

    try {
      final response = await HttpClient.get(
        Uri.parse('${Constants.LAYERS_API_BASE_URL}/flocks?farm_id=$farmId'),
        headers: await authProvider.getHeaders(),
      );
      if (mounted) {
        if (response.statusCode == 200) {
          final List<dynamic> jsonList = jsonDecode(response.body);
          List<Flock> fetchedFlocks =
              jsonList.map((json) => Flock.fromJson(json)).toList();

          setState(() {
            _flocks = fetchedFlocks;
          });
        } else {
          logger.w('Failed to fetch flocks (${response.statusCode}).');
        }
      }
    } catch (e) {
      logger.e('Error fetching flocks: $e.');
      if (mounted) {
        SystemUtils.showSnackBar(context, 'Failed to fetch flocks.');
      }
    }
  }

  void _onRouteSelected(String route, [Map<String, dynamic>? args]) {
    Navigator.pushNamed(context, route, arguments: args).then((_) {
      _fetchFlocks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.user?.role;
    final canModifyFlock =
        userRole == UserRole.ADMIN || userRole == UserRole.MANAGER;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Flock Management',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Constants.kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: AppNavigationDrawer(
        selectedRoute: FlockListScreen.routeName,
        onRouteSelected: _onRouteSelected,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchFlocks,
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
                : Column(
                  children: [
                    Expanded(
                      child:
                          _flocks.isEmpty
                              ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'No flocks found. Tap the + button to add one.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              )
                              : ListView.builder(
                                padding: const EdgeInsets.all(8.0),
                                itemCount: _flocks.length,
                                itemBuilder: (context, index) {
                                  Flock flock = _flocks[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                      horizontal: 4.0,
                                    ),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Constants.kAccentColor,
                                        child: Icon(
                                          Icons.pets,
                                          color: Constants.kPrimaryColor,
                                        ),
                                      ),
                                      title: Text(
                                        flock.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Arrival: ${StringUtils.formatDateDisplay(flock.arrivalDate)}',
                                          ),
                                          Text(
                                            'Initial: ${flock.initialCount}, Current: ${flock.currentCount}',
                                          ),
                                          Text('Age: ${flock.ageWeeks} weeks'),
                                          Text(
                                            'Status: ${flock.status == 1 ? 'Active' : 'Inactive'}',
                                            style: TextStyle(
                                              color:
                                                  flock.status == 1
                                                      ? Colors.green
                                                      : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      onTap:
                                          canModifyFlock
                                              ? () => _onRouteSelected(
                                                FlockManagementScreen.routeName,
                                                {'flock': flock},
                                              )
                                              : null,
                                    ),
                                  );
                                },
                              ),
                    ),
                    const Padding(padding: EdgeInsets.only(bottom: 100)),
                  ],
                ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onRouteSelected(FlockManagementScreen.routeName),
        backgroundColor: Constants.kPrimaryColor,
        foregroundColor: Colors.white,
        tooltip: 'Add New Flock',
        child: const Icon(Icons.add),
      ),
    );
  }
}
