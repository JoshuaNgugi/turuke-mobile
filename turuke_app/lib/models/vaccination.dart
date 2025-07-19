import 'package:turuke_app/utils/string_utils.dart';

class Vaccination {
  final int? id; // nullable if not yet persisted (used in offline mode)
  final int flockId;
  final String name;
  final String vaccinationDate;
  final String? notes;
  final String flockName;

  Vaccination({
    this.id,
    required this.flockId,
    required this.name,
    required this.vaccinationDate,
    required this.notes,
    required this.flockName,
  });

  factory Vaccination.fromJson(Map<String, dynamic> json) {
    return Vaccination(
      id: json['id'],
      flockId: json['flock_id'],
      name: json['vaccine_name'],
      vaccinationDate: StringUtils.formatDateDisplay(json['vaccination_date']),
      notes: json['notes'],
      flockName: json['flock_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'flock_id': flockId,
      'vaccine_name': name,
      'vaccination_date': vaccinationDate,
      'notes': notes,
    };
  }
}
