import 'dart:math';

import 'package:flutter/material.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/home.dart';
import 'package:turuke_app/screens/registration.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

var logger = Logger(printer: PrettyPrinter());

class LoginScreen extends StatefulWidget {
  static const String routeName = '/log-in';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '', _password = '';
  bool _isLoading = false;
  bool _isObscured = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    try {
      await context.read<AuthProvider>().login(_email, _password);
      Navigator.pushReplacementNamed(context, HomeScreen.routeName);
    } catch (e) {
      logger.e(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign In')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty ? 'Email required' : null,
                onChanged: (value) => _email = value,
              ),
              SizedBox(height: 16),
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
                    (value) => value!.isEmpty ? 'Password required' : null,
                onChanged: (value) => _password = value,
                enableSuggestions: false,
                autocorrect: false,
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _login,
                    child: const Text('Sign In'),
                  ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? "),
                  TextButton(
                    onPressed:
                        () => Navigator.pushNamed(
                          context,
                          RegistrationScreen.routeName,
                        ),
                    child: Text('Create one'),
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
