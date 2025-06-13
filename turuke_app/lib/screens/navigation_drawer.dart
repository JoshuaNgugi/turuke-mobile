import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/disease_log.dart';
import 'package:turuke_app/screens/egg_collection.dart';
import 'package:turuke_app/screens/egg_collection_list_screen.dart';
import 'package:turuke_app/screens/flock_management.dart';
import 'package:turuke_app/screens/home.dart';
import 'package:turuke_app/screens/login.dart';
import 'package:turuke_app/screens/user_management_screen.dart';
import 'package:turuke_app/screens/vaccination_log.dart';

class AppNavigationDrawer extends StatelessWidget {
  final String selectedRoute;
  final Function(String) onRouteSelected;

  const AppNavigationDrawer({
    Key? key,
    required this.selectedRoute,
    required this.onRouteSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole =
        authProvider.user?.role ?? UserRole.VIEWER; // Default to Viewer
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.purple),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Turuke',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Farm Management',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.home,
              color:
                  selectedRoute == HomeScreen.routeName ? Colors.purple : null,
            ),
            title: Text('Home'),
            selected: selectedRoute == HomeScreen.routeName,
            onTap: () => onRouteSelected(HomeScreen.routeName),
          ),
          ListTile(
            leading: Icon(
              Icons.egg,
              color:
                  selectedRoute == EggCollectionScreen.routeName
                      ? Colors.purple
                      : null,
            ),
            title: Text('Egg Collection'),
            selected: selectedRoute == EggCollectionListScreen.routeName,
            onTap: () => onRouteSelected(EggCollectionListScreen.routeName),
          ),
          ListTile(
            leading: Icon(
              Icons.pets,
              color:
                  selectedRoute == FlockManagementScreen.routeName
                      ? Colors.purple
                      : null,
            ),
            title: Text('Flock Management'),
            selected: selectedRoute == FlockManagementScreen.routeName,
            onTap: () => onRouteSelected(FlockManagementScreen.routeName),
          ),
          ListTile(
            leading: Icon(
              Icons.vaccines,
              color:
                  selectedRoute == VaccinationLogScreen.routeName
                      ? Colors.purple
                      : null,
            ),
            title: Text('Vaccination Log'),
            selected: selectedRoute == VaccinationLogScreen.routeName,
            onTap: () => onRouteSelected(VaccinationLogScreen.routeName),
          ),
          ListTile(
            leading: Icon(
              Icons.sick,
              color:
                  selectedRoute == DiseaseLogScreen.routeName
                      ? Colors.purple
                      : null,
            ),
            title: Text('Disease Log'),
            selected: selectedRoute == DiseaseLogScreen.routeName,
            onTap: () => onRouteSelected(DiseaseLogScreen.routeName),
          ),
          if (userRole == 1 || userRole == 2) // Admin or Manager
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('User Management'),
              selected: selectedRoute == UserManagementScreen.routeName,
              onTap: () => onRouteSelected(UserManagementScreen.routeName),
            ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Logout'),
            onTap: () async {
              Navigator.pushNamedAndRemoveUntil(
                context,
                LoginScreen.routeName,
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
