import 'package:turuke_app/utils/string_utils.dart';

class Mortality {
  final int? id; // nullable if not yet persisted (used in offline mode)
  final int flockId;
  final int count;
  final String recordedDate;
  final String? cause;
  final String? flockName;

  Mortality({
    this.id,
    required this.flockId,
    required this.count,
    required this.recordedDate,
    this.cause,
    this.flockName,
  });

  Mortality.empty()
    : id = null,
      flockId = 0,
      recordedDate = '',
      count = 0,
      cause = '',
      flockName = '';

  factory Mortality.fromJson(Map<String, dynamic> json) {
    return Mortality(
      id: json['id'],
      flockId: json['flock_id'],
      recordedDate: StringUtils.formatDate(json['death_date']),
      count: json['count'],
      cause: json['cause'],
      flockName: json['flock_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'flock_id': flockId,
      'death_date': recordedDate,
      'count': count,
      'cause': cause,
    };
  }
}
