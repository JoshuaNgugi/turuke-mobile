import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/src/response.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/models/disease.dart';
import 'package:turuke_app/models/flock.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/utils/http_client.dart';
import 'package:turuke_app/utils/system_utils.dart';

var logger = Logger(printer: PrettyPrinter());

class AddEditDiseaseScreen extends StatefulWidget {
  static const String routeName = '/add-edit-disease';

  const AddEditDiseaseScreen({super.key});

  @override
  State<AddEditDiseaseScreen> createState() => _AddEditDiseaseScreenState();
}

class _AddEditDiseaseScreenState extends State<AddEditDiseaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final DateFormat _dateFormat = DateFormat('d MMMM, y');

  int? _flockId;
  DateTime _diagnosisDate = DateTime.now();
  int? _affectedCount;
  String _notes = '';
  String _diseaseName = '';

  List<Flock> _flocks = [];
  bool _isLoadingFlocks = true;
  bool _isWholeFlockAffected = false;
  Disease? _diseaseToEdit;

  late TextEditingController _diseaseNameController;
  late TextEditingController _diagnosisDateController;
  late TextEditingController _affectedCountController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _diseaseNameController = TextEditingController();
    _diagnosisDateController = TextEditingController();
    _affectedCountController = TextEditingController();
    _notesController = TextEditingController();

    _fetchFlocks();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_diseaseToEdit == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args.containsKey('disease')) {
        _diseaseToEdit = args['disease'] as Disease;
        _populateFields(_diseaseToEdit!);
      } else {
        _diagnosisDateController.text = _dateFormat.format(_diagnosisDate);
      }
    }
  }

  @override
  void dispose() {
    _diseaseNameController.dispose();
    _diagnosisDateController.dispose();
    _affectedCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populateFields(Disease disease) {
    _flockId = disease.flockId;
    _diseaseName = disease.name;
    _diagnosisDate = _dateFormat.parse(disease.diagnosisDate);
    _affectedCount = disease.affectedCount;
    _notes = disease.notes ?? '';
    _isWholeFlockAffected = disease.isWholeFlockAffected ?? false;

    _diseaseNameController.text = _diseaseName;
    _diagnosisDateController.text = _dateFormat.format(_diagnosisDate);
    _notesController.text = _notes;
    if (_affectedCount != null) {
      _affectedCountController.text = _affectedCount.toString();
    }
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
      final response = await HttpClient.get(
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
      if (!mounted) return;
      SystemUtils.showSnackBar(context, 'Farm ID not available. Cannot save.');
      return;
    }

    Disease disease = Disease(
      flockId: _flockId!,
      name: _diseaseName,
      diagnosisDate: _dateFormat.format(_diagnosisDate),
      affectedCount: _affectedCount,
      notes: _notes,
      isWholeFlockAffected: _isWholeFlockAffected,
    );

    try {
      Response response;
      if (_diseaseToEdit != null) {
        response = await HttpClient.patch(
          Uri.parse(
            '${Constants.LAYERS_API_BASE_URL}/diseases/${_diseaseToEdit!.id}',
          ),
          headers: headers,
          body: jsonEncode(disease.toJson()),
        );
        if (response.statusCode == 200) {
          if (mounted) {
            SystemUtils.showSnackBar(
              context,
              'Disease record updated successfully!',
            );
            Navigator.pop(context, true);
          }
        } else {
          logger.e(
            'Failed to update disease: ${response.statusCode} - ${response.body}',
          );
          throw Exception('Failed to update disease');
        }
      } else {
        response = await HttpClient.post(
          Uri.parse('${Constants.LAYERS_API_BASE_URL}/diseases'),
          headers: headers,
          body: jsonEncode(disease.toJson()),
        );
        if (response.statusCode == 201) {
          if (mounted) {
            SystemUtils.showSnackBar(
              context,
              'Disease record added successfully!',
            );
            Navigator.pop(context, true);
          }
        } else {
          logger.e(
            'Failed to add disease: ${response.statusCode} - ${response.body}',
          );
          throw Exception('Failed to add disease');
        }
      }
    } catch (e) {
      logger.e('Error during API call for disease: $e');
      if (mounted) {
        SystemUtils.showSnackBar(
          context,
          'Failed to save disease record. Please try again later.',
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
          _diseaseToEdit != null ? 'Edit Disease' : 'Add Disease',
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
                        controller: _diseaseNameController,
                        decoration: _inputDecoration('Disease Name', ''),
                        validator:
                            (value) =>
                                value!.isEmpty
                                    ? 'Disease Name is required'
                                    : null,
                        onChanged: (value) => _diseaseName = value,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _diagnosisDateController,
                        decoration: _inputDecoration('Recorded Date', ''),
                        readOnly: true,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _diagnosisDate,
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
                              _diagnosisDate = picked;
                              _diagnosisDateController.text = _dateFormat
                                  .format(_diagnosisDate);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade700),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: SwitchListTile(
                          title: const Text('Entire flock affected'),
                          value: _isWholeFlockAffected,
                          onChanged: (value) {
                            setState(() {
                              _isWholeFlockAffected = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!_isWholeFlockAffected)
                        TextFormField(
                          controller: _affectedCountController,
                          decoration: _inputDecoration('Affected Count', ''),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter affected count';
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
                                  _affectedCount = int.tryParse(value) ?? 0,
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: _inputDecoration('Notes', ''),
                        keyboardType: TextInputType.text,
                        maxLines: 3,
                        onChanged: (value) => _notes = value.trim(),
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
                            _diseaseToEdit != null
                                ? 'Update Disease'
                                : 'Add Disease',
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
