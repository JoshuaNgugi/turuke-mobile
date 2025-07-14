import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/home_screen.dart';
import 'package:turuke_app/screens/login_screen.dart';
import 'package:turuke_app/sync.dart';

var logger = Logger();

class SplashScreen extends StatefulWidget {
  static const String routeName = '/splash';

  const SplashScreen({super.key});

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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 1. Load authentication data
    await authProvider.loadFromPrefs();

    // 2. Initialize database
    final db = await initDatabase(); // Make sure initDatabase is awaited

    // 3. Perform data synchronization
    // Consider adding error handling or UI feedback for sync
    await syncPendingData(context, db);

    // 4. Determine initial route based on authentication status
    if (authProvider.token != null &&
        authProvider.user != null &&
        !authProvider.isTokenExpired) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
      }
    } else {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
      }
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
