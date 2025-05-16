import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

import 'package:turuke_app/constants.dart';
import 'package:turuke_app/providers/auth_provider.dart';

Future<Database> initDatabase() async {
  return openDatabase(
    join(await getDatabasesPath(), 'turuke.db'),
    onCreate: (db, version) async {
      await db.execute(
        'CREATE TABLE egg_pending(id TEXT PRIMARY KEY, flock_id INTEGER, collection_date TEXT, whole_eggs INTEGER, broken_eggs INTEGER)',
      );
      await db.execute(
        'CREATE TABLE flock_pending(id TEXT PRIMARY KEY, farm_id INTEGER, breed TEXT, arrival_date TEXT, initial_count INTEGER, age_weeks INTEGER, status TEXT)',
      );
      await db.execute(
        'CREATE TABLE vaccination_pending(id TEXT PRIMARY KEY, flock_id INTEGER, vaccine_name TEXT, vaccination_date TEXT, notes TEXT)',
      );
      await db.execute(
        'CREATE TABLE disease_pending(id TEXT PRIMARY KEY, flock_id INTEGER, disease_name TEXT, diagnosis_date TEXT, affected_count INTEGER, notes TEXT)',
      );
    },
    version: 1,
  );
}

Future<void> syncPendingData(BuildContext context, Database db) async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  if (authProvider.token == null) return; // Skip sync if not logged in
  final headers = await authProvider.getHeaders();

  // Sync egg_pending
  final eggs = await db.query('egg_pending');
  for (var entry in eggs) {
    try {
      final response = await http.post(
        Uri.parse('${Constants.API_BASE_URL}/egg-production'),
        headers: headers,
        body: jsonEncode({
          'flock_id': entry['flock_id'],
          'collection_date': entry['collection_date'],
          'whole_eggs': entry['whole_eggs'],
          'broken_eggs': entry['broken_eggs'],
        }),
      );
      if (response.statusCode == 201) {
        await db.delete(
          'egg_pending',
          where: 'id = ?',
          whereArgs: [entry['id']],
        );
      }
    } catch (e) {
      // Retry later
    }
  }

  // Sync flock_pending
  final flocks = await db.query('flock_pending');
  for (var entry in flocks) {
    try {
      final response = await http.post(
        Uri.parse('${Constants.API_BASE_URL}/flocks'),
        headers: headers,
        body: jsonEncode({
          'farm_id': entry['farm_id'],
          'breed': entry['breed'],
          'arrival_date': entry['arrival_date'],
          'initial_count': entry['initial_count'],
          'age_weeks': entry['age_weeks'],
          'status': entry['status'],
        }),
      );
      if (response.statusCode == 201) {
        await db.delete(
          'flock_pending',
          where: 'id = ?',
          whereArgs: [entry['id']],
        );
      }
    } catch (e) {
      // Retry later
    }
  }

  // Sync vaccination_pending
  final vaccinations = await db.query('vaccination_pending');
  for (var entry in vaccinations) {
    try {
      final response = await http.post(
        Uri.parse('${Constants.API_BASE_URL}/vaccinations'),
        headers: headers,
        body: jsonEncode({
          'flock_id': entry['flock_id'],
          'vaccine_name': entry['vaccine_name'],
          'vaccination_date': entry['vaccination_date'],
          'notes': entry['notes'],
        }),
      );
      if (response.statusCode == 201) {
        await db.delete(
          'vaccination_pending',
          where: 'id = ?',
          whereArgs: [entry['id']],
        );
      }
    } catch (e) {
      // Retry later
    }
  }

  // Sync disease_pending
  final diseases = await db.query('disease_pending');
  for (var entry in diseases) {
    try {
      final response = await http.post(
        Uri.parse('${Constants.API_BASE_URL}/diseases'),
        headers: headers,
        body: jsonEncode({
          'flock_id': entry['flock_id'],
          'disease_name': entry['disease_name'],
          'diagnosis_date': entry['diagnosis_date'],
          'affected_count': entry['affected_count'],
          'notes': entry['notes'],
        }),
      );
      if (response.statusCode == 201) {
        await db.delete(
          'disease_pending',
          where: 'id = ?',
          whereArgs: [entry['id']],
        );
      }
    } catch (e) {
      // Retry later
    }
  }
}
