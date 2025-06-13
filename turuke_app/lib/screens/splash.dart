import 'dart:async';
import 'package:flutter/material.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/home.dart';
import 'package:turuke_app/screens/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = '/splash';

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool loadSuccessful = false; // Flag to track success

    try {
      await authProvider.loadFromPrefs();
      loadSuccessful = true; // Set to true if loading succeeded
    } catch (e) {
      // Log the error for debugging
      print('Error loading authentication state from preferences: $e');
      // Optionally, set the token to null explicitly if your loadFromPrefs
      // might leave it in an indeterminate state on error.
      // authProvider.clearToken(); // If you have such a method
      // You might also want to show a toast/snackbar to the user
      // or set a flag to display a simple error on the splash screen itself.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Redirecting you to log in screen')),
      );
      await authProvider.logout();
    } finally {
      // Always wait for 2 seconds to show splash, regardless of load success
      Timer(const Duration(seconds: 2), () {
        // Ensure the widget is still mounted before attempting navigation
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          authProvider.token != null
              ? HomeScreen.routeName
              : LoginScreen.routeName,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/big-chicken.png',
              height: 100,
              width: 100,
            ),
            SizedBox(height: 16),
            Text(
              'Turuke',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            Text(
              "Jumpstart your farm's efficiency",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 87, 1, 102),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
