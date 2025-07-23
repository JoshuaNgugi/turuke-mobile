import 'package:turuke_app/utils/string_utils.dart';

class Disease {
  final int? id; // nullable if not yet persisted (used in offline mode)
  final int flockId;
  final String name;
  final String diagnosisDate;
  final int affectedCount;
  final String? notes;
  final String? flockName;

  Disease({
    this.id,
    required this.flockId,
    required this.name,
    required this.diagnosisDate,
    required this.affectedCount,
    required this.notes,
    this.flockName,
  });

  factory Disease.fromJson(Map<String, dynamic> json) {
    return Disease(
      id: json['id'],
      flockId: json['flock_id'],
      name: json['disease_name'],
      diagnosisDate: StringUtils.formatDateDisplay(json['diagnosis_date']),
      affectedCount: json['affected_count'],
      notes: json['notes'],
      flockName: json['flock_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'flock_id': flockId,
      'disease_name': name,
      'diagnosis_date': diagnosisDate,
      'affected_count': affectedCount,
      'notes': notes,
    };
  }
}
