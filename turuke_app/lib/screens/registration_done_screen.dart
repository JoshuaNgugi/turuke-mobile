import 'dart:async';

import 'package:flutter/material.dart';
import 'package:turuke_app/screens/home_screen.dart';

class RegistrationDoneScreen extends StatefulWidget {
  static const String routeName = '/done';
  const RegistrationDoneScreen({super.key});

  @override
  State<RegistrationDoneScreen> createState() => _RegistrationDoneScreenState();
}

class _RegistrationDoneScreenState extends State<RegistrationDoneScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, HomeScreen.routeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 100, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Registration Successful!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  () => Navigator.pushReplacementNamed(
                    context,
                    HomeScreen.routeName,
                  ),
              child: Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
