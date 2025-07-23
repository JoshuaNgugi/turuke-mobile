import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/providers/home_provider.dart';
import 'package:turuke_app/screens/add_edit_mortality_screen.dart';
import 'package:turuke_app/screens/add_user_screen.dart';
import 'package:turuke_app/screens/change_password_screen.dart';
import 'package:turuke_app/screens/disease_log_screen.dart';
import 'package:turuke_app/screens/egg_collection_list_screen.dart';
import 'package:turuke_app/screens/egg_collection_screen.dart';
import 'package:turuke_app/screens/flock_management_screen.dart';
import 'package:turuke_app/screens/home_screen.dart';
import 'package:turuke_app/screens/login_screen.dart';
import 'package:turuke_app/screens/mortality_list_screen.dart';
import 'package:turuke_app/screens/registration_done_screen.dart';
import 'package:turuke_app/screens/registration_screen.dart';
import 'package:turuke_app/screens/settings_screen.dart';
import 'package:turuke_app/screens/splash_screen.dart';
import 'package:turuke_app/screens/user_management_screen.dart';
import 'package:turuke_app/screens/vaccination_log_screen.dart';
import 'package:turuke_app/screens/verify_email_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, HomeProvider>(
          create:
              (context) => HomeProvider(
                Provider.of<AuthProvider>(context, listen: false),
              ),
          update: (context, auth, previousHome) => HomeProvider(auth),
        ),
      ],
      child: const TurukeApp(),
    ),
  );
}

class TurukeApp extends StatefulWidget {
  const TurukeApp({super.key});

  @override
  _TurukeAppState createState() => _TurukeAppState();
}

class _TurukeAppState extends State<TurukeApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Turuke',
      theme: ThemeData(primarySwatch: Colors.purple),
      initialRoute: SplashScreen.routeName,
      routes: {
        HomeScreen.routeName: (ctx) => const HomeScreen(),
        SplashScreen.routeName: (ctx) => const SplashScreen(),
        LoginScreen.routeName: (ctx) => const LoginScreen(),
        RegistrationScreen.routeName: (ctx) => const RegistrationScreen(),
        VerifyEmailScreen.routeName: (ctx) => const VerifyEmailScreen(),
        RegistrationDoneScreen.routeName:
            (ctx) => const RegistrationDoneScreen(),
        EggCollectionScreen.routeName: (ctx) => const EggCollectionScreen(),
        FlockManagementScreen.routeName: (ctx) => const FlockManagementScreen(),
        VaccinationLogScreen.routeName: (ctx) => const VaccinationLogScreen(),
        DiseaseLogScreen.routeName: (ctx) => const DiseaseLogScreen(),
        EggCollectionListScreen.routeName:
            (ctx) => const EggCollectionListScreen(),
        UserManagementScreen.routeName: (ctx) => const UserManagementScreen(),
        AddUserScreen.routeName: (ctx) => const AddUserScreen(),
        ChangePasswordScreen.routeName: (ctx) => const ChangePasswordScreen(),
        MortalityListScreen.routeName: (ctx) => const MortalityListScreen(),
        AddEditMortalityScreen.routeName:
            (ctx) => const AddEditMortalityScreen(),
        SettingsScreen.routeName: (ctx) => const SettingsScreen(),
      },
    );
  }
}
