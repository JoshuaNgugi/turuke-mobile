import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/navigation_drawer.dart';
import 'package:uuid/uuid.dart';

class FlockManagementScreen extends StatefulWidget {
  static const String routeName = '/flock-management';

  const FlockManagementScreen({super.key});

  @override
  State<FlockManagementScreen> createState() => _FlockManagementScreenState();
}

class _FlockManagementScreenState extends State<FlockManagementScreen> {
  List<Map<String, dynamic>> _flocks = [];
  Database? _db;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initDb();
    _fetchFlocks();
  }

  Future<void> _initDb() async {
    _db = await openDatabase(
      path.join(await getDatabasesPath(), 'turuke.db'),
      onCreate:
          (db, version) => db.execute(
            'CREATE TABLE flock_pending(id TEXT PRIMARY KEY, farm_id INTEGER, breed TEXT, arrival_date TEXT, initial_count INTEGER, age_weeks INTEGER, status TEXT)',
          ),
      version: 1,
    );
  }

  Future<void> _fetchFlocks() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await http.get(
        Uri.parse(
          '${Constants.API_BASE_URL}/flocks?farm_id=${authProvider.user!['farm_id']}',
        ),
        headers: await authProvider.getHeaders(),
      );
      if (response.statusCode == 200) {
        setState(() {
          _flocks = List<Map<String, dynamic>>.from(jsonDecode(response.body));
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

  Future<void> _showAddFlockDialog() async {
    final formKey = GlobalKey<FormState>();
    String breed = '';
    DateTime arrivalDate = DateTime.now();
    int initialCount = 0, ageWeeks = 0;
    int status = 1;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Flock'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Breed'),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                      onChanged: (value) => breed = value,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Arrival Date',
                      ),
                      readOnly: true,
                      controller: TextEditingController(
                        text: arrivalDate.toIso8601String().substring(0, 10),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: arrivalDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          arrivalDate = picked;
                          (context as Element).markNeedsBuild();
                        }
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Initial Count',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                      onChanged:
                          (value) => initialCount = int.tryParse(value) ?? 0,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Age (Weeks)',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                      onChanged: (value) => ageWeeks = int.tryParse(value) ?? 0,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context, {
                      'breed': breed,
                      'arrival_date': arrivalDate.toIso8601String().substring(
                        0,
                        10,
                      ),
                      'initial_count': initialCount,
                      'age_weeks': ageWeeks,
                      'status': status,
                    });
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (result != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final data = {'farm_id': authProvider.user!['farm_id'], ...result};
      try {
        final response = await http.post(
          Uri.parse('${Constants.API_BASE_URL}/flocks'),
          headers: await authProvider.getHeaders(),
          body: jsonEncode(data),
        );
        if (response.statusCode == 201) {
          _fetchFlocks();
        } else {
          throw Exception('Failed to save');
        }
      } catch (e) {
        await _db!.insert('flock_pending', {'id': const Uuid().v4(), ...data});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved offline, will sync later')),
        );
        _fetchFlocks();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Flock Management')),
      drawer: AppNavigationDrawer(
        selectedRoute: FlockManagementScreen.routeName,
        onRouteSelected: _onRouteSelected,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                padding: EdgeInsets.all(16.0),
                itemCount: _flocks.length,
                itemBuilder: (context, index) {
                  final flock = _flocks[index];
                  return ListTile(
                    leading: Icon(Icons.pets),
                    title: Text(flock['breed']),
                    subtitle: Text(
                      'Count: ${flock['current_count']}, Age: ${flock['age_weeks']} weeks',
                    ),
                    onTap: () {
                      // TODO: Navigate to flock details or edit
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit coming soon')),
                      );
                    },
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFlockDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
