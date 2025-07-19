import 'package:flutter/material.dart';
import 'package:turuke_app/models/egg_data.dart';
import 'package:turuke_app/utils/string_utils.dart';

class EggCollectionDataSource extends DataTableSource {
  List<EggData> _eggCollections;
  final Function(EggData)? onSelect;

  EggCollectionDataSource({
    required List<EggData> eggCollections,
    this.onSelect,
  }) : _eggCollections = eggCollections;

  void updateEggCollections(List<EggData> newEggCollections) {
    _eggCollections = newEggCollections;
    notifyListeners();
  }

  @override
  DataRow? getRow(int index) {
    if (index >= _eggCollections.length) return null;
    final eggData = _eggCollections[index];

    return DataRow(
      onSelectChanged: (selected) {
        if (selected == true && onSelect != null) {
          onSelect!(eggData);
        }
      },
      cells: [
        DataCell(Text(eggData.flockName)),
        DataCell(Text(StringUtils.formatDateDisplay(eggData.collectionDate))),
        DataCell(Text('${eggData.wholeEggs}')),
        DataCell(Text('${eggData.brokenEggs}')),
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
