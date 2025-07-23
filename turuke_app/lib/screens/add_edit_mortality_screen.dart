import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/models/flock.dart';
import 'package:turuke_app/models/mortality.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/utils/system_utils.dart';

var logger = Logger(printer: PrettyPrinter());

class AddEditMortalityScreen extends StatefulWidget {
  static const String routeName = '/add-edit-mortality';

  const AddEditMortalityScreen({super.key});

  @override
  State<AddEditMortalityScreen> createState() => _AddEditMortalityScreenState();
}

class _AddEditMortalityScreenState extends State<AddEditMortalityScreen> {
  final _formKey = GlobalKey<FormState>();
  final DateFormat _dateFormat = DateFormat('d MMMM, y');

  int? _flockId;
  DateTime _recordedDate = DateTime.now();
  int _mortalityCount = 0;
  String _mortalityCause = '';

  List<Flock> _flocks = [];
  bool _isLoadingFlocks = true;
  Mortality? _mortalityToEdit;

  late TextEditingController _recordedDateController;
  late TextEditingController _mortalityCountController;
  late TextEditingController _mortalityCauseController;

  @override
  void initState() {
    super.initState();
    _recordedDateController = TextEditingController();
    _mortalityCountController = TextEditingController();
    _mortalityCauseController = TextEditingController();

    _fetchFlocks();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mortalityToEdit == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args.containsKey('mortality')) {
        _mortalityToEdit = args['mortality'] as Mortality;
        _populateFields(_mortalityToEdit!);
      } else {
        _recordedDateController.text = _dateFormat.format(_recordedDate);
      }
    }
  }

  @override
  void dispose() {
    _recordedDateController.dispose();
    _mortalityCountController.dispose();
    _mortalityCauseController.dispose();
    super.dispose();
  }

  // Populates form fields when editing an existing mortality record
  void _populateFields(Mortality mortality) {
    _flockId = mortality.flockId;
    _recordedDate = _dateFormat.parse(mortality.recordedDate);
    _mortalityCount = mortality.count;
    _mortalityCause = mortality.cause ?? '';

    _recordedDateController.text = _dateFormat.format(_recordedDate);
    _mortalityCountController.text = _mortalityCount.toString();
    _mortalityCauseController.text = _mortalityCause;
  }

  Future<void> _fetchFlocks() async {
    if (!mounted) return;
    setState(() => _isLoadingFlocks = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final headers = await authProvider.getHeaders();
    final farmId = authProvider.user?.farmId;
    if (farmId == null) {
      logger.e('Farm ID is null. Cannot fetch flocks.');
      if (mounted) {
        SystemUtils.showSnackBar(
          context,
          'Error: Farm ID not found. Please re-login.',
        );
      }
      setState(() => _isLoadingFlocks = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${Constants.LAYERS_API_BASE_URL}/flocks?farm_id=$farmId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _flocks = jsonList.map((json) => Flock.fromJson(json)).toList();
          });
        }
      } else {
        logger.e(
          'Failed to fetch flocks: ${response.statusCode} - ${response.body}',
        );
        if (mounted) {
          SystemUtils.showSnackBar(
            context,
            'Failed to load flocks for dropdown.',
          );
        }
      }
    } catch (e) {
      logger.e('Error fetching flocks: $e');
      if (mounted) {
        SystemUtils.showSnackBar(
          context,
          'Network error. Could not load flocks.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingFlocks = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final headers = await authProvider.getHeaders();
    final farmId = authProvider.user?.farmId;

    if (farmId == null) {
      SystemUtils.showSnackBar(context, 'Farm ID not available. Cannot save.');
      return;
    }

    Mortality mortality = Mortality(
      flockId: _flockId!,
      count: _mortalityCount,
      recordedDate: _dateFormat.format(_recordedDate),
      cause: _mortalityCause,
    );

    try {
      http.Response response;
      if (_mortalityToEdit != null) {
        response = await http.patch(
          Uri.parse(
            '${Constants.LAYERS_API_BASE_URL}/mortality/${_mortalityToEdit!.id}',
          ),
          headers: headers,
          body: jsonEncode(mortality.toJson()),
        );
        if (response.statusCode == 200) {
          if (mounted) {
            SystemUtils.showSnackBar(
              context,
              'Mortality record updated successfully!',
            );
            Navigator.pop(context, true);
          }
        } else {
          logger.e(
            'Failed to update mortality: ${response.statusCode} - ${response.body}',
          );
          throw Exception('Failed to update mortality');
        }
      } else {
        response = await http.post(
          Uri.parse('${Constants.LAYERS_API_BASE_URL}/mortality'),
          headers: headers,
          body: jsonEncode(mortality.toJson()),
        );
        if (response.statusCode == 201) {
          if (mounted) {
            SystemUtils.showSnackBar(
              context,
              'Mortality record added successfully!',
            );
            Navigator.pop(context, true);
          }
        } else {
          logger.e(
            'Failed to add mortality: ${response.statusCode} - ${response.body}',
          );
          throw Exception('Failed to add mortality');
        }
      }
    } catch (e) {
      logger.e('Error during API call for mortality: $e');
      if (mounted) {
        SystemUtils.showSnackBar(
          context,
          'Failed to save mortality record. Please check your internet connection and try again.',
        );
      }
    }
  }

  InputDecoration _inputDecoration(String labelText, String hintText) {
    return InputDecoration(
      labelText: labelText,
      border: const OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Constants.kPrimaryColor, width: 2.0),
      ),
      labelStyle: TextStyle(color: Constants.kPrimaryColor),
      hintText: hintText,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _mortalityToEdit != null ? 'Edit Mortality' : 'Add Mortality',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Constants.kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          _isLoadingFlocks
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<int>(
                        decoration: _inputDecoration('Select Flock', ''),
                        value: _flockId,
                        items:
                            _flocks
                                .where((flock) => flock.status == 1)
                                .map(
                                  (flock) => DropdownMenuItem(
                                    value: flock.id,
                                    child: Text(flock.name),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) => setState(() => _flockId = value),
                        validator:
                            (value) =>
                                value == null ? 'Please select a flock' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _recordedDateController,
                        decoration: _inputDecoration('Recorded Date', ''),
                        readOnly: true,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _recordedDate,
                            firstDate: DateTime(2020, 1, 1),
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
                          if (picked != null && mounted) {
                            setState(() {
                              _recordedDate = picked;
                              _recordedDateController.text = _dateFormat.format(
                                _recordedDate,
                              );
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _mortalityCountController,
                        decoration: _inputDecoration('Mortality Count', ''),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter mortality count';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          if (int.parse(value) < 0) {
                            return 'Count cannot be negative';
                          }
                          return null;
                        },
                        onChanged:
                            (value) =>
                                _mortalityCount = int.tryParse(value) ?? 0,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _mortalityCauseController,
                        decoration: _inputDecoration(
                          'Cause',
                          'What was the cause of death?',
                        ),
                        keyboardType: TextInputType.text,
                        maxLines: 3,
                        onChanged: (value) => _mortalityCause = value.trim(),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Constants.kPrimaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            _mortalityToEdit != null
                                ? 'Update Mortality'
                                : 'Add Mortality',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
