import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/models/flock.dart';
import 'package:turuke_app/models/vaccination.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/navigation_drawer_screen.dart';
import 'package:turuke_app/utils/http_client.dart';
import 'package:turuke_app/utils/string_utils.dart';
import 'package:turuke_app/utils/system_utils.dart';
import 'package:uuid/uuid.dart';

var logger = Logger(printer: PrettyPrinter());

class VaccinationLogScreen extends StatefulWidget {
  static const String routeName = '/vaccination-log';

  const VaccinationLogScreen({super.key});

  @override
  State<VaccinationLogScreen> createState() => _VaccinationLogScreenState();
}

class _VaccinationLogScreenState extends State<VaccinationLogScreen> {
  List<Vaccination> _vaccinations = [];
  List<Flock> _flocks = [];

  bool _isLoading = true;
  final DateFormat _dateFormat = DateFormat('d MMMM, y');

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    await _fetchData();
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
      final flocksRes = await HttpClient.get(
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
        logger.w(
          'Failed to fetch flocks (${flocksRes.statusCode}). Falling back to offline flocks.',
        );
      }

      final vaccinationsRes = await HttpClient.get(
        Uri.parse(
          '${Constants.LAYERS_API_BASE_URL}/vaccinations?farm_id=$farmId',
        ),
        headers: headers,
      );
      if (mounted) {
        if (vaccinationsRes.statusCode == 200) {
          final List<dynamic> jsonList = jsonDecode(vaccinationsRes.body);
          _vaccinations =
              jsonList.map((json) => Vaccination.fromJson(json)).toList();
        } else {
          logger.w(
            'Failed to fetch vaccinations (${vaccinationsRes.statusCode}). Falling back to offline vaccinations.',
          );
        }
      }
    } catch (e) {
      logger.e('Error fetching data online: $e. Falling back to offline.');
      if (mounted) {
        SystemUtils.showSnackBar(context, 'Failed to fetch data online.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAddEditVaccinationDialog({
    Vaccination? vaccinationToEdit,
  }) async {
    final _formKey = GlobalKey<FormState>();

    int? _flockId = vaccinationToEdit?.flockId;
    DateTime _vaccinationDate =
        vaccinationToEdit != null
            ? _dateFormat.parse(vaccinationToEdit.vaccinationDate)
            : DateTime.now();

    String _vaccineName = vaccinationToEdit?.name ?? '';
    String _notes = vaccinationToEdit?.notes ?? '';

    final vaccineNameController = TextEditingController(text: _vaccineName);
    final notesController = TextEditingController(text: _notes);
    final vaccinationDateController = TextEditingController(
      text: _dateFormat.format(_vaccinationDate),
    );

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setStateInDialog) {
              return AlertDialog(
                title: Text(
                  vaccinationToEdit != null
                      ? 'Edit Vaccination'
                      : 'Add Vaccination',
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
                              _flocks.map<DropdownMenuItem<int>>((flock) {
                                return DropdownMenuItem<int>(
                                  value: flock.id,
                                  child: Text(flock.name),
                                );
                              }).toList(),
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
                          controller: vaccineNameController,
                          decoration: _inputDecoration('Vaccine Name'),
                          validator:
                              (value) =>
                                  value!.isEmpty
                                      ? 'Vaccine Name is required'
                                      : null,
                          onChanged: (value) => _vaccineName = value,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: vaccinationDateController,
                          decoration: _inputDecoration('Vaccination Date'),
                          readOnly: true,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _vaccinationDate,
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
                                        foregroundColor:
                                            Constants.kPrimaryColor,
                                      ),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setStateInDialog(() {
                                _vaccinationDate = picked;
                                vaccinationDateController.text = _dateFormat
                                    .format(picked); // ✅ update text
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: notesController,
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
                      if (_formKey.currentState!.validate() &&
                          _flockId != null) {
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
        await _saveVaccination(
          vaccinationToEdit: vaccinationToEdit,
          flockId: _flockId!,
          name: _vaccineName,
          date: _vaccinationDate,
          notes: _notes,
        );
      }
    } finally {
      vaccineNameController.dispose();
      notesController.dispose();
      vaccinationDateController.dispose();
    }
  }

  Future<void> _saveVaccination({
    required int flockId,
    required String name,
    required DateTime date,
    required String notes,
    Vaccination? vaccinationToEdit,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final farmId = authProvider.user?.farmId;

    if (farmId == null) {
      SystemUtils.showSnackBar(context, 'Farm ID not available. Cannot save.');
      return;
    }

    final vaccination = Vaccination(
      flockId: flockId,
      name: name,
      vaccinationDate: _dateFormat.format(date),
      notes: notes,
    );

    try {
      var response;
      if (vaccinationToEdit != null) {
        response = await HttpClient.patch(
          Uri.parse(
            '${Constants.LAYERS_API_BASE_URL}/vaccinations/${vaccinationToEdit.id}',
          ),
          headers: await authProvider.getHeaders(),
          body: jsonEncode(vaccination.toJson()),
        );
        if (response.statusCode == 200) {
          if (!mounted) return;

          SystemUtils.showSnackBar(
            context,
            'Vaccination updated successfully!',
          );
          await _fetchData();
        } else {
          throw Exception('Failed to update vaccination: ${response.body}');
        }
      } else {
        response = await HttpClient.post(
          Uri.parse('${Constants.LAYERS_API_BASE_URL}/vaccinations'),
          headers: await authProvider.getHeaders(),
          body: jsonEncode(vaccination.toJson()),
        );
        if (response.statusCode == 201) {
          if (!mounted) return;
          SystemUtils.showSnackBar(context, 'Vaccination added successfully!');
          await _fetchData();
        } else {
          throw Exception('Failed to add vaccination: ${response.body}');
        }
      }
    } catch (e) {
      logger.e('Error saving/updating vaccination: $e.');
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
        title: const Text(
          'Vaccination Log',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Constants.kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: AppNavigationDrawer(
        selectedRoute: VaccinationLogScreen.routeName,
        onRouteSelected: _onRouteSelected,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
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
                          _vaccinations.isEmpty
                              ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'No vaccination records found. Add a flock then tap the + button to add one.',
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
                                itemCount: _vaccinations.length,
                                itemBuilder: (context, index) {
                                  final vaccination = _vaccinations[index];
                                  final flockName =
                                      _flocks
                                          .firstWhere(
                                            (f) => f.id == vaccination.flockId,
                                            orElse:
                                                () => Flock(
                                                  id: vaccination.flockId,
                                                  name:
                                                      'Unknown Flock', // Default name for display
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
                                  final vaccinationDateDisplay =
                                      StringUtils.formatDateDisplay(
                                        vaccination.vaccinationDate,
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
                                          Icons.vaccines,
                                          color: Constants.kPrimaryColor,
                                        ),
                                      ),
                                      title: Text(
                                        vaccination.name, // Vaccine name
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Flock: $flockName'),
                                          Text('Date: $vaccinationDateDisplay'),
                                          if (vaccination.notes != null &&
                                              vaccination.notes!.isNotEmpty)
                                            Text('Notes: ${vaccination.notes}'),
                                        ],
                                      ),
                                      trailing: const Icon(
                                        Icons.edit,
                                        color: Colors.grey,
                                      ),
                                      onTap:
                                          () => _showAddEditVaccinationDialog(
                                            vaccinationToEdit: vaccination,
                                          ),
                                    ),
                                  );
                                },
                              ),
                    ),
                    const Padding(padding: EdgeInsets.only(bottom: 100)),
                  ],
                ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _flocks.isEmpty
            // Disable FAB if no flocks available to link
            ? () => SystemUtils.showEmptyFlocksWarning(context)
            : () => _showAddEditVaccinationDialog(vaccinationToEdit: null),
        backgroundColor: Constants.kPrimaryColor,
        foregroundColor: Colors.white,
        tooltip: 'Add Vaccination Log',
        child: const Icon(Icons.add),
      ),
    );
  }
}
