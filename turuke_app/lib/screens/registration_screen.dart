import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/models/user.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/login_screen.dart';
import 'package:url_launcher/url_launcher.dart';

var logger = Logger(printer: PrettyPrinter());

class RegistrationScreen extends StatefulWidget {
  static const String routeName = '/register';

  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _farmNameController = TextEditingController();
  final TapGestureRecognizer _tapGestureRecognizer = TapGestureRecognizer();

  bool _termsAccepted = false;
  bool _isLoading = false;
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _farmNameController.dispose();
    _tapGestureRecognizer.dispose();
    super.dispose();
  }

  Future<void> _launchURL() async {
    final Uri url = Uri.parse(Constants.TERMS_OF_SERVICE_URL);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch ${Constants.TERMS_OF_SERVICE_URL}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) return;
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please accept the Terms of Service to register.',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final User newUser = User(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        farmName: _farmNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: UserRole.ADMIN,
      );

      await context.read<AuthProvider>().register(user: newUser);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Registration successful! Please log in.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pushReplacementNamed(context, LoginScreen.routeName);
    } catch (e) {
      logger.e("Registration Error: $e");
      if (!mounted) return;

      String errorMessage =
          e.toString().contains('Exception:')
              ? e.toString().replaceFirst('Exception: ', '')
              : 'An unexpected error occurred during registration. Please try again.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Register Account',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 103, 2, 121),
              Color.fromARGB(255, 150, 50, 170),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: _firstNameController,
                              decoration: InputDecoration(
                                labelText: 'First Name',
                                hintText: 'Your first name',
                                prefixIcon: const Icon(
                                  Icons.person,
                                  color: Color.fromARGB(255, 103, 2, 121),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.purple.shade50,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 12,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'First name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                labelText: 'Last Name',
                                hintText: 'Your last name',
                                prefixIcon: const Icon(
                                  Icons.person_outline,
                                  color: Color.fromARGB(255, 103, 2, 121),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.purple.shade50,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 12,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Last name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'Your email address',
                                prefixIcon: const Icon(
                                  Icons.email,
                                  color: Color.fromARGB(255, 103, 2, 121),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.purple.shade50,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 12,
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Email is required';
                                }
                                if (!RegExp(
                                  r'^[^@]+@[^@]+\.[^@]+',
                                ).hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _farmNameController,
                              decoration: InputDecoration(
                                labelText: 'Farm Name',
                                hintText: 'Your farm\'s name',
                                prefixIcon: const Icon(
                                  Icons.home,
                                  color: Color.fromARGB(255, 103, 2, 121),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.purple.shade50,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 12,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Farm name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _isPasswordObscured,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Create a strong password',
                                prefixIcon: const Icon(
                                  Icons.lock,
                                  color: Color.fromARGB(255, 103, 2, 121),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordObscured
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordObscured =
                                          !_isPasswordObscured;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.purple.shade50,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 12,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password is required';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters long';
                                }
                                return null;
                              },
                              enableSuggestions: false,
                              autocorrect: false,
                            ),
                            const SizedBox(height: 24),
                            // Terms and Conditions Checkbox with clickable text
                            CheckboxListTile(
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text.rich(
                                TextSpan(
                                  text: 'I accept the ',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color,
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: 'Terms of Service',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Color.fromARGB(255, 103, 2, 121),
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      recognizer:
                                          _tapGestureRecognizer
                                            ..onTap = _launchURL,
                                    ),
                                  ],
                                ),
                              ),
                              value: _termsAccepted,
                              onChanged:
                                  (value) =>
                                      setState(() => _termsAccepted = value!),
                              activeColor: const Color.fromARGB(
                                255,
                                103,
                                2,
                                121,
                              ),
                              checkColor: Colors.white,
                            ),
                            const SizedBox(height: 24),
                            _isLoading
                                ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color.fromARGB(255, 103, 2, 121),
                                  ),
                                )
                                : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(
                                        255,
                                        103,
                                        2,
                                        121,
                                      ),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      elevation: 5,
                                      textStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    child: const Text('Register'),
                                  ),
                                ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color.fromARGB(
                                  255,
                                  103,
                                  2,
                                  121,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              child: const Text(
                                'Already have an account? Sign in',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
