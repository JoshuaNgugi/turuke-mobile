import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/datasources/users_datasource.dart';
import 'package:turuke_app/models/user.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/add_user_screen.dart';
import 'package:turuke_app/screens/login_screen.dart';
import 'package:turuke_app/screens/navigation_drawer_screen.dart';
import 'package:turuke_app/utils/http_client.dart';
import 'package:turuke_app/utils/system_utils.dart';

var logger = Logger(printer: PrettyPrinter());

class UserManagementScreen extends StatefulWidget {
  static const String routeName = '/users-management';

  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<User> _users = [];
  bool _isLoading = true;
  final int _rowsPerPage =
      PaginatedDataTable.defaultRowsPerPage; // Use default for consistency

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final headers = await authProvider.getHeaders();
    final farmId = authProvider.user?.farmId; // Use null-safe access

    if (farmId == null) {
      if (mounted) {
        SystemUtils.showSnackBar(
          context,
          'Farm ID not available. Cannot fetch users.',
        );
        // Optionally, log out if farmId is crucial and missing
        // await authProvider.logout();
        // Navigator.of(context).pushAndRemoveUntil(
        //   MaterialPageRoute(builder: (context) => const LoginScreen()),
        //   (Route<dynamic> route) => false,
        // );
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final response = await HttpClient.get(
        Uri.parse('${Constants.USERS_API_BASE_URL}/users?farm_id=$farmId'),
        headers: headers,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        List<dynamic> usersData = jsonDecode(response.body);
        setState(() {
          _users = usersData.map((user) => User.fromJson(user)).toList();
        });
      } else if (response.statusCode == 401) {
        SystemUtils.showSnackBar(
          context,
          'Authentication failed. Please log in again.',
        );
        await authProvider.logout();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
        }
      } else {
        logger.e(
          'Failed to fetch users: ${response.statusCode} - ${response.body}',
        );
        SystemUtils.showSnackBar(
          context,
          'Failed to load users: ${response.statusCode}',
        );
        setState(() {
          _users = [];
        });
      }
    } catch (e) {
      logger.e('Error fetching users: $e');
      if (mounted) {
        SystemUtils.showSnackBar(
          context,
          'Network error. Could not load users.',
        );
        setState(() {
          _users = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onRouteSelected(String route, [Map<String, dynamic>? args, int? role]) {
    Navigator.pushNamed(context, route, arguments: args).then((_) {
      _fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.user?.role ?? UserRole.VIEWER;

    if (userRole != UserRole.ADMIN && userRole != UserRole.MANAGER) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'User Management',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Constants.kPrimaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        drawer: AppNavigationDrawer(
          selectedRoute: UserManagementScreen.routeName,
          onRouteSelected: _onRouteSelected,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Access Denied',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your account is not authorized to view or manage users.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final dataSource = UsersDataSource(
      users: _users,
      onSelect:
          (user) => _onRouteSelected(AddUserScreen.routeName, {'user': user}),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Management',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Constants.kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchUsers, // Manual refresh button
            tooltip: 'Refresh Users',
          ),
        ],
      ),
      drawer: AppNavigationDrawer(
        selectedRoute: UserManagementScreen.routeName,
        onRouteSelected: _onRouteSelected,
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Constants.kPrimaryColor,
                  ),
                ),
              )
              : _users.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_alt_outlined,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No users found',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the "+" button to add your user.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (userRole == UserRole.ADMIN ||
                        userRole == UserRole.MANAGER)
                      ElevatedButton.icon(
                        onPressed:
                            () => _onRouteSelected(AddUserScreen.routeName),
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add New User'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.kPrimaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _fetchUsers,
                color: Constants.kPrimaryColor,
                child: SingleChildScrollView(
                  child: PaginatedDataTable(
                    header: const Text(
                      'Farm Users',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(label: Text('First Name')),
                      DataColumn(label: Text('Last Name')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Role')),
                    ],
                    source: dataSource,
                    rowsPerPage: _rowsPerPage,
                    columnSpacing: 16,
                    horizontalMargin: 16,
                  ),
                ),
              ),
      floatingActionButton:
          (userRole == UserRole.ADMIN || userRole == UserRole.MANAGER)
              ? FloatingActionButton(
                onPressed: () => _onRouteSelected(AddUserScreen.routeName),
                backgroundColor: Constants.kPrimaryColor,
                foregroundColor: Colors.white,
                tooltip: 'Add User',
                child: const Icon(Icons.add),
              )
              : null,
    );
  }
}
