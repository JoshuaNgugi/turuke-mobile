import 'package:flutter/material.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/utils/string_utils.dart';

class UsersDataSource extends DataTableSource {
  final List<Map<String, dynamic>> _users;

  UsersDataSource({required List<Map<String, dynamic>> users})
    : _users = users;

  @override
  DataRow? getRow(int index) {
    if (index >= _users.length) return null;
    final user = _users[index];
    return DataRow(
      cells: [
        DataCell(Text(user['first_name'] ?? '')),
        DataCell(Text(user['last_name'] ?? '')),
        DataCell(Text(user['email'] ?? '')),
        DataCell(Text(UserRole.getString(user['role'] ?? 5))),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _users.length;

  @override
  int get selectedRowCount => 0;
}
