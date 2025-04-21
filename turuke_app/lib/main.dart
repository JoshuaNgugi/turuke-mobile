import 'package:flutter/material.dart';
import 'package:turuke_app/screens/home.dart';
import 'package:turuke_app/screens/login.dart';
import 'package:turuke_app/screens/splash.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Turuke',
      initialRoute: SplashScreen.routeName,
      routes: {
        HomeScreen.routeName: (context) => HomeScreen(),
        SplashScreen.routeName: (context) => SplashScreen(),
        LoginScreen.routeName: (context) => LoginScreen(),
      },
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Hello World!'))),
    );
  }
}
