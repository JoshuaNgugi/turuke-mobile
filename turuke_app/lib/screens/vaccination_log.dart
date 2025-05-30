import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/navigation_drawer.dart';
import 'package:uuid/uuid.dart';

class VaccinationLogScreen extends StatefulWidget {
  static const String routeName = '/vaccination-log';

  const VaccinationLogScreen({super.key});

  @override
  State<VaccinationLogScreen> createState() => _VaccinationLogScreenState();
}

class _VaccinationLogScreenState extends State<VaccinationLogScreen> {
  List<Map<String, dynamic>> _vaccinations = [];
  List<Map<String, dynamic>> _flocks = [];
  Database? _db;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchVaccinations();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final headers = await authProvider.getHeaders();
    final farmId = authProvider.user!['farm_id'];

    try {
      // Fetch flocks
      final flocksRes = await http.get(
        Uri.parse('${Constants.API_BASE_URL}/flocks?farm_id=$farmId'),
        headers: headers,
      );
      if (flocksRes.statusCode == 200) {
        _flocks = List<Map<String, dynamic>>.from(jsonDecode(flocksRes.body));
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
      builder:
          (context) => AlertDialog(
            title: Text('Add Vaccination'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<int>(
                      hint: Text('Select Flock'),
                      value: _flockId,
                      items:
                          _flocks
                              .map<DropdownMenuItem<int>>(
                                (f) => DropdownMenuItem<int>(
                                  value: f['id'] as int,
                                  child: Text(f['breed']),
                                ),
                              )
                              .toList(),
                      onChanged: (value) => _flockId = value,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Vaccine Name'),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                      onChanged: (value) => _vaccineName = value,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Vaccination Date',
                      ),
                      readOnly: true,
                      controller: TextEditingController(
                        text: _vaccinationDate.toIso8601String().substring(
                          0,
                          10,
                        ),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _vaccinationDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) _vaccinationDate = picked;
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
          ),
    );

    if (result != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final data = {'farm_id': authProvider.user!['farm_id'], ...result};
      try {
        final response = await http.post(
          Uri.parse('${Constants.API_BASE_URL}/vaccinations'),
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
        await _db!.insert('flock_pending', {'id': const Uuid().v4(), ...data});
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
          '${Constants.API_BASE_URL}/vaccinations?farm_id=${authProvider.user!['farm_id']}',
        ),
        headers: await authProvider.getHeaders(),
      );
      if (response.statusCode == 200) {
        setState(() {
          _vaccinations = List<Map<String, dynamic>>.from(
            jsonDecode(response.body),
          );
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
              : ListView.builder(
                padding: EdgeInsets.all(16.0),
                itemCount: _vaccinations.length,
                itemBuilder: (context, index) {
                  final vaccination = _vaccinations[index];
                  return ListTile(
                    leading: Icon(Icons.vaccines),
                    title: Text(vaccination['vaccine_name']),
                    subtitle: Text(
                      'Flock: ${vaccination['flock_id']} | Date: ${vaccination['vaccination_date']}',
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
