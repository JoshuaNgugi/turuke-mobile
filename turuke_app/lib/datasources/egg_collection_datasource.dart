import 'package:flutter/material.dart';
import 'package:turuke_app/models/egg_data.dart';
import 'package:turuke_app/utils/string_utils.dart';

class EggCollectionDataSource extends DataTableSource {
  final List<EggData> _eggCollections;
  final Function(EggData)? onSelect;

  EggCollectionDataSource({
    required List<EggData> eggCollections,
    this.onSelect,
  }) : _eggCollections = eggCollections;

  @override
  DataRow? getRow(int index) {
    if (index >= _eggCollections.length) return null;
    final eggData = _eggCollections[index];
    return DataRow(
      onSelectChanged: (selected) {
        if (selected == true && onSelect != null) {
          onSelect!(eggData); // Trigger onSelect when row is tapped
        }
      },
      cells: [
        DataCell(Text('${eggData.flockName ?? 0}')), // TODO: change to name
        DataCell(Text(StringUtils.formatDate(eggData.collectionDate))),
        DataCell(Text('${eggData.wholeEggs ?? 0}')),
        DataCell(Text('${eggData.brokenEggs ?? 0}')),
        DataCell(Text('${eggData.totalEggs}')),
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
