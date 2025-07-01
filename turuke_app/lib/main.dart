import 'package:flutter/material.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/add_user_screen.dart';
import 'package:turuke_app/screens/change_password_screen.dart';
import 'package:turuke_app/screens/disease_log.dart';
import 'package:turuke_app/screens/egg_collection.dart';
import 'package:turuke_app/screens/egg_collection_list_screen.dart';
import 'package:turuke_app/screens/flock_management.dart';
import 'package:turuke_app/screens/home.dart';
import 'package:turuke_app/screens/login.dart';
import 'package:turuke_app/screens/registration.dart';
import 'package:turuke_app/screens/registration_done.dart';
import 'package:turuke_app/screens/splash.dart';
import 'package:turuke_app/screens/user_management_screen.dart';
import 'package:turuke_app/screens/vaccination_log.dart';
import 'package:turuke_app/screens/verify_email.dart';
import 'package:provider/provider.dart';
import 'package:turuke_app/sync.dart';

void main() {
  runApp(const TurukeApp());
}

class TurukeApp extends StatefulWidget {
  const TurukeApp({Key? key}) : super(key: key);

  @override
  _TurukeAppState createState() => _TurukeAppState();
}

class _TurukeAppState extends State<TurukeApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<AuthProvider>(context, listen: false).loadFromPrefs();
      final db = await initDatabase();
      await syncPendingData(context, db);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'Turuke',
        theme: ThemeData(primarySwatch: Colors.purple),
        initialRoute: SplashScreen.routeName,
        routes: {
          HomeScreen.routeName: (ctx) => HomeScreen(),
          SplashScreen.routeName: (ctx) => SplashScreen(),
          LoginScreen.routeName: (ctx) => LoginScreen(),
          RegistrationScreen.routeName: (ctx) => RegistrationScreen(),
          VerifyEmailScreen.routeName: (ctx) => VerifyEmailScreen(),
          RegistrationDoneScreen.routeName: (ctx) => RegistrationDoneScreen(),
          EggCollectionScreen.routeName: (ctx) => EggCollectionScreen(),
          FlockManagementScreen.routeName: (ctx) => FlockManagementScreen(),
          VaccinationLogScreen.routeName: (ctx) => VaccinationLogScreen(),
          DiseaseLogScreen.routeName: (ctx) => DiseaseLogScreen(),
          EggCollectionListScreen.routeName: (ctx) => EggCollectionListScreen(),
          UserManagementScreen.routeName: (ctx) => UserManagementScreen(),
          AddUserScreen.routeName: (ctx) => AddUserScreen(),
          ChangePasswordScreen.routeName: (ctx) => ChangePasswordScreen(),
        },
      ),
    );
  }
}
