import 'package:flutter/material.dart';
import 'package:turuke_app/models/mortality.dart';
import 'package:turuke_app/utils/string_utils.dart';

class MortalityDataSource extends DataTableSource {
  final List<Mortality> _mortalityList;
  final Function(Mortality)? onSelect;

  MortalityDataSource({required List<Mortality> mortality, this.onSelect})
    : _mortalityList = mortality;

  @override
  DataRow? getRow(int index) {
    if (index >= _mortalityList.length) return null;
    final mortalityData = _mortalityList[index];
    return DataRow(
      onSelectChanged: (selected) {
        if (selected == true && onSelect != null) {
          onSelect!(mortalityData);
        }
      },
      cells: [
        DataCell(
          Text(StringUtils.formatDateDisplay(mortalityData.recordedDate)),
        ),
        DataCell(Text(mortalityData.flockName ?? '')),
        DataCell(Text('${mortalityData.count}')),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _mortalityList.length;

  @override
  int get selectedRowCount => 0;
}
