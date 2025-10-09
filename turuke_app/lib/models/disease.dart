import 'package:turuke_app/utils/string_utils.dart';

class Disease {
  final int? id; // nullable if not yet persisted (used in offline mode)
  final int flockId;
  final String name;
  final String diagnosisDate;
  final int? affectedCount;
  final String? notes;
  final String? flockName;
  final bool? isWholeFlockAffected;

  Disease({
    this.id,
    required this.flockId,
    required this.name,
    required this.diagnosisDate,
    this.affectedCount,
    required this.notes,
    this.flockName,
    this.isWholeFlockAffected = false,
  });

  String get affectedSummary {
    return isWholeFlockAffected == true
        ? 'Whole Flock'
        : affectedCount?.toString() ?? '0';
  }

  factory Disease.fromJson(Map<String, dynamic> json) {
    return Disease(
      id: json['id'],
      flockId: json['flock_id'],
      name: json['disease_name'],
      diagnosisDate: StringUtils.formatDateDisplay(json['diagnosis_date']),
      affectedCount: json['affected_count'],
      notes: json['notes'],
      flockName: json['flock_name'],
      isWholeFlockAffected: json['is_whole_flock_affected'],
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
      'is_whole_flock_affected': isWholeFlockAffected,
    };
  }
}
