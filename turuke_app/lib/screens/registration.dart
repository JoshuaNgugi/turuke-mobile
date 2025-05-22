import 'package:flutter/material.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/home.dart';
import 'package:turuke_app/screens/verify_email.dart';
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

  Future<void> _register() async {
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
      await context.read<AuthProvider>().register(
        firstName: _firstName,
        lastName: _lastName,
        email: _email,
        farmName: _farmName,
        password: _password,
      );
      Navigator.pushNamed(context, VerifyEmailScreen.routeName);
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
                    decoration: InputDecoration(labelText: 'First Name'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onChanged: (value) => _firstName = value,
                  ),
                  SizedBox(width: 16),
                  TextFormField(
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
                    decoration: InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onChanged: (value) => _email = value,
                  ),
                  SizedBox(width: 16),
                  TextFormField(
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
