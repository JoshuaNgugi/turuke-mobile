import 'package:flutter/material.dart';
import 'package:turuke_app/screens/home.dart';
import 'package:turuke_app/screens/registration.dart';

class LoginScreen extends StatefulWidget {
  static const String routeName = '/log-in';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '', _password = '';

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      try {
        // TODO
        Navigator.pushNamed(context, HomeScreen.routeName);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator:
                    (value) => value!.isEmpty ? 'Password required' : null,
                onChanged: (value) => _password = value,
              ),
              SizedBox(height: 24),
              ElevatedButton(onPressed: _signIn, child: Text('Sign In')),
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
