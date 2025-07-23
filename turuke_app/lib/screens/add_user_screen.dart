import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/models/user.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/utils/system_utils.dart';

var logger = Logger(printer: PrettyPrinter());

class AddUserScreen extends StatefulWidget {
  static const String routeName = '/add-user';

  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isObscured = true;
  User? _userToEdit;
  bool _isEditing = false;
  bool _isSelfEditing = false;
  int _selectedRole = UserRole.VIEWER;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['user'] != null) {
        _userToEdit = args['user'];
        _isEditing = true;
        _firstNameController.text = _userToEdit!.firstName ?? '';
        _lastNameController.text = _userToEdit!.lastName ?? '';
        _emailController.text = _userToEdit!.email;
        _selectedRole = _userToEdit!.role;

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        _isSelfEditing = authProvider.user?.id == _userToEdit!.id;
      } else {
        _selectedRole = UserRole.VIEWER;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(
    String labelText, {
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return InputDecoration(
      labelText: labelText,
      border: const OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Constants.kPrimaryColor, width: 2.0),
      ),
      enabledBorder:
          enabled
              ? const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              )
              : OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
      labelStyle: TextStyle(color: Constants.kPrimaryColor),
      suffixIcon: suffixIcon,
      fillColor: enabled ? Colors.white : Colors.grey.shade100,
      filled: true,
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      SystemUtils.showSnackBar(
        context,
        'Please correct the errors in the form.',
      );
      return;
    }
    _formKey.currentState!.save();

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final headers = await authProvider.getHeaders();
    final farmId = authProvider.user?.farmId;

    if (farmId == null) {
      if (mounted) {
        SystemUtils.showSnackBar(
          context,
          'Farm ID not available. Cannot save user.',
        );
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    User user = User(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      farmId: farmId,
      role: _selectedRole,
      password:
          !_isEditing || _passwordController.text.isNotEmpty
              ? _passwordController.text
              : null,
    );

    http.Response response;
    String successMessage;
    String errorMessagePrefix;

    try {
      if (_isEditing) {
        successMessage = 'User updated successfully!';
        errorMessagePrefix = 'Failed to update user';
        response = await http.put(
          Uri.parse('${Constants.USERS_API_BASE_URL}/users/${_userToEdit!.id}'),
          headers: headers,
          body: jsonEncode(user.toJson()),
        );
      } else {
        successMessage = 'User added successfully!';
        errorMessagePrefix = 'Failed to add user';
        response = await http.post(
          Uri.parse('${Constants.USERS_API_BASE_URL}/users'),
          headers: headers,
          body: jsonEncode(user.toJson()),
        );
      }

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        SystemUtils.showSnackBar(context, successMessage);
        if (!_isEditing) {
          _firstNameController.clear();
          _lastNameController.clear();
          _emailController.clear();
          _passwordController.clear();
          setState(() {
            _selectedRole = UserRole.VIEWER;
          });
        }
        Navigator.of(context).pop();
      } else {
        String serverMessage = 'Server error (${response.statusCode})';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            serverMessage = errorBody['message'];
          }
        } catch (jsonError) {
          logger.e(
            'Failed to parse error response body: $jsonError. Raw body: ${response.body}',
          );
        }
        SystemUtils.showSnackBar(
          context,
          '$errorMessagePrefix: $serverMessage',
        );
        logger.e(
          '$errorMessagePrefix: ${response.statusCode} - $serverMessage',
        );
      }
    } catch (e) {
      logger.e('Network error during user save/update: $e');
      if (mounted) {
        SystemUtils.showSnackBar(
          context,
          'Network error. Please check your internet connection.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validatePassword(String? value) {
    if (!_isEditing || value!.isNotEmpty) {
      // Required for new user or if entered for existing
      if (value == null || value.isEmpty) {
        return 'Password is required';
      }
      if (value.length < 8) {
        return 'Password must be at least 8 characters long';
      }
      // if (!value.contains(RegExp(r'[A-Z]'))) {
      //   return 'Password must contain at least one uppercase letter';
      // }
      // if (!value.contains(RegExp(r'[a-z]'))) {
      //   return 'Password must contain at least one lowercase letter';
      // }
      // if (!value.contains(RegExp(r'[0-9]'))) {
      //   return 'Password must contain at least one digit';
      // }
      // if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      //   return 'Password must contain at least one special character';
      // }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final authenticatedUserRole = authProvider.user?.role ?? UserRole.VIEWER;

    if (authenticatedUserRole != UserRole.ADMIN &&
        authenticatedUserRole != UserRole.MANAGER) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'User Management',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Constants.kPrimaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Access Denied',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your account is not authorized to add or edit users.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Only admin/manager can change roles, and they can't change their own role
    final bool canChangeRole =
        (authenticatedUserRole == UserRole.ADMIN ||
            authenticatedUserRole == UserRole.MANAGER) &&
        !_isSelfEditing;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit User' : 'Add User',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Constants.kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _firstNameController,
                      decoration: _inputDecoration('First Name'),
                      validator:
                          (value) =>
                              value!.trim().isEmpty
                                  ? 'First Name is required'
                                  : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: _inputDecoration('Last Name'),
                      validator:
                          (value) =>
                              value!.trim().isEmpty
                                  ? 'Last Name is required'
                                  : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration(
                        'Email',
                        enabled: !_isEditing,
                      ), // Email usually not editable when editing
                      keyboardType: TextInputType.emailAddress,
                      validator:
                          (value) =>
                              value!.trim().isEmpty || !value.contains('@')
                                  ? 'Enter a valid email'
                                  : null,
                      enabled: !_isEditing, // Disable email editing
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      decoration: _inputDecoration(
                        'Role',
                        enabled: canChangeRole,
                      ),
                      value: _selectedRole,
                      items:
                          UserRole.allRoleValues.map((roleValue) {
                            return DropdownMenuItem<int>(
                              value: roleValue,
                              child: Text(UserRole.getString(roleValue)),
                            );
                          }).toList(),
                      onChanged:
                          canChangeRole
                              ? (value) =>
                                  setState(() => _selectedRole = value!)
                              : null, // Disable based on canChangeRole
                      validator:
                          (value) => value == null ? 'Role is required' : null,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _isObscured,
                      decoration: _inputDecoration(
                        _isEditing ? 'New Password (optional)' : 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isObscured
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Constants.kPrimaryColor.withOpacity(0.7),
                          ),
                          onPressed: () {
                            setState(() {
                              _isObscured = !_isObscured;
                            });
                          },
                        ),
                      ),
                      validator: _validatePassword,
                      enableSuggestions: false,
                      autocorrect: false,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.kPrimaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14.0,
                          horizontal: 24.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        elevation: 3,
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                _isEditing ? 'Save Changes' : 'Add User',
                                style: const TextStyle(fontSize: 18.0),
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Constants.kAccentColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
