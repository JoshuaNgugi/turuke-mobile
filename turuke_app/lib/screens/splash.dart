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
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Load auth state
    await Provider.of<AuthProvider>(context, listen: false).loadFromPrefs();

    // Wait for 2 seconds to show splash
    Timer(const Duration(seconds: 2), () {
      // Navigate based on auth state
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      Navigator.pushReplacementNamed(
        context,
        authProvider.token != null
            ? HomeScreen.routeName
            : LoginScreen.routeName,
      );
    });
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
          ],
        ),
      ),
    );
  }
}
