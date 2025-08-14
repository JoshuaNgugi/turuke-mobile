import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/models/flock.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/navigation_drawer_screen.dart';
import 'package:turuke_app/utils/http_client.dart';
import 'package:turuke_app/utils/string_utils.dart';
import 'package:turuke_app/utils/system_utils.dart';
import 'package:uuid/uuid.dart';

var logger = Logger(printer: PrettyPrinter());

class FlockManagementScreen extends StatefulWidget {
  static const String routeName = '/flock-management';

  const FlockManagementScreen({super.key});

  @override
  State<FlockManagementScreen> createState() => _FlockManagementScreenState();
}

class _FlockManagementScreenState extends State<FlockManagementScreen> {
  List<Flock> _flocks = [];
  bool _isLoading = true;
  final DateFormat _dateFormat = DateFormat('d MMMM, y');

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
    });
    await _fetchFlocks();
    if (mounted) {
      setState(() => _isLoading = false);
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
      if (mounted) {
        if (response.statusCode == 200) {
          final List<dynamic> jsonList = jsonDecode(response.body);
          List<Flock> fetchedFlocks =
              jsonList.map((json) => Flock.fromJson(json)).toList();

          setState(() {
            _flocks = fetchedFlocks;
          });
        } else {
          logger.w('Failed to fetch flocks (${response.statusCode}).');
        }
      }
    } catch (e) {
      logger.e('Error fetching flocks: $e.');
      if (mounted) {
        SystemUtils.showSnackBar(context, 'Failed to fetch flocks.');
      }
    }
  }

  void _onRouteSelected(String route) {
    Navigator.pushNamed(context, route);
  }

  Future<void> _showAddEditFlockDialog({Flock? flockToEdit}) async {
    final formKey = GlobalKey<FormState>();
    String _flockName = flockToEdit?.name ?? '';
    int _initialCount = flockToEdit?.initialCount ?? 0;
    int _currentCount = flockToEdit?.currentCount ?? 0;
    DateTime _arrivalDate =
        flockToEdit != null
            ? _dateFormat.parse(flockToEdit.arrivalDate)
            : DateTime.now();
    int _status = flockToEdit?.status ?? 1;

    final TextEditingController nameController = TextEditingController(
      text: _flockName,
    );
    final TextEditingController initialCountController = TextEditingController(
      text: _initialCount.toString(),
    );
    final TextEditingController currentCountController = TextEditingController(
      text: _currentCount.toString(),
    );

    try {
      final result = await showDialog<bool>(
        context: context,
        builder:
            (context) => StatefulBuilder(
              builder: (BuildContext context, StateSetter setStateInDialog) {
                return AlertDialog(
                  title: Text(flockToEdit != null ? 'Edit Flock' : 'Add Flock'),
                  content: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: nameController,
                            decoration: _inputDecoration('Name'),
                            validator:
                                (value) =>
                                    value!.isEmpty ? 'Name is required' : null,
                            onChanged: (value) => _flockName = value,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: _inputDecoration('Arrival Date'),
                            readOnly: true,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _arrivalDate,
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
                              if (picked != null && context.mounted) {
                                setStateInDialog(() {
                                  _arrivalDate = picked;
                                });
                              }
                            },
                            controller: TextEditingController(
                              text: _dateFormat.format(_arrivalDate),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: initialCountController,
                            decoration: _inputDecoration('Initial Count'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (int.tryParse(value) == null ||
                                  int.parse(value)! < 0) {
                                return 'Enter valid number';
                              }
                              return null;
                            },
                            onChanged:
                                (value) =>
                                    _initialCount = int.tryParse(value) ?? 0,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: currentCountController,
                            decoration: _inputDecoration('Current Count'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (int.tryParse(value) == null ||
                                  int.parse(value) < 0) {
                                return 'Enter valid number';
                              }
                              return null;
                            },
                            onChanged:
                                (value) =>
                                    _currentCount = int.tryParse(value) ?? 0,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            decoration: _inputDecoration('Status'),
                            value: _status,
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('Active')),
                              DropdownMenuItem(
                                value: 0,
                                child: Text('Inactive'),
                              ),
                            ],
                            onChanged: (newValue) {
                              if (newValue != null) {
                                setStateInDialog(() {
                                  _status = newValue;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          () => Navigator.pop(
                            context,
                            false,
                          ), // Return false on cancel
                      style: TextButton.styleFrom(
                        foregroundColor: Constants.kPrimaryColor,
                      ),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          // Return true to indicate save success
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
            ),
      );

      if (result == true) {
        await _saveFlock(
          flockName: _flockName,
          initialCount: _initialCount,
          currentCount: _currentCount,
          arrivalDate: _arrivalDate,
          status: _status,
          flockId:
              (flockToEdit != null && flockToEdit.id != null)
                  ? flockToEdit.id
                  : null,
        );
      }
    } finally {
      nameController.dispose();
      initialCountController.dispose();
      currentCountController.dispose();
    }
  }

  Future<void> _saveFlock({
    required String flockName,
    required int initialCount,
    required int currentCount,
    required DateTime arrivalDate,
    required int status,
    int? flockId,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final farmId = authProvider.user?.farmId;

    if (farmId == null) {
      SystemUtils.showSnackBar(context, 'Farm ID not available. Cannot save.');
      return;
    }

    final flock = Flock(
      farmId: farmId,
      name: flockName,
      arrivalDate: _dateFormat.format(arrivalDate),
      initialCount: initialCount,
      currentCount: currentCount,
      status: status,
    );

    try {
      var response;
      if (flockId != null) {
        response = await HttpClient.patch(
          Uri.parse('${Constants.LAYERS_API_BASE_URL}/flocks/$flockId'),
          headers: await authProvider.getHeaders(),
          body: jsonEncode(flock.toJson()),
        );
        if (response.statusCode == 200) {
          SystemUtils.showSnackBar(context, 'Flock updated successfully!');
          await _fetchFlocks();
        } else {
          throw Exception('Failed to update flock: ${response.body}');
        }
      } else {
        response = await HttpClient.post(
          Uri.parse('${Constants.LAYERS_API_BASE_URL}/flocks'),
          headers: await authProvider.getHeaders(),
          body: jsonEncode(flock.toJson()),
        );
        if (response.statusCode == 201) {
          SystemUtils.showSnackBar(context, 'Flock added successfully!');
          await _fetchFlocks();
        } else {
          throw Exception('Failed to add flock: ${response.body}');
        }
      }
    } catch (e) {
      logger.e('Error saving/updating flock online: $e.');
    }
  }

  Future<void> _showDeleteFlockDialog(Flock flock) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Flock?'),
            content: Text(
              'Are you sure you want to delete flock "${flock.name}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (shouldDelete == true) {
      await _deleteFlock(flock.id!);
    }
  }

  Future<void> _deleteFlock(int flockId) async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await HttpClient.delete(
        Uri.parse('${Constants.LAYERS_API_BASE_URL}/flocks/$flockId'),
        headers: await authProvider.getHeaders(),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          SystemUtils.showSnackBar(
            context,
            'Flock deleted successfully!',
          ); // Refresh the list after successful deletion
          await _fetchFlocks();
        } else {
          SystemUtils.showSnackBar(context, 'Failed to delete flock.');
          logger.e('Failed to delete flock: ${response.body}');
        }
      }
    } catch (e) {
      logger.e('Error deleting flock: $e');
      if (mounted) {
        SystemUtils.showSnackBar(
          context,
          'Network error. Failed to delete flock.',
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.user?.role;
    final canModifyFlock =
        userRole == UserRole.ADMIN || userRole == UserRole.MANAGER;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Flock Management',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Constants.kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: AppNavigationDrawer(
        selectedRoute: FlockManagementScreen.routeName,
        onRouteSelected: _onRouteSelected,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchFlocks,
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
                          _flocks.isEmpty
                              ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'No flocks found. Tap the + button to add one.',
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
                                itemCount: _flocks.length,
                                itemBuilder: (context, index) {
                                  Flock flock = _flocks[index];
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
                                          Icons.pets,
                                          color: Constants.kPrimaryColor,
                                        ),
                                      ),
                                      title: Text(
                                        flock.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Arrival: ${StringUtils.formatDateDisplay(flock.arrivalDate)}',
                                          ),
                                          Text(
                                            'Initial: ${flock.initialCount}, Current: ${flock.currentCount}',
                                          ),
                                          Text('Age: ${flock.ageWeeks} weeks'),
                                          Text(
                                            'Status: ${flock.status == 1 ? 'Active' : 'Inactive'}',
                                            style: TextStyle(
                                              color:
                                                  flock.status == 1
                                                      ? Colors.green
                                                      : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing:
                                          canModifyFlock
                                              ? Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      color: Colors.grey,
                                                    ),
                                                    onPressed:
                                                        () =>
                                                            _showAddEditFlockDialog(
                                                              flockToEdit:
                                                                  flock,
                                                            ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                    onPressed:
                                                        () =>
                                                            _showDeleteFlockDialog(
                                                              flock,
                                                            ),
                                                  ),
                                                ],
                                              )
                                              : const Icon(
                                                Icons.arrow_forward_ios,
                                                color: Colors.grey,
                                              ),
                                      onTap:
                                          canModifyFlock
                                              ? () => _showAddEditFlockDialog(
                                                flockToEdit: flock,
                                              )
                                              : null,
                                    ),
                                  );
                                },
                              ),
                    ),
                    Padding(padding: EdgeInsetsGeometry.only(bottom: 100)),
                  ],
                ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditFlockDialog(flockToEdit: null),
        backgroundColor: Constants.kPrimaryColor,
        foregroundColor: Colors.white,
        tooltip: 'Add New Flock',
        child: const Icon(Icons.add),
      ),
    );
  }
}
