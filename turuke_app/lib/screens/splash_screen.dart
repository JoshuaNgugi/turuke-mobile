import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/home_screen.dart';
import 'package:turuke_app/screens/login_screen.dart';
import 'package:turuke_app/sync.dart';

var logger = Logger(printer: PrettyPrinter());

class SplashScreen extends StatefulWidget {
  static const String routeName = '/splash';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final startTime = DateTime.now();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await authProvider.loadFromPrefs();

      final db = await initDatabase();

      await syncPendingData(context, db);
    } catch (e) {
      logger.e('Error during app initialization/sync: $e');
    }

    // Calculate elapsed time and wait if less than minimum splash duration
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    const minSplashDuration = Duration(
      seconds: 3,
    ); // Minimum 3 seconds for the splash screen

    if (duration < minSplashDuration) {
      await Future.delayed(minSplashDuration - duration);
    }

    // Determine initial route based on authentication status
    // Ensure context is still mounted before attempting navigation
    if (!mounted) return;

    if (authProvider.token != null &&
        authProvider.user != null &&
        !authProvider.isTokenExpired) {
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    } else {
      Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 226, 80, 255),
              Color.fromARGB(255, 103, 2, 121),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/big-chicken-withoutbg.png',
                height: size.height * 0.2, 
                width: size.height * 0.2,  
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              const Text(
                'Turuke',
                style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Jumpstart your farm's efficiency",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: size.height * 0.1),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 4,
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading...',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
