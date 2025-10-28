import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/src/response.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/models/flock.dart';
import 'package:turuke_app/models/mortality.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/utils/http_client.dart';
import 'package:turuke_app/utils/system_utils.dart';

var logger = Logger(printer: PrettyPrinter());

class FlockManagementScreen extends StatefulWidget {
  static const String routeName = '/flock-management';

  const FlockManagementScreen({super.key});

  @override
  State<FlockManagementScreen> createState() => _FlockManagementScreenState();
}

class _FlockManagementScreenState extends State<FlockManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final DateFormat _dateFormat = DateFormat('d MMMM, y');

  int? _flockId;
  DateTime _recordedDate = DateTime.now();
  Flock? _flockToEdit;

  late TextEditingController _nameController;
  late TextEditingController _initialCountController;
  late TextEditingController _currentCountController;

  String _flockName = '';
  DateTime _arrivalDate = DateTime.now();
  int _initialCount = 0;
  int _currentCount = 0;
  int _status = 1;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _initialCountController = TextEditingController();
    _currentCountController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_flockToEdit == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args.containsKey('flock')) {
        _flockToEdit = args['flock'] as Flock;
        _populateFields(_flockToEdit!);
      } else {
        //_recordedDateController.text = _dateFormat.format(_recordedDate);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentCountController.dispose();
    _initialCountController.dispose();
    super.dispose();
  }

  void _populateFields(Flock flock) {
    _recordedDate = _dateFormat.parse(flock.arrivalDate);
    _flockName = flock.name;
    _currentCount = flock.currentCount;
    _initialCount = flock.initialCount;

    _nameController.text = _dateFormat.format(_recordedDate);
    _currentCountController.text = _currentCount.toString();
    _initialCountController.text = _initialCount.toString();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final farmId = authProvider.user?.farmId;

    if (farmId == null) {
      SystemUtils.showSnackBar(context, 'Farm ID not available. Cannot save.');
      return;
    }

    final flock = Flock(
      farmId: farmId,
      name: _flockName,
      arrivalDate: _dateFormat.format(_arrivalDate),
      initialCount: _initialCount,
      currentCount: _currentCount,
      status: _status,
    );

    try {
      Response response;
      if (_flockToEdit != null && _flockToEdit?.id != null) {
        response = await HttpClient.patch(
          Uri.parse(
            '${Constants.LAYERS_API_BASE_URL}/flocks/${_flockToEdit?.id}',
          ),
          headers: await authProvider.getHeaders(),
          body: jsonEncode(flock.toJson()),
        );
        if (response.statusCode == 200) {
          if (!mounted) return;
          SystemUtils.showSnackBar(context, 'Flock updated successfully!');
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
          if (!mounted) return;
          SystemUtils.showSnackBar(context, 'Flock added successfully!');
        } else {
          throw Exception('Failed to add flock: ${response.body}');
        }
      }
    } catch (e) {
      logger.e('Error saving/updating flock online: $e.');
      if (mounted) {
        SystemUtils.showSnackBar(
          context,
          'Failed to save flock. Please try again.',
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
          _flockToEdit != null ? 'Edit Flock' : 'Add Flock',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Constants.kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Name', ''),
                validator:
                    (value) => value!.isEmpty ? 'Name is required' : null,
                onChanged: (value) => _flockName = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: _inputDecoration('Arrival Date', ''),
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
                              foregroundColor: Constants.kPrimaryColor,
                            ),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null && context.mounted) {
                    setState(() {
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
                controller: _initialCountController,
                decoration: _inputDecoration('Initial Count', ''),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 0) {
                    return 'Enter valid number';
                  }
                  return null;
                },
                onChanged: (value) => _initialCount = int.tryParse(value) ?? 0,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currentCountController,
                decoration: _inputDecoration('Current Count', ''),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 0) {
                    return 'Enter valid number';
                  }
                  return null;
                },
                onChanged: (value) => _currentCount = int.tryParse(value) ?? 0,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                decoration: _inputDecoration('Status', ''),
                value: _status,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Active')),
                  DropdownMenuItem(value: 0, child: Text('Inactive')),
                ],
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _status = newValue;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
