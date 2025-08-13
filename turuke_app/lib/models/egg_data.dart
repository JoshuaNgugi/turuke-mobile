import 'package:turuke_app/utils/string_utils.dart';

class EggData {
  final int? id; // nullable if not yet persisted (used in offline mode)
  final int flockId;
  final String collectionDate;
  final int wholeEggs;
  final int brokenEggs;
  final String flockName;
  final int totalEggs;

  EggData({
    this.id,
    required this.flockId,
    required this.collectionDate,
    required this.wholeEggs,
    required this.brokenEggs,
    required this.flockName,
    required this.totalEggs,
  });

  EggData.empty()
    : id = null,
      flockId = 0,
      collectionDate = '',
      wholeEggs = 0,
      brokenEggs = 0,
      flockName = '',
      totalEggs = 0;

  factory EggData.fromJson(Map<String, dynamic> json) {
    return EggData(
      id: json['id'],
      flockId: json['flock_id'],
      collectionDate: StringUtils.formatDateDisplay(json['collection_date']),
      wholeEggs: json['whole_eggs'],
      brokenEggs: json['broken_eggs'],
      flockName: json['name'],
      totalEggs: json['total_eggs'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'flock_id': flockId,
      'collection_date': collectionDate,
      'whole_eggs': wholeEggs,
      'broken_eggs': brokenEggs,
      'name': flockName,
      'total_eggs': totalEggs,
    };
  }
}
