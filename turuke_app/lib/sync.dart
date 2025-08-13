import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/providers/auth_provider.dart';

var logger = Logger();

const int _databaseVersion = 1;

Future<Database> initDatabase() async {
  return openDatabase(
    join(await getDatabasesPath(), 'turuke.db'),
    onCreate: (db, version) async {
      // These are all the tables for version 1 of your database.
      // They will be created when the database is first initialized.
      await db.execute(
        'CREATE TABLE egg_pending(id TEXT PRIMARY KEY, flock_id INTEGER, collection_date TEXT, whole_eggs INTEGER, broken_eggs INTEGER)',
      );
      await db.execute(
        'CREATE TABLE flock_pending(id TEXT PRIMARY KEY, farm_id INTEGER, name TEXT, arrival_date TEXT, initial_count INTEGER, current_count INTEGER, age_weeks INTEGER, status TEXT)',
      );
      await db.execute(
        'CREATE TABLE vaccination_pending(id TEXT PRIMARY KEY, flock_id INTEGER, vaccine_name TEXT, vaccination_date TEXT, notes TEXT)',
      );
      await db.execute(
        'CREATE TABLE disease_pending(id TEXT PRIMARY KEY, flock_id INTEGER, disease_name TEXT, diagnosis_date TEXT, affected_count INTEGER, notes TEXT)',
      );
      await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY,
          first_name TEXT,
          last_name TEXT,
          email TEXT,
          farm_id INTEGER,
          role INTEGER,
          status INTEGER
        )
      ''');
      await db.execute('''
        CREATE TABLE users_pending(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          first_name TEXT,
          last_name TEXT,
          email TEXT,
          farm_id INTEGER,
          role INTEGER,
          password TEXT,
          created_at TEXT
        )
      ''');
      // Add any new tables that were missing from the initial version.
      // For instance, if 'mortality_pending' was added later:
      await db.execute(
        'CREATE TABLE mortality_pending(id TEXT PRIMARY KEY, flock_id INTEGER, mortality_date TEXT, count INTEGER, reason TEXT)',
      );
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      // This is called when the database needs to be upgraded.
      // Write migration scripts here based on the old and new versions.
      if (oldVersion < 2) {
        // Migrate from version 1 to version 2
        // Add other schema changes for version 2 if any (e.g., add new columns)
        // Example: await db.execute('ALTER TABLE egg_pending ADD COLUMN new_column TEXT;');
      }
    },
    version: _databaseVersion, // Use the constant version
  );
}

Future<void> syncPendingData(BuildContext context, Database db) async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  if (authProvider.token == null) {
    logger.i('Sync skipped: User not logged in.');
    return;
  }
  final headers = await authProvider.getHeaders();
  if (!headers.containsKey('Authorization')) {
    logger.i('Sync skipped: Auth token is missing or expired.');
    return;
  }

  Future<void> _syncTable(
    String tableName,
    String apiEndpoint,
    Function(Map<String, dynamic>) getBody,
  ) async {
    try {
      final entries = await db.query(tableName);
      for (var entry in entries) {
        try {
          final response = await http.post(
            Uri.parse('${Constants.API_BASE_URL}/$apiEndpoint'),
            headers: headers,
            body: jsonEncode(getBody(entry)),
          );
          if (response.statusCode == 201) {
            await db.delete(
              tableName,
              where: 'id = ?',
              whereArgs: [entry['id']],
            );
            logger.i('Synced and deleted from $tableName: ${entry['id']}');
          } else {
            logger.i(
              'Failed to sync $tableName entry ${entry['id']}: Status ${response.statusCode}, Body: ${response.body}',
            );
          }
        } catch (e) {
          logger.e('Error syncing $tableName entry ${entry['id']}: $e');
        }
      }
    } catch (e) {
      logger.e('Error querying table $tableName for sync: $e');
    }
  }

  logger.i('Starting data synchronization...');

  await _syncTable(
    'egg_pending',
    'egg-production',
    (entry) => {
      'flock_id': entry['flock_id'],
      'collection_date': entry['collection_date'],
      'whole_eggs': entry['whole_eggs'],
      'broken_eggs': entry['broken_eggs'],
    },
  );

  await _syncTable(
    'flock_pending',
    'flocks',
    (entry) => {
      'farm_id': entry['farm_id'],
      'name': entry['name'],
      'arrival_date': entry['arrival_date'],
      'initial_count': entry['initial_count'],
      'current_count': entry['current_count'],
      'age_weeks': entry['age_weeks'],
      'status': entry['status'],
    },
  );

  await _syncTable(
    'vaccination_pending',
    'vaccinations',
    (entry) => {
      'flock_id': entry['flock_id'],
      'vaccine_name': entry['vaccine_name'],
      'vaccination_date': entry['vaccination_date'],
      'notes': entry['notes'],
    },
  );

  await _syncTable(
    'disease_pending',
    'diseases',
    (entry) => {
      'flock_id': entry['flock_id'],
      'disease_name': entry['disease_name'],
      'diagnosis_date': entry['diagnosis_date'],
      'affected_count': entry['affected_count'],
      'notes': entry['notes'],
    },
  );

  await _syncTable(
    'mortality_pending',
    'mortalities',
    (entry) => {
      'flock_id': entry['flock_id'],
      'mortality_date': entry['mortality_date'],
      'count': entry['count'],
      'reason': entry['reason'],
    },
  );

  await _syncTable(
    'users_pending',
    'users',
    (user) => {
      'first_name': user['first_name'],
      'last_name': user['last_name'],
      'email': user['email'],
      'farm_id': user['farm_id'],
      'role': user['role'],
      'password': user['password'],
    },
  );
  // The users_pending sync needs to also insert into the 'users' table locally
  // This logic is a bit different as it updates a local cache, not just deletes pending.
  // So, it's better to keep it separate or modify _syncTable for insert_after_sync.
  // For now, let's keep it separate for clarity given its unique local insertion.
  final pendingUsers = await db.query('users_pending');
  for (var user in pendingUsers) {
    try {
      final response = await http.post(
        Uri.parse('${Constants.API_BASE_URL}/users'),
        headers: headers,
        body: jsonEncode({
          'first_name': user['first_name'],
          'last_name': user['last_name'],
          'email': user['email'],
          'farm_id': user['farm_id'],
          'role': user['role'],
          'password': user['password'],
        }),
      );
      if (response.statusCode == 201) {
        await db.delete(
          'users_pending',
          where: 'id = ?',
          whereArgs: [user['id']],
        );
        final userData = jsonDecode(response.body);
        await db.insert('users', {
          'id': userData['id'], // Assuming server returns the new user ID
          'first_name': user['first_name'],
          'last_name': user['last_name'],
          'email': user['email'],
          'farm_id': user['farm_id'],
          'role': user['role'],
          'status': 1, // Default status for new user
        });
        logger.i('Synced and deleted from users_pending: ${user['id']}');
      } else {
        logger.i(
          'Failed to sync users_pending entry ${user['id']}: Status ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      logger.e('Error syncing users_pending entry ${user['id']}: $e');
    }
  }

  logger.i('Data synchronization complete.');
}
