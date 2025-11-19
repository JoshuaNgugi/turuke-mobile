import 'package:turuke_app/utils/string_utils.dart';

class MonthlyYield {
  final String collectionDate;
  final int totalEggs;

  MonthlyYield({required this.collectionDate, required this.totalEggs});

  factory MonthlyYield.fromJson(Map<String, dynamic> json) {
    return MonthlyYield(
      collectionDate: StringUtils.formatDateDisplay(json['collection_date']),
      totalEggs: json['total_eggs'],
    );
  }
}
