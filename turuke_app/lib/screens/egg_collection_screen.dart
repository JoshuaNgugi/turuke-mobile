import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/models/egg_data.dart';
import 'package:turuke_app/models/flock.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/utils/http_client.dart';
import 'package:turuke_app/utils/system_utils.dart';
import 'package:uuid/uuid.dart';

var logger = Logger(printer: PrettyPrinter());

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
  List<Flock> _flocks = [];
  Database? _db;
  EggData? _initialEggData;
  bool _isEditing = false;
  String? _collectionId;
  bool _isLoading = true;

  final _wholeEggsController = TextEditingController();
  final _brokenEggsController = TextEditingController();

  DateFormat dateFormat = DateFormat('d MMMM, y');

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _initDb();
    await _fetchFlocks();

    // Process arguments after data is potentially loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final EggData? argsCollection =
          ModalRoute.of(context)?.settings.arguments as EggData?;

      if (argsCollection != null) {
        setState(() {
          _initialEggData = argsCollection;
          _isEditing = true;
          _collectionId = _initialEggData!.id.toString(); // Use ID from EggData
          _flockId = _initialEggData!.flockId;
          _date = dateFormat.parse(_initialEggData!.collectionDate);
          _wholeEggs = _initialEggData!.wholeEggs;
          _wholeEggsController.text = _wholeEggs.toString();
          _brokenEggs = _initialEggData!.brokenEggs;
          _brokenEggsController.text = _brokenEggs.toString();
        });
      }
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _wholeEggsController.dispose();
    _brokenEggsController.dispose();
    _db?.close();
    super.dispose();
  }

  Future<void> _initDb() async {
    try {
      _db = await openDatabase(
        path.join(await getDatabasesPath(), 'turuke.db'),
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE egg_pending(id TEXT PRIMARY KEY, flock_id INTEGER, collection_date TEXT, whole_eggs INTEGER, broken_eggs INTEGER, is_synced INTEGER DEFAULT 0)',
          );
          await db.execute(
            'CREATE TABLE flocks(id INTEGER PRIMARY KEY, farm_id INTEGER, name TEXT, arrivalDate TEXT, initialCount INTEGER, currentCount INTEGER, ageWeeks INTEGER, status INTEGER, currentAgeWeeks INTEGER)',
          );
        },
        version: 1,
      );
    } catch (e) {
      logger.e("Error initializing database: $e");
      if (mounted) {
        SystemUtils.showSnackBar(
          context,
          'Database initialization failed. Please restart app.',
        );
      }
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

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _flocks = jsonList.map((json) => Flock.fromJson(json)).toList();
          });
        }
      } else {
        logger.w(
          'Failed to fetch flocks (${response.statusCode}). Falling back to offline flocks.',
        );
        await _loadOfflineFlocks();
      }
    } catch (e) {
      logger.e('Error fetching flocks online: $e. Falling back to offline.');
      await _loadOfflineFlocks();
    }
  }

  Future<void> _loadOfflineFlocks() async {
    try {
      if (_db == null) {
        await _initDb();
      }
      final List<Map<String, dynamic>> offlineFlocksMaps = await _db!.query(
        'flocks',
      );
      if (mounted) {
        setState(() {
          _flocks =
              offlineFlocksMaps.map((map) => Flock.fromJson(map)).toList();
          if (!_isEditing && _flockId == null && _flocks.isNotEmpty) {
            _flockId = _flocks.first.id;
          }
        });
      }
      if (offlineFlocksMaps.isEmpty) {
        if (mounted) {
          SystemUtils.showSnackBar(
            context,
            'No flocks available. Please connect to internet.',
          );
        }
      } else {
        if (mounted) {
          SystemUtils.showSnackBar(context, 'Showing offline flocks.');
        }
      }
    } catch (e) {
      logger.e('Error loading offline flocks: $e');
      if (mounted) {
        _flocks = [];
        _flockId = null;
        SystemUtils.showSnackBar(context, 'Failed to load flocks offline.');
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      SystemUtils.showSnackBar(
        context,
        'Please correct the errors in the form.',
      );
      return;
    }

    if (_flockId == null) {
      SystemUtils.showSnackBar(context, 'Please select a flock.');
      return;
    }

    if (_db == null) {
      await _initDb();
      if (_db == null) {
        if (!mounted) return;
        SystemUtils.showSnackBar(context, 'Database not ready. Cannot save.');
        return;
      }
    }

    final data = {
      'flock_id': _flockId,
      'collection_date': _date.toIso8601String().substring(0, 10),
      'whole_eggs': _wholeEggs,
      'broken_eggs': _brokenEggs,
    };
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final response =
          _isEditing
              ? await HttpClient.patch(
                Uri.parse(
                  '${Constants.LAYERS_API_BASE_URL}/egg-production/$_collectionId',
                ),
                headers: await authProvider.getHeaders(),
                body: jsonEncode(data),
              )
              : await HttpClient.post(
                Uri.parse('${Constants.LAYERS_API_BASE_URL}/egg-production'),
                headers: await authProvider.getHeaders(),
                body: jsonEncode(data),
              );

      if (response.statusCode == (_isEditing ? 200 : 201)) {
        if (mounted) {
          SystemUtils.showSnackBar(
            context,
            _isEditing
                ? 'Successfully updated collection for ${_date.toIso8601String().substring(0, 10)}'
                : 'Successfully saved collection for ${_date.toIso8601String().substring(0, 10)}',
            backgroundColor: Constants.kAccentColor,
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(
          'API Save Failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      logger.e('Error saving online: $e. Attempting offline save.');
      final String id =
          _collectionId ??
          const Uuid().v4(); // Reuse ID if editing, else new UUID
      await _db!.insert(
        'egg_pending',
        {
          'id': id,
          ...data,
          'is_synced': 0, // Mark as not synced
        },
        conflictAlgorithm:
            ConflictAlgorithm
                .replace, // Replace if editing existing offline entry
      );
      if (mounted) {
        SystemUtils.showSnackBar(
          context,
          'Saved offline. Data will sync when connected.',
          backgroundColor: Colors.orange,
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Egg Collection' : 'Add Egg Collection',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Constants.kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Constants.kPrimaryColor,
                  ),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<int>(
                        value: _flockId,
                        decoration: _inputDecoration('Select Flock'),
                        items:
                            _flocks
                                .where((f) => f.status == 1)
                                .map(
                                  (f) => DropdownMenuItem(
                                    value: f.id,
                                    child: Text(f.name),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) => setState(() => _flockId = value),
                        validator:
                            (value) =>
                                value == null ? 'Flock is required' : null,
                        isExpanded: true,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        decoration: _inputDecoration('Collection Date'),
                        readOnly: true,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: Constants.kPrimaryColor,
                                    onPrimary: Colors.white,
                                    onSurface: Colors.black87,
                                  ),
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Constants.kPrimaryColor,
                                    ),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() => _date = picked);
                          }
                        },
                        controller: TextEditingController(
                          text: _date.toIso8601String().substring(0, 10),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _wholeEggsController,
                        decoration: _inputDecoration('Whole Eggs'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Whole eggs count is required';
                          }
                          if (int.tryParse(value) == null ||
                              int.parse(value) < 0) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                        onChanged:
                            (value) => setState(
                              () => _wholeEggs = int.tryParse(value) ?? 0,
                            ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _brokenEggsController,
                        decoration: _inputDecoration('Broken Eggs'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Broken eggs count is required';
                          }
                          if (int.tryParse(value) == null ||
                              int.parse(value) < 0) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                        onChanged:
                            (value) => setState(
                              () => _brokenEggs = int.tryParse(value) ?? 0,
                            ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Total Eggs: ${_wholeEggs + _brokenEggs}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Constants.kPrimaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.kPrimaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _isEditing ? 'Update Collection' : 'Save Collection',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  InputDecoration _inputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      border: const OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Constants.kPrimaryColor, width: 2.0),
      ),
      labelStyle: TextStyle(color: Constants.kPrimaryColor),
    );
  }
}
