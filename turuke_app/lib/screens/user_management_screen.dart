import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/datasources/users_datasource.dart';
import 'package:turuke_app/models/user.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/add_user_screen.dart';
import 'package:turuke_app/screens/navigation_drawer.dart';

class UserManagementScreen extends StatefulWidget {
  static const String routeName = '/users-management';

  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<User> _users = [];
  bool _isLoading = true;
  final int _rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final headers = await authProvider.getHeaders();
    final farmId = authProvider.user!['farm_id'];

    try {
      final response = await http.get(
        Uri.parse('${Constants.API_BASE_URL}/users?farm_id=$farmId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        List<dynamic> usersData = jsonDecode(response.body);
        _users = usersData.map((user) => User.fromJson(user)).toList();
      } else {
        // Offline: Fetch from sqflite
        final db = await openDatabase(
          path.join(await getDatabasesPath(), 'turuke.db'),
        );
        List<Map<String, Object?>> dbUsers = await db.query('users');
        _users = dbUsers.map((user) => User.fromJson(user)).toList();
      }
    } catch (e) {
      // Offline fallback
      final db = await openDatabase(
        path.join(await getDatabasesPath(), 'turuke.db'),
      );
      List<Map<String, Object?>> dbUsers = await db.query('users');
      _users = dbUsers.map((user) => User.fromJson(user)).toList();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onRouteSelected(String route, [Map<String, dynamic>? args]) {
    Navigator.pushNamed(context, route, arguments: args);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.user?['role'] ?? 5;

    if (userRole != 1 && userRole != 2) {
      return Scaffold(
        appBar: AppBar(title: const Text('User Management')),
        body: const Center(child: Text('Access Denied')),
      );
    }

    final dataSource = UsersDataSource(
      users: _users,
      onSelect:
          (entry) => _onRouteSelected(
            AddUserScreen.routeName,
            {'collection': entry}, // Pass selected collection
          ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      drawer: AppNavigationDrawer(
        selectedRoute: UserManagementScreen.routeName,
        onRouteSelected: _onRouteSelected,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
              ? const Center(child: Text('No users found'))
              : SingleChildScrollView(
                child: PaginatedDataTable(
                  header: const Text('Farm Users'),
                  showCheckboxColumn: false,
                  columns: [
                    DataColumn(label: const Text('First Name')),
                    DataColumn(label: const Text('Last Name')),
                    DataColumn(label: const Text('Email')),
                    DataColumn(label: const Text('Role')),
                  ],
                  source: dataSource,
                  rowsPerPage: _rowsPerPage,
                  columnSpacing: 16,
                  horizontalMargin: 16,
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-user'),
        child: const Icon(Icons.add),
        tooltip: 'Add User',
      ),
    );
  }
}
