import 'package:turuke_app/utils/string_utils.dart';

class Flock {
  final int? id; // nullable if not yet persisted (used in offline mode)
  final int farmId;
  final String name;
  final String arrivalDate;
  final int initialCount;
  final int currentCount;
  final int ageWeeks;
  final int status;

  Flock({
    this.id,
    required this.farmId,
    required this.name,
    required this.arrivalDate,
    required this.initialCount,
    required this.currentCount,
    required this.ageWeeks,
    required this.status,
  });

  factory Flock.fromJson(Map<String, dynamic> json) {
    return Flock(
      id: json['id'],
      farmId: json['farm_id'],
      name: json['breed'], // TODO: change to name
      arrivalDate: StringUtils.formatDate(json['arrival_date']),
      initialCount: json['initial_count'],
      currentCount: json['current_count'],
      ageWeeks: json['current_age_weeks'] ?? json['age_weeks'] ?? 0,
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'farm_id': farmId,
      'name': name,
      'arrival_date': arrivalDate,
      'initial_count': initialCount,
      'current_count': currentCount,
      'age_weeks': ageWeeks,
      'status': status,
    };
  }
}
