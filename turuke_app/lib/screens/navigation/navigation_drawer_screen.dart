import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/diseases/disease_log_screen.dart';
import 'package:turuke_app/screens/egg_collection/egg_collection_list_screen.dart';
import 'package:turuke_app/screens/flocks/flock_list_screen.dart';
import 'package:turuke_app/screens/home_screen.dart';
import 'package:turuke_app/screens/mortality/mortality_list_screen.dart';
import 'package:turuke_app/screens/settings/settings_screen.dart';
import 'package:turuke_app/screens/users/user_management_screen.dart';
import 'package:turuke_app/screens/vaccinations/vaccination_log_screen.dart';

class AppNavigationDrawer extends StatelessWidget {
  final String selectedRoute;
  final Function(String) onRouteSelected;

  const AppNavigationDrawer({
    super.key,
    required this.selectedRoute,
    required this.onRouteSelected,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final int? userRole = authProvider.user?.role;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(context, authProvider),

          // Home
          _buildDrawerItem(
            context,
            icon: Icons.home,
            title: 'Home',
            routeName: HomeScreen.routeName,
          ),
          // Egg Collection List
          _buildDrawerItem(
            context,
            icon: Icons.egg,
            title: 'Egg Collection',
            routeName: EggCollectionListScreen.routeName,
          ),
          // Flock Management
          _buildDrawerItem(
            context,
            icon: Icons.pets,
            title: 'Flock Management',
            routeName: FlockListScreen.routeName,
          ),
          // Vaccination Log
          _buildDrawerItem(
            context,
            icon: Icons.vaccines,
            title: 'Vaccination Log',
            routeName: VaccinationLogScreen.routeName,
          ),
          // Disease Log
          _buildDrawerItem(
            context,
            icon: Icons.sick,
            title: 'Disease Log',
            routeName: DiseaseLogScreen.routeName,
          ),
          // Mortality Log
          _buildDrawerItem(
            context,
            icon: Icons.dangerous,
            title: 'Mortality',
            routeName: MortalityListScreen.routeName,
          ),

          // User Management
          if (userRole == UserRole.ADMIN || userRole == UserRole.MANAGER)
            _buildDrawerItem(
              context,
              icon: Icons.people,
              title: 'User Management',
              routeName: UserManagementScreen.routeName,
            ),

          const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),

          // Settings
          _buildDrawerItem(
            context,
            icon: Icons.settings,
            title: 'Settings',
            routeName: SettingsScreen.routeName,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.only(left: 24.0, bottom: 16.0),
      decoration: const BoxDecoration(color: Constants.kPrimaryColor),
      height: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            authProvider.user!.farmNameOrDefault,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          if (authProvider.user != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authProvider.user!.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  UserRole.getString(authProvider.user!.role),
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
              ],
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String routeName,
  }) {
    final bool isSelected = selectedRoute == routeName;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Constants.kPrimaryColor : Colors.grey.shade700,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Constants.kPrimaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Constants.kPrimaryColor.withOpacity(0.1),
      onTap: () {
        Navigator.pop(context);
        onRouteSelected(routeName);
      },
    );
  }
}
