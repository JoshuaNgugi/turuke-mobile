import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/models/flock.dart';
import 'package:turuke_app/providers/auth_provider.dart';

class AddMortalityScreen extends StatefulWidget {
  static const String routeName = '/add-mortality';
  const AddMortalityScreen({super.key});

  @override
  State<AddMortalityScreen> createState() => _AddMortalityScreenState();
}

class _AddMortalityScreenState extends State<AddMortalityScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _flockId;
  DateTime _date = DateTime.now();
  int _mortalityCount = 0, _mortalityCause = 0;
  List<Flock> _flocks = [];
  Database? _db;
  Map<String, dynamic>? _collection; // Store selected collection
  bool _isEditing = false;
  String? _collectionId; // Store collection ID for
  final _mortalityCountController = TextEditingController();
  final _mortalityCauseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initDb();
    _fetchFlocks();
    // Retrieve arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['mortality'] != null) {
        setState(() {
          _collection = args['mortality'];
          _isEditing = true;
          _collectionId = _collection!['id'].toString();
          _flockId = _collection!['flock_id'];
          _date = DateTime.parse(_collection!['death_date']);
          _mortalityCount = _collection!['count'] ?? 0;
          _mortalityCountController.text = _mortalityCount.toString();
          _mortalityCause = _collection!['cause'];
          _mortalityCauseController.text = _mortalityCause.toString();
        });
      }
    });
  }

  @override
  void dispose() {
    _mortalityCountController.dispose();
    _mortalityCauseController.dispose();
    super.dispose();
  }

  Future<void> _initDb() async {
    // _db = await openDatabase(
    //   path.join(await getDatabasesPath(), 'turuke.db'),
    //   onCreate:
    //       (db, version) => db.execute(
    //         'CREATE TABLE mortality(id TEXT PRIMARY KEY, flock_id INTEGER, collection_date TEXT, whole_eggs INTEGER, broken_eggs INTEGER)',
    //       ),
    //   version: 1,
    // );
  }

  Future<void> _fetchFlocks() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await http.get(
        Uri.parse(
          '${Constants.LAYERS_API_BASE_URL}/flocks?farm_id=${authProvider.user!.farmId}',
        ),
        headers: await authProvider.getHeaders(),
      );
      if (response.statusCode == 200) {
        setState(() {
          final List<dynamic> jsonList = jsonDecode(response.body);
          _flocks = jsonList.map((json) => Flock.fromJson(json)).toList();
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
        'death_date': _date.toIso8601String().substring(0, 10),
        'count': _mortalityCount,
        'cause': _mortalityCause,
      };
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      try {
        final response =
            _isEditing
                ? await http.patch(
                  Uri.parse(
                    '${Constants.LAYERS_API_BASE_URL}/mortality/$_collectionId',
                  ),
                  headers: await authProvider.getHeaders(),
                  body: jsonEncode(data),
                )
                : await http.post(
                  Uri.parse('${Constants.LAYERS_API_BASE_URL}/mortality'),
                  headers: await authProvider.getHeaders(),
                  body: jsonEncode(data),
                );

        if (response.statusCode == (_isEditing ? 200 : 201)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? 'Mortality updated successfully'
                    : 'Mortality saved successfully',
              ),
            ),
          );
        } else {
          throw Exception('Failed to save');
        }
      } catch (e) {
        // await _db!.insert('egg_pending', {
        //   'id': Uuid().v4(),
        //   ...data,
        //   'collection_date': data['collection_date'],
        // });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to save know. Please try again later'),
          ),
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
        title: Text('Mortality'),
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
                        .where(
                          (flock) => flock.status == 1,
                        ) // Active flocks only
                        .map(
                          (flock) => DropdownMenuItem(
                            value: flock.id,
                            child: Text(flock.name),
                          ),
                        )
                        .toList(),
                onChanged: (value) => setState(() => _flockId = value),
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(labelText: 'Recorded Date'),
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
                controller: _mortalityCountController,
                decoration: InputDecoration(labelText: 'Count'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onChanged:
                    (value) => setState(
                      () => _mortalityCount = int.tryParse(value) ?? 0,
                    ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _mortalityCauseController,
                decoration: InputDecoration(labelText: 'Cause'),
                keyboardType: TextInputType.text,
                maxLines: 3,
                onChanged:
                    (value) => setState(
                      () => _mortalityCause = int.tryParse(value) ?? 0,
                    ),
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
