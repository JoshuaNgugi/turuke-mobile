import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/models/disease.dart';
import 'package:turuke_app/models/flock.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/navigation_drawer_screen.dart';
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
  final DateFormat _dateFormat = DateFormat('d MMMM, y');

  @override
  void initState() {
    super.initState();
    _initializeData(); // Combine init and fetches
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
      // Fetch flocks for the dropdown
      final flocksRes = await http.get(
        Uri.parse('${Constants.LAYERS_API_BASE_URL}/flocks?farm_id=$farmId'),
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

      // Fetch diseases
      final diseasesRes = await http.get(
        Uri.parse('${Constants.LAYERS_API_BASE_URL}/diseases?farm_id=$farmId'),
        headers: headers,
      );
      if (mounted) {
        if (diseasesRes.statusCode == 200) {
          final List<dynamic> jsonList = jsonDecode(diseasesRes.body);
          _diseases = jsonList.map((json) => Disease.fromJson(json)).toList();

          setState(() {}); // Update UI with fetched diseases
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

  Future<void> _showAddEditDiseaseDialog({Disease? diseaseToEdit}) async {
    final _formKey = GlobalKey<FormState>();
    int? _flockId = diseaseToEdit?.flockId;
    String _diseaseName = diseaseToEdit?.name ?? '';
    DateTime _diagnosisDate =
        diseaseToEdit != null
            ? _dateFormat.parse(diseaseToEdit.diagnosisDate)
            : DateTime.now();
    int _affectedCount = diseaseToEdit?.affectedCount ?? 0;
    String _notes = diseaseToEdit?.notes ?? '';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: Text(
                diseaseToEdit != null ? 'Edit Disease' : 'Add Disease',
              ),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        decoration: _inputDecoration('Select Flock'),
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
                        onChanged: (value) {
                          setStateInDialog(() {
                            _flockId = value;
                          });
                        },
                        validator:
                            (value) =>
                                value == null ? 'Flock is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: _inputDecoration('Disease Name'),
                        validator:
                            (value) =>
                                value!.isEmpty
                                    ? 'Disease Name is required'
                                    : null,
                        onChanged: (value) => _diseaseName = value,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: TextEditingController(
                          text: _dateFormat.format(_diagnosisDate),
                        ),
                        decoration: _inputDecoration('Diagnosis Date'),
                        readOnly: true,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _diagnosisDate,
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
                            setStateInDialog(() {
                              _diagnosisDate = picked;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: _inputDecoration('Affected Count'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Affected Count is required';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Enter a valid number';
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
                        decoration: _inputDecoration('Notes (Optional)'),
                        maxLines: 3,
                        onChanged: (value) => _notes = value,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    foregroundColor: Constants.kPrimaryColor,
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate() && _flockId != null) {
                      Navigator.pop(context, true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.kPrimaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final farmId = authProvider.user?.farmId;

      if (farmId == null) {
        SystemUtils.showSnackBar(
          context,
          'Farm ID not available. Cannot save.',
        );
        return;
      }

      Disease disease = Disease(
        flockId: _flockId!,
        name: _diseaseName,
        diagnosisDate: _dateFormat.format(_diagnosisDate),
        affectedCount: _affectedCount,
        notes: _notes,
      );

      try {
        http.Response response;
        if (diseaseToEdit != null) {
          response = await http.patch(
            Uri.parse(
              '${Constants.LAYERS_API_BASE_URL}/diseases/${diseaseToEdit.id}',
            ),
            headers: await authProvider.getHeaders(),
            body: jsonEncode(disease.toJson()),
          );
          if (response.statusCode == 200) {
            SystemUtils.showSnackBar(
              context,
              'Disease record updated successfully!',
            );
            await _fetchData();
          } else {
            throw Exception(
              'Failed to update disease record: ${response.body}',
            );
          }
        } else {
          response = await http.post(
            Uri.parse('${Constants.LAYERS_API_BASE_URL}/diseases'),
            headers: await authProvider.getHeaders(),
            body: jsonEncode(disease.toJson()),
          );
          if (response.statusCode == 201) {
            SystemUtils.showSnackBar(
              context,
              'Disease record added successfully!',
            );
            await _fetchData();
          } else {
            throw Exception('Failed to add disease record: ${response.body}');
          }
        }
      } catch (e) {
        logger.e('Error saving/updating disease: $e');
        SystemUtils.showSnackBar(
          context,
          'Failed to save disease record. Please try again.',
        );
      }
    }
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

  void _onRouteSelected(String route) {
    Navigator.pushNamed(context, route);
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
                                        disease.name, // Disease name
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
                                            'Affected: ${disease.affectedCount}',
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
                                          () => _showAddEditDiseaseDialog(
                                            diseaseToEdit: disease,
                                          ),
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            _flocks.isEmpty
                ? null
                : () => _showAddEditDiseaseDialog(diseaseToEdit: null),
        backgroundColor: Constants.kPrimaryColor,
        foregroundColor: Colors.white,
        tooltip: 'Add Disease Record',
        child: const Icon(Icons.add),
      ),
    );
  }
}
