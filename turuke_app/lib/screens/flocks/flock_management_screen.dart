import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/src/response.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/models/flock.dart';
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
  Flock? _flockToEdit;

  late TextEditingController _nameController;
  late TextEditingController _arrivalDateController;
  late TextEditingController _initialCountController;
  late TextEditingController _currentCountController;

  String _flockName = '';
  DateTime _arrivalDate = DateTime.now();
  int _initialCount = 0;
  int _currentCount = 0;
  int _status = 1;

  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _arrivalDateController = TextEditingController(
      text: _dateFormat.format(_arrivalDate),
    );
    _initialCountController = TextEditingController();
    _currentCountController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args.containsKey('flock')) {
        _flockToEdit = args['flock'] as Flock;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _populateFields(_flockToEdit!);
          _isInitialized = true;
        });
      } else {
        _isInitialized = true;
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
    _flockName = flock.name;
    _currentCount = flock.currentCount;
    _initialCount = flock.initialCount;
    _arrivalDate = _dateFormat.parse(flock.arrivalDate);

    _nameController.text = _flockName;
    _arrivalDateController.text = flock.arrivalDate;
    _currentCountController.text = _currentCount.toString();
    _initialCountController.text = _initialCount.toString();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 5));

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
          Navigator.of(context).pop(true);
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
          Navigator.of(context).pop(true);
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
    } finally {
      setState(() => _isLoading = false);
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
      body: Stack(
        children: [
          SingleChildScrollView(
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
                    onSaved: (value) => _flockName = value!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _arrivalDateController,
                    decoration: _inputDecoration(
                      'Arrival Date',
                      'The date this flock arrived',
                    ),
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
                          _arrivalDateController.text = _dateFormat.format(
                            picked,
                          );
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _initialCountController,
                    decoration: _inputDecoration(
                      'Initial Count',
                      'The initial number of chicks that arrived',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Initial Count is required';
                      }
                      if (int.tryParse(value) == null || int.parse(value) < 0) {
                        return 'Must be a valid whole number';
                      }
                      return null;
                    },
                    onSaved:
                        (value) => _initialCount = int.tryParse(value!) ?? 0,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _currentCountController,
                    decoration: _inputDecoration(
                      'Current Count',
                      'The current number of chicken in this flock',
                    ),
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
                    onSaved:
                        (value) => _currentCount = int.tryParse(value!) ?? 0,
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
                        _flockToEdit != null ? 'Update Flock' : 'Add Flock',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              constraints: const BoxConstraints.expand(),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Constants.kPrimaryColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
