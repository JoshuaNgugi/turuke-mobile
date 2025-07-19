import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:turuke_app/constants.dart'; // Assuming kPrimaryColor, kAccentColor, UserRole enum are here
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/change_password_screen.dart';
import 'package:turuke_app/screens/disease_log_screen.dart';
import 'package:turuke_app/screens/egg_collection_list_screen.dart'; // Use the list screen for navigation
import 'package:turuke_app/screens/flock_management_screen.dart';
import 'package:turuke_app/screens/home_screen.dart';
import 'package:turuke_app/screens/login_screen.dart';
import 'package:turuke_app/screens/mortality_list_screen.dart';
import 'package:turuke_app/screens/user_management_screen.dart';
import 'package:turuke_app/screens/vaccination_log_screen.dart';

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
    // Safely get user role, defaulting to VIEWER if user or role is null
    final int? userRole = authProvider.user?.role;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero, // Remove default ListView padding
        children: [
          // Enhanced Drawer Header
          _buildDrawerHeader(context, authProvider),

          // Home
          _buildDrawerItem(
            context,
            icon: Icons.home,
            title: 'Home',
            routeName: HomeScreen.routeName,
          ),
          // Egg Collection List (Navigating to list screen as primary)
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
            routeName: FlockManagementScreen.routeName,
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

          // User Management (Conditional access)
          // Assuming userRole is an enum and has methods like isAdmin() or isManager()
          // If not, you can revert to `userRole == UserRole.ADMIN || userRole == UserRole.MANAGER`
          if (userRole == UserRole.ADMIN || userRole == UserRole.MANAGER)
            _buildDrawerItem(
              context,
              icon: Icons.people,
              title: 'User Management',
              routeName: UserManagementScreen.routeName,
            ),

          // Dividers for visual separation
          const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),

          // Settings (Change Password)
          _buildDrawerItem(
            context,
            icon: Icons.settings,
            title: 'Settings',
            routeName: ChangePasswordScreen.routeName,
          ),

          const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
            onTap: () async {
              // Show confirmation dialog before logging out
              final confirmed = await _showLogoutConfirmationDialog(context);
              if (confirmed == true) {
                // Perform logout action via AuthProvider
                await authProvider.logout();
                if (!context.mounted) return; // Check context after async
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  LoginScreen.routeName,
                  (route) => false, // Clears the navigation stack
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Builds a custom DrawerHeader with app branding and user info.
  Widget _buildDrawerHeader(BuildContext context, AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.only(
        left: 24.0,
        bottom: 16.0,
      ), // Adjust padding
      decoration: const BoxDecoration(
        color: Constants.kPrimaryColor, // Use your primary color
        // You could add a background image here
        // image: DecorationImage(
        //   image: AssetImage('assets/images/drawer_bg.png'),
        //   fit: BoxFit.cover,
        //   opacity: 0.5,
        // ),
      ),
      height: 180, // A bit taller header
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // App Icon/Logo (Optional)
          // Image.asset('assets/icons/app_icon.png', height: 40, width: 40),
          // const SizedBox(height: 12),
          const Text(
            'Turuke',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28, // Larger font for branding
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2, // A bit of letter spacing
            ),
          ),
          const SizedBox(height: 12),
          // Display logged-in user's name and email
          if (authProvider.user != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authProvider.user!.email,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  authProvider.user!.email,
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
              ],
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Helper method to build a standardized DrawerListTile.
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
        color:
            isSelected
                ? Constants.kPrimaryColor
                : Colors
                    .grey
                    .shade700, // Accent color for selected, grey for others
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Constants.kPrimaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      // Apply a subtle background color when selected
      selectedTileColor: Constants.kPrimaryColor.withOpacity(0.1), // Light tint
      onTap: () {
        Navigator.pop(context); // Close the drawer first
        onRouteSelected(routeName); // Then navigate
      },
    );
  }

  /// Shows a confirmation dialog for logout.
  Future<bool?> _showLogoutConfirmationDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed:
                  () => Navigator.of(
                    dialogContext,
                  ).pop(false), // Dismiss and return false
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed:
                  () => Navigator.of(
                    dialogContext,
                  ).pop(true), // Dismiss and return true
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Red for logout confirmation
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
