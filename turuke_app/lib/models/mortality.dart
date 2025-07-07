import 'package:turuke_app/utils/string_utils.dart';

class Mortality {
  final int? id; // nullable if not yet persisted (used in offline mode)
  final int flockId;
  final int count;
  final String recordedDate;
  final String? cause;

  Mortality({
    this.id,
    required this.flockId,
    required this.count,
    required this.recordedDate,
    this.cause,
  });

  Mortality.empty()
    : id = null,
      flockId = 0,
      recordedDate = '',
      count = 0,
      cause = '';

  factory Mortality.fromJson(Map<String, dynamic> json) {
    return Mortality(
      id: json['id'],
      flockId: json['flock_id'],
      recordedDate: StringUtils.formatDate(json['created_at']),
      count: json['count'],
      cause: json['cause'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'flock_id': flockId,
      'created_at': recordedDate,
      'count': count,
      'cause': cause,
    };
  }
}
