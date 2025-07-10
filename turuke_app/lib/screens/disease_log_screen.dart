import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/models/disease.dart';
import 'package:turuke_app/models/flock.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/navigation_drawer_screen.dart';
import 'package:turuke_app/utils/string_utils.dart';
import 'package:uuid/uuid.dart';

class DiseaseLogScreen extends StatefulWidget {
  static const String routeName = '/disease-log';
  const DiseaseLogScreen({super.key});

  @override
  State<DiseaseLogScreen> createState() => _DiseaseLogScreenState();
}

class _DiseaseLogScreenState extends State<DiseaseLogScreen> {
  List<Disease> _diseases = [];
  List<Flock> _flocks = [];
  Database? _db;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initDb();
    _fetchData();
    _fetchDiseases();
  }

  Future<void> _initDb() async {
    _db = await openDatabase(
      path.join(await getDatabasesPath(), 'turuke.db'),
      onCreate:
          (db, version) => db.execute(
            'CREATE TABLE disease_pending(id TEXT PRIMARY KEY, flock_id INTEGER, diagnosis_date TEXT, affected_count INTEGER, notes TEXT)',
          ),
      version: 1,
    );
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final headers = await authProvider.getHeaders();
    final farmId = authProvider.user!.farmId;

    try {
      // Fetch flocks
      final flocksRes = await http.get(
        Uri.parse('${Constants.LAYERS_API_BASE_URL}/flocks?farm_id=$farmId'),
        headers: headers,
      );
      if (flocksRes.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(flocksRes.body);
        _flocks = jsonList.map((json) => Flock.fromJson(json)).toList();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addDisease({
    required int flockId,
    required String diseaseName,
    required DateTime diagnosisDate,
    required int affectedCount,
    String? notes,
  }) async {
    final data = {
      'flock_id': flockId,
      'disease_name': diseaseName,
      'diagnosis_date': diagnosisDate.toIso8601String().substring(0, 10),
      'affected_count': affectedCount,
      if (notes != null) 'notes': notes,
    };
    try {} catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved offline, will sync later')));
    }
  }

  Future<void> _showAddDiseaseDialog() async {
    final _formKey = GlobalKey<FormState>();
    int? _flockId;
    String _diseaseName = '';
    DateTime _diagnosisDate = DateTime.now();
    int _affectedCount = 0;
    String _notes = '';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        final diagnosisDateController = TextEditingController(
          text: _diagnosisDate.toIso8601String().substring(0, 10),
        );

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Disease'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        hint: Text('Select Flock'),
                        value: _flockId,
                        items:
                            _flocks
                                .map<DropdownMenuItem<int>>(
                                  (flock) => DropdownMenuItem<int>(
                                    value: flock.id,
                                    child: Text(flock.name),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) => setState(() => _flockId = value),
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Disease Name'),
                        validator:
                            (value) => value!.isEmpty ? 'Required' : null,
                        onChanged: (value) => _diseaseName = value,
                      ),
                      TextFormField(
                        controller: diagnosisDateController,
                        decoration: InputDecoration(
                          labelText: 'Diagnosis Date',
                        ),
                        readOnly: true,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _diagnosisDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              _diagnosisDate = picked;
                              diagnosisDateController.text = _diagnosisDate
                                  .toIso8601String()
                                  .substring(0, 10);
                            });
                          }
                        },
                      ),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Affected Count',
                        ),
                        keyboardType: TextInputType.number,
                        validator:
                            (value) => value!.isEmpty ? 'Required' : null,
                        onChanged:
                            (value) =>
                                _affectedCount = int.tryParse(value) ?? 0,
                      ),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Notes (Optional)',
                          hintText: 'Enter any notes that will be helpful',
                        ),
                        onChanged: (value) => _notes = value,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate() && _flockId != null) {
                      Navigator.pop(context, {
                        'flock_id': _flockId!,
                        'disease_name': _diseaseName.trim(),
                        'diagnosis_date': _diagnosisDate
                            .toIso8601String()
                            .substring(0, 10),
                        'affected_count': _affectedCount,
                        'notes': _notes.isEmpty ? null : _notes,
                      });
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final data = {'farm_id': authProvider.user!.farmId, ...result};
      try {
        final response = await http.post(
          Uri.parse('${Constants.LAYERS_API_BASE_URL}/diseases'),
          headers: await authProvider.getHeaders(),
          body: jsonEncode(data),
        );
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Saved successfully')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Save failed. Try again later')),
          );
          throw Exception('Failed to save');
        }
      } catch (e) {
        await _db!.insert('disease_pending', {
          'id': const Uuid().v4(),
          ...data,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved offline, will sync later')),
        );
      } finally {
        _fetchDiseases();
      }
    }
  }

  Future<void> _fetchDiseases() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await http.get(
        Uri.parse(
          '${Constants.LAYERS_API_BASE_URL}/diseases?farm_id=${authProvider.user!.farmId}',
        ),
        headers: await authProvider.getHeaders(),
      );
      if (response.statusCode == 200) {
        setState(() {
          final List<dynamic> jsonList = jsonDecode(response.body);
          _diseases = jsonList.map((json) => Disease.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onRouteSelected(String route) {
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Disease Log')),
      drawer: AppNavigationDrawer(
        selectedRoute: DiseaseLogScreen.routeName,
        onRouteSelected: _onRouteSelected,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _diseases.isEmpty
              ? const Center(child: Text('No disease records found'))
              : ListView.builder(
                padding: EdgeInsets.all(16.0),
                itemCount: _diseases.length,
                itemBuilder: (context, index) {
                  final disease = _diseases[index];
                  final diagnosisDate = StringUtils.formatDate(
                    disease.diagnosisDate,
                  );
                  return ListTile(
                    leading: Icon(Icons.sick),
                    title: Text(disease.name),
                    subtitle: Text(
                      'Flock: ${disease.flockName} | Affected: ${disease.affectedCount} | Onset : $diagnosisDate',
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDiseaseDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
