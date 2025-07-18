import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/models/user.dart';
import 'package:turuke_app/providers/auth_provider.dart';

class AddUserScreen extends StatefulWidget {
  static final String routeName = '/add-user';

  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  String? _error;
  bool _isObscured = true;
  User? _user;
  bool _isEditing = false;
  bool _isSelfEditing = false;
  int _currentUserRole = UserRole.VIEWER;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['user'] != null) {
        setState(() {
          _user = args['user'];
          _isEditing = true;
          _firstNameController.text = _user!.firstName ?? '';
          _lastNameController.text = _user!.lastName ?? '';
          _emailController.text = _user!.email;
          _currentUserRole = _user!.role;
        });
      }
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

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final headers = await authProvider.getHeaders();
    final farmId = authProvider.user!.farmId;

    try {
      final response = await http.post(
        Uri.parse('${Constants.USERS_API_BASE_URL}/users'),
        headers: headers,
        body: jsonEncode({
          'first_name': _firstName,
          'last_name': _lastName,
          'email': _email,
          'farm_id': farmId,
          'role': _currentUserRole,
          'password': _password,
        }),
      );
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Successfully added user')));
      } else {
        setState(
          () =>
              _error =
                  jsonDecode(response.body)['error'] ?? 'Failed to add user',
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to add user')));
      }
    } catch (e) {
      setState(() => _error = 'Network error. User queued for sync.');
      // Save to sqflite for offline sync
      final db = await openDatabase(
        path.join(await getDatabasesPath(), 'turuke.db'),
      );
      await db.insert('users_pending', {
        'first_name': _firstName,
        'last_name': _lastName,
        'email': _email,
        'farm_id': farmId,
        'role': _currentUserRole,
        'password': _password,
        'created_at': DateTime.now().toIso8601String(),
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    _currentUserRole = authProvider.user!.role;
    if (_currentUserRole != UserRole.ADMIN &&
        _currentUserRole != UserRole.MANAGER) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add User')),
        body: const Center(
          child: Text('Your account is not authorized to add users'),
        ),
      );
    }
    if (_user != null) {
      _isSelfEditing = _user!.id == authProvider.user!.id!;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add User')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  onSaved: (value) => _firstName = value!,
                ),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  onSaved: (value) => _lastName = value!,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator:
                      (value) =>
                          value!.isEmpty || !value.contains('@')
                              ? 'Enter a valid email'
                              : null,
                  onSaved: (value) => _email = value!,
                ),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'Role',
                    enabled: _isSelfEditing, // Controls visual enabled state
                  ),
                  value: _currentUserRole,
                  items:
                      UserRole.allRoleValues.map((roleValue) {
                        return DropdownMenuItem<int>(
                          value: roleValue,
                          child: Text(UserRole.getString(roleValue)),
                        );
                      }).toList(),
                  onChanged:
                      _isSelfEditing
                          ? null
                          : (value) =>
                              setState(() => _currentUserRole = value!),
                  validator: (value) => value == null ? 'Required' : null,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                TextFormField(
                  obscureText: _isObscured,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscured ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscured = !_isObscured;
                        });
                      },
                    ),
                  ),
                  validator:
                      (value) =>
                          value!.isEmpty || value.length < 6
                              ? 'Minimum 6 characters'
                              : null,
                  onSaved: (value) => _password = value!,
                  enableSuggestions: false,
                  autocorrect: false,
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                      onPressed: _isEditing ? null : _saveUser,
                      child: const Text('Add User'),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
