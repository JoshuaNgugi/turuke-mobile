import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/providers/home_provider.dart';
import 'package:turuke_app/screens/mortality/add_edit_mortality_screen.dart';
import 'package:turuke_app/screens/users/add_user_screen.dart';
import 'package:turuke_app/screens/settings/change_password_screen.dart';
import 'package:turuke_app/screens/diseases/disease_log_screen.dart';
import 'package:turuke_app/screens/egg_collection/egg_collection_list_screen.dart';
import 'package:turuke_app/screens/egg_collection/egg_collection_screen.dart';
import 'package:turuke_app/screens/flocks/flock_management_screen.dart';
import 'package:turuke_app/screens/home_screen.dart';
import 'package:turuke_app/screens/login/login_screen.dart';
import 'package:turuke_app/screens/mortality/mortality_list_screen.dart';
import 'package:turuke_app/screens/registration/registration_done_screen.dart';
import 'package:turuke_app/screens/registration/registration_screen.dart';
import 'package:turuke_app/screens/settings/settings_screen.dart';
import 'package:turuke_app/screens/splash/splash_screen.dart';
import 'package:turuke_app/screens/users/user_management_screen.dart';
import 'package:turuke_app/screens/vaccinations/vaccination_log_screen.dart';
import 'package:turuke_app/screens/registration/verify_email_screen.dart';

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
  TurukeAppState createState() => TurukeAppState();
}

class TurukeAppState extends State<TurukeApp> {
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
