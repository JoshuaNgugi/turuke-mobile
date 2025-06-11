import 'package:flutter/material.dart';
import 'package:turuke_app/utils/string_utils.dart';

class EggCollectionDataSource extends DataTableSource {
  final List<Map<String, dynamic>> _eggCollections;
  final Function(Map<String, dynamic>)? onSelect; // Add onSelect callback

  EggCollectionDataSource({
    required List<Map<String, dynamic>> eggCollections,
    this.onSelect,
  }) : _eggCollections = eggCollections;

  @override
  DataRow? getRow(int index) {
    if (index >= _eggCollections.length) return null;
    final entry = _eggCollections[index];
    final total = (entry['whole_eggs'] ?? 0) + (entry['broken_eggs'] ?? 0);
    return DataRow(
      onSelectChanged: (selected) {
        if (selected == true && onSelect != null) {
          onSelect!(entry); // Trigger onSelect when row is tapped
        }
      },
      cells: [
        DataCell(Text('${entry['breed'] ?? 0}')), // TODO: change to name
        DataCell(Text(StringUtils.formatDate(entry['collection_date']))),
        DataCell(Text('${entry['whole_eggs'] ?? 0}')),
        DataCell(Text('${entry['broken_eggs'] ?? 0}')),
        DataCell(Text('$total')),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _eggCollections.length;

  @override
  int get selectedRowCount => 0;
}
