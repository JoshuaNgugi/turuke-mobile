import 'package:turuke_app/utils/string_utils.dart';

class Flock {
  final int? id;
  final int farmId;
  final String name;
  final String arrivalDate;
  final int initialCount;
  final int currentCount;
  final int? ageWeeks;
  final int status;
  final int? currentAgeWeeks;

  Flock({
    this.id,
    required this.farmId,
    required this.name,
    required this.arrivalDate,
    required this.initialCount,
    required this.currentCount,
    this.ageWeeks,
    required this.status,
    this.currentAgeWeeks,
  });

  factory Flock.fromJson(Map<String, dynamic> json) {
    return Flock(
      id: json['id'],
      farmId: json['farm_id'],
      name: json['name'],
      arrivalDate: StringUtils.formatDateDisplay(json['arrival_date']),
      initialCount: json['initial_count'],
      currentCount: json['current_count'],
      ageWeeks: json['current_age_weeks'] ?? json['age_weeks'] ?? 0,
      status: json['status'],
      currentAgeWeeks: json['current_age_weeks'],
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
      'status': status,
    };
  }
}
