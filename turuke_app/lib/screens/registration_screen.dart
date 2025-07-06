import 'package:flutter/material.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/models/user.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/home_screen.dart';
import 'package:provider/provider.dart';

class RegistrationScreen extends StatefulWidget {
  static const String routeName = '/register';

  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  String _firstName = '',
      _lastName = '',
      _email = '',
      _farmName = '',
      _password = '';
  bool _termsAccepted = false;
  bool _isLoading = false;
  String? _error;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _farmNameController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _farmNameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    User _user = User(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      farmName: _farmNameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      role:
          UserRole.VIEWER, // TODO: fix this. Registering user cannot be viewer
    );
    if (!_termsAccepted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please accept Terms of Service')));
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().register(user: _user);
      Navigator.pushNamed(context, HomeScreen.routeName);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(labelText: 'First Name'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onChanged: (value) => _firstName = value,
                  ),
                  SizedBox(width: 16),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(labelText: 'Last Name'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onChanged: (value) => _lastName = value,
                  ),
                ],
              ),
              SizedBox(height: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onChanged: (value) => _email = value,
                  ),
                  SizedBox(width: 16),
                  TextFormField(
                    controller: _farmNameController,
                    decoration: InputDecoration(labelText: 'Farm Name'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onChanged: (value) => _farmName = value,
                  ),
                ],
              ),
              SizedBox(height: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onChanged: (value) => _password = value,
                  ),
                  SizedBox(width: 16),
                  CheckboxListTile(
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text('Accept Terms of Service'),
                    value: _termsAccepted,
                    onChanged:
                        (value) => setState(() => _termsAccepted = value!),
                  ),
                ],
              ),
              SizedBox(height: 16),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                        onPressed: _register,
                        child: const Text('Register'),
                      ),
                  SizedBox(width: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
