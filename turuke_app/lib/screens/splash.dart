import 'dart:async';
import 'package:flutter/material.dart';
import 'package:turuke_app/screens/home.dart';
import 'package:turuke_app/screens/login.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = '/splash';

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () async {
      // final prefs = await SharedPreferences.getInstance();
      // final token = prefs.getString('token');
      final token = null;
      Navigator.pushReplacementNamed(
        context,
        token != null ? HomeScreen.routeName : LoginScreen.routeName,
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
