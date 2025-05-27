import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/navigation_drawer.dart';
import 'package:intl/intl.dart';

class EggCollectionListScreen extends StatefulWidget {
  static const String routeName = '/egg-collection-list';
  const EggCollectionListScreen({super.key});

  @override
  State<EggCollectionListScreen> createState() =>
      _EggCollectionListScreenState();
}

class _EggCollectionListScreenState extends State<EggCollectionListScreen> {
  List<Map<String, dynamic>> _eggCollections = [];
  List<Map<String, dynamic>> _flocks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final headers = await authProvider.getHeaders();
    final farmId = authProvider.user!['farm_id'];

    try {
      // Fetch flocks
      final flocksRes = await http.get(
        Uri.parse('${Constants.API_BASE_URL}/flocks?farm_id=$farmId'),
        headers: headers,
      );
      if (flocksRes.statusCode == 200) {
        _flocks = List<Map<String, dynamic>>.from(jsonDecode(flocksRes.body));
      }

      // Fetch egg collections
      final eggRes = await http.get(
        Uri.parse('${Constants.API_BASE_URL}/egg-production?farm_id=$farmId'),
        headers: headers,
      );
      if (eggRes.statusCode == 200) {
        _eggCollections = List<Map<String, dynamic>>.from(
          jsonDecode(eggRes.body),
        );
      } else {
        // Offline: Fetch from sqflite
        final db = await openDatabase(
          path.join(await getDatabasesPath(), 'turuke.db'),
        );
        final synced = await db.query('egg_production');
        final pending = await db.query('egg_pending');
        _eggCollections = [...synced, ...pending];
      }
    } catch (e) {
      // Offline fallback
      final db = await openDatabase(
        path.join(await getDatabasesPath(), 'turuke.db'),
      );
      final synced = await db.query('egg_production');
      final pending = await db.query('egg_pending');
      _eggCollections = [...synced, ...pending];
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onRouteSelected(String route) {
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Egg Collection')),
      drawer: AppNavigationDrawer(
        selectedRoute: EggCollectionListScreen.routeName,
        onRouteSelected: _onRouteSelected,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _eggCollections.isEmpty
              ? const Center(child: Text('No egg collections found'))
              : SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Date',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(label: Text('Whole Eggs')),
                      DataColumn(label: Text('Broken Eggs')),
                      DataColumn(label: Text('Total')),
                    ],
                    rows:
                        _eggCollections.map((entry) {
                          final total =
                              (entry['whole_eggs'] ?? 0) +
                              (entry['broken_eggs'] ?? 0);
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(_formatDate(entry['collection_date'])),
                              ),
                              DataCell(Text('${entry['whole_eggs'] ?? 0}')),
                              DataCell(Text('${entry['broken_eggs'] ?? 0}')),
                              DataCell(Text('$total')),
                            ],
                          );
                        }).toList(),
                  ),
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _flocks.isEmpty ? null : () {},
        tooltip: 'Add Egg Collection',
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(isoDate);
      return DateFormat('d MMMM, yyyy').format(dateTime);
    } catch (e) {
      return isoDate;
    }
  }
}
