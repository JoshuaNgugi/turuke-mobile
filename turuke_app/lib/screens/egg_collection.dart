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

class EggCollectionScreen extends StatefulWidget {
  static const String routeName = '/egg-collection';
  const EggCollectionScreen({super.key});

  @override
  State<EggCollectionScreen> createState() => _EggCollectionScreenState();
}

class _EggCollectionScreenState extends State<EggCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _flockId;
  DateTime _date = DateTime.now();
  int _wholeEggs = 0, _brokenEggs = 0;
  List<Map<String, dynamic>> _flocks = [];
  Database? _db;
  Map<String, dynamic>? _collection; // Store selected collection
  bool _isEditing = false; // Track edit mode
  String? _collectionId; // Store collection ID for
  final _wholeEggsController = TextEditingController();
  final _brokenEggsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initDb();
    _fetchFlocks();
    // Retrieve arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['collection'] != null) {
        setState(() {
          _collection = args['collection'];
          _isEditing = true;
          _collectionId = _collection!['id'].toString();
          _flockId = _collection!['flock_id'];
          _date = DateTime.parse(_collection!['collection_date']);
          _wholeEggs = _collection!['whole_eggs'] ?? 0;
          _wholeEggsController.text = _wholeEggs.toString();
          _brokenEggs = _collection!['broken_eggs'] ?? 0;
          _brokenEggsController.text = _brokenEggs.toString();
        });
      }
    });
  }

  @override
  void dispose() {
    _wholeEggsController.dispose();
    _brokenEggsController.dispose();
    super.dispose();
  }

  Future<void> _initDb() async {
    _db = await openDatabase(
      path.join(await getDatabasesPath(), 'turuke.db'),
      onCreate:
          (db, version) => db.execute(
            'CREATE TABLE egg_pending(id TEXT PRIMARY KEY, flock_id INTEGER, collection_date TEXT, whole_eggs INTEGER, broken_eggs INTEGER)',
          ),
      version: 1,
    );
  }

  Future<void> _fetchFlocks() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await http.get(
        Uri.parse(
          '${Constants.API_BASE_URL}/flocks?farm_id=${authProvider.user!.farmId}',
        ),
        headers: await authProvider.getHeaders(),
      );
      if (response.statusCode == 200) {
        setState(() {
          _flocks = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        });
      }
    } catch (e) {
      // Handle offline
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate() && _flockId != null) {
      final data = {
        'flock_id': _flockId,
        'collection_date': _date.toIso8601String().substring(0, 10),
        'whole_eggs': _wholeEggs,
        'broken_eggs': _brokenEggs,
      };
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      try {
        final response =
            _isEditing
                ? await http.patch(
                  Uri.parse(
                    '${Constants.API_BASE_URL}/egg-production/$_collectionId',
                  ),
                  headers: await authProvider.getHeaders(),
                  body: jsonEncode(data),
                )
                : await http.post(
                  Uri.parse('${Constants.API_BASE_URL}/egg-production'),
                  headers: await authProvider.getHeaders(),
                  body: jsonEncode(data),
                );

        if (response.statusCode == (_isEditing ? 200 : 201)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? 'Successfully updated collection for ${_date.toIso8601String().substring(0, 10)}'
                    : 'Successfully saved collection for ${_date.toIso8601String().substring(0, 10)}',
              ),
            ),
          );
        } else {
          throw Exception('Failed to save');
        }
      } catch (e) {
        await _db!.insert('egg_pending', {
          'id': Uuid().v4(),
          ...data,
          'collection_date': data['collection_date'],
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved offline, will sync later')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back),
        ),
        title: Text('Egg Collection'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                value: _flockId,
                decoration: const InputDecoration(labelText: 'Select Flock'),
                items:
                    _flocks
                        .where((f) => f['status'] == 1) // Active flocks only
                        .map(
                          (f) => DropdownMenuItem(
                            value: f['id'] as int,
                            child: Text(f['breed']),
                          ),
                        )
                        .toList(),
                onChanged: (value) => setState(() => _flockId = value),
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(labelText: 'Date'),
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                controller: TextEditingController(
                  text: _date.toIso8601String().substring(0, 10),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _wholeEggsController,
                decoration: InputDecoration(labelText: 'Whole Eggs'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onChanged:
                    (value) =>
                        setState(() => _wholeEggs = int.tryParse(value) ?? 0),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _brokenEggsController,
                decoration: InputDecoration(labelText: 'Broken Eggs'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onChanged:
                    (value) =>
                        setState(() => _brokenEggs = int.tryParse(value) ?? 0),
              ),
              SizedBox(height: 16),
              Text(
                'Total Eggs: ${_wholeEggs + _brokenEggs}',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 16),
              ElevatedButton(onPressed: _save, child: Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}
