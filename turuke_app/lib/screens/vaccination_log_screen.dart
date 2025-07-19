import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/models/flock.dart';
import 'package:turuke_app/models/vaccination.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/navigation_drawer_screen.dart';
import 'package:turuke_app/utils/string_utils.dart';
import 'package:uuid/uuid.dart';

class VaccinationLogScreen extends StatefulWidget {
  static const String routeName = '/vaccination-log';

  const VaccinationLogScreen({super.key});

  @override
  State<VaccinationLogScreen> createState() => _VaccinationLogScreenState();
}

class _VaccinationLogScreenState extends State<VaccinationLogScreen> {
  List<Vaccination> _vaccinations = [];
  List<Flock> _flocks = [];
  Database? _db;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initDb();
    _fetchData();
    _fetchVaccinations();
  }

  Future<void> _initDb() async {
    _db = await openDatabase(
      path.join(await getDatabasesPath(), 'turuke.db'),
      onCreate:
          (db, version) => db.execute(
            'CREATE TABLE vaccination_pending(id TEXT PRIMARY KEY, flock_id INTEGER, vaccination_date TEXT, notes TEXT)',
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

  Future<void> _showAddVaccinationDialog() async {
    final _formKey = GlobalKey<FormState>();
    int? _flockId;
    String _vaccineName = '';
    DateTime _vaccinationDate = DateTime.now();
    String _notes = '';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        final vaccinationDateController = TextEditingController(
          text: _vaccinationDate.toIso8601String().substring(0, 10),
        );
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Vaccination'),
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
                        onChanged: (value) => _flockId = value,
                        validator: (value) => value == null ? 'Required' : null,
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Vaccine Name'),
                        validator:
                            (value) => value!.isEmpty ? 'Required' : null,
                        onChanged: (value) => _vaccineName = value,
                      ),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Vaccination Date',
                        ),
                        readOnly: true,
                        controller: vaccinationDateController,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _vaccinationDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              _vaccinationDate = picked;
                              vaccinationDateController.text = _vaccinationDate
                                  .toIso8601String()
                                  .substring(0, 10);
                            });
                          }
                        },
                      ),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Notes (Optional)',
                        ),
                        onChanged: (value) => _notes = value,
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
                        // flock_id, vaccine_name, vaccination_date, notes
                        'flock_id': _flockId,
                        'vaccine_name': _vaccineName,
                        'vaccination_date': _vaccinationDate
                            .toIso8601String()
                            .substring(0, 10),
                        'notes': _notes,
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
          Uri.parse('${Constants.LAYERS_API_BASE_URL}/vaccinations'),
          headers: await authProvider.getHeaders(),
          body: jsonEncode(data),
        );
        if (response.statusCode == 201) {
          _fetchVaccinations();
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
        await _db!.insert('vaccination_pending', {
          'id': const Uuid().v4(),
          ...data,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved offline, will sync later')),
        );
        _fetchVaccinations();
      }
    }
  }

  Future<void> _fetchVaccinations() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await http.get(
        Uri.parse(
          '${Constants.LAYERS_API_BASE_URL}/vaccinations?farm_id=${authProvider.user!.farmId}',
        ),
        headers: await authProvider.getHeaders(),
      );
      if (response.statusCode == 200) {
        setState(() {
          final List<dynamic> jsonList = jsonDecode(response.body);
          _vaccinations =
              jsonList.map((json) => Vaccination.fromJson(json)).toList();

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
      appBar: AppBar(title: Text('Vaccination Log')),
      drawer: AppNavigationDrawer(
        selectedRoute: VaccinationLogScreen.routeName,
        onRouteSelected: _onRouteSelected,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _vaccinations.isEmpty
              ? const Center(child: Text('No vaccination records found'))
              : ListView.builder(
                padding: EdgeInsets.all(16.0),
                itemCount: _vaccinations.length,
                itemBuilder: (context, index) {
                  final vaccination = _vaccinations[index];
                  final vaccinationDate = StringUtils.formatDateDisplay(
                    vaccination.vaccinationDate,
                  );
                  return ListTile(
                    leading: Icon(Icons.vaccines),
                    title: Text(vaccination.name),
                    subtitle: Text(
                      'Flock: ${vaccination.flockName} | Date: $vaccinationDate',
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVaccinationDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
