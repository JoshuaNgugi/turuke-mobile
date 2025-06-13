import 'package:flutter/material.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/models/user.dart';

class UsersDataSource extends DataTableSource {
  final List<User> _users;
  final Function(User) onSelect;

  UsersDataSource({required List<User> users, required this.onSelect})
    : _users = users;

  @override
  DataRow? getRow(int index) {
    if (index >= _users.length) return null;
    final user = _users[index];
    return DataRow(
      onSelectChanged: (selected) {
        if (selected == true && onSelect != null) {
          onSelect(user); // Trigger onSelect when row is tapped
        }
      },
      cells: [
        DataCell(Text(user.firstName ?? '')),
        DataCell(Text(user.lastName ?? '')),
        DataCell(Text(user.email)),
        DataCell(Text(UserRole.getString(user.role))),
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
