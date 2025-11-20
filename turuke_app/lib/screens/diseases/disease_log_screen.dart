import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/models/disease.dart';
import 'package:turuke_app/models/flock.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/diseases/add_edit_disease_screen.dart';
import 'package:turuke_app/screens/navigation/navigation_drawer_screen.dart';
import 'package:turuke_app/utils/http_client.dart';
import 'package:turuke_app/utils/string_utils.dart';
import 'package:turuke_app/utils/system_utils.dart';

var logger = Logger(printer: PrettyPrinter());

class DiseaseLogScreen extends StatefulWidget {
  static const String routeName = '/disease-log';

  const DiseaseLogScreen({super.key});

  @override
  State<DiseaseLogScreen> createState() => _DiseaseLogScreenState();
}

class _DiseaseLogScreenState extends State<DiseaseLogScreen> {
  List<Disease> _diseases = [];
  List<Flock> _flocks = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    await _fetchData(); // Fetch flocks and diseases
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
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
      return;
    }

    try {
      final flocksRes = await HttpClient.get(
        Uri.parse('${Constants.LAYERS_API_BASE_URL_V1}/flocks?farm_id=$farmId'),
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
        logger.w('Failed to fetch flocks (${flocksRes.statusCode}).');
        if (mounted) {
          SystemUtils.showSnackBar(context, 'Failed to load flocks.');
        }
      }

      final diseasesRes = await HttpClient.get(
        Uri.parse('${Constants.LAYERS_API_BASE_URL_V1}/diseases?farm_id=$farmId'),
        headers: headers,
      );
      if (mounted) {
        if (diseasesRes.statusCode == 200) {
          final List<dynamic> jsonList = jsonDecode(diseasesRes.body);
          _diseases = jsonList.map((json) => Disease.fromJson(json)).toList();

          setState(() {}); // Update UI
        } else {
          logger.w('Failed to fetch diseases (${diseasesRes.statusCode}).');
          if (mounted) {
            SystemUtils.showSnackBar(
              context,
              'Failed to load disease records.',
            );
          }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disease Log', style: TextStyle(color: Colors.white)),
        backgroundColor: Constants.kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: AppNavigationDrawer(
        selectedRoute: DiseaseLogScreen.routeName,
        onRouteSelected: _onRouteSelected,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData, // Pull to refresh
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
                          _diseases.isEmpty
                              ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'No disease records found. Tap the + button to add one.',
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
                                itemCount: _diseases.length,
                                itemBuilder: (context, index) {
                                  final disease = _diseases[index];
                                  final flockName =
                                      _flocks
                                          .firstWhere(
                                            (f) => f.id == disease.flockId,
                                            orElse:
                                                () => Flock(
                                                  id: disease.flockId,
                                                  name: 'Unknown Flock',
                                                  farmId: 0,
                                                  arrivalDate: '',
                                                  initialCount: 0,
                                                  currentCount: 0,
                                                  ageWeeks: 0,
                                                  status: 0,
                                                  currentAgeWeeks: 0,
                                                ),
                                          )
                                          .name;
                                  final diagnosisDateDisplay =
                                      StringUtils.formatDateDisplay(
                                        disease.diagnosisDate,
                                      );

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
                                          Icons.sick,
                                          color: Constants.kPrimaryColor,
                                        ),
                                      ),
                                      title: Text(
                                        disease.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Flock: $flockName'),
                                          Text(
                                            'Affected: ${disease.affectedSummary}',
                                          ),
                                          Text('Onset: $diagnosisDateDisplay'),
                                          if (disease.notes != null &&
                                              disease.notes!.isNotEmpty)
                                            Text('Notes: ${disease.notes}'),
                                        ],
                                      ),
                                      trailing: const Icon(
                                        Icons.edit,
                                        color: Colors.grey,
                                      ),
                                      onTap:
                                          () => _onRouteSelected(
                                            AddEditDiseaseScreen.routeName,
                                            {'disease': disease},
                                          ),
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
        onPressed:
            _flocks.isEmpty
                ? () => SystemUtils.showEmptyFlocksWarning(context)
                : () => _onRouteSelected(AddEditDiseaseScreen.routeName),
        backgroundColor: Constants.kPrimaryColor,
        foregroundColor: Colors.white,
        tooltip: 'Add Disease Record',
        child: const Icon(Icons.add),
      ),
    );
  }
}
