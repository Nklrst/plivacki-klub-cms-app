import 'enrollment.dart';

class Member {
  final int id;
  final String fullName;
  final DateTime dateOfBirth;
  final String? notes;
  final bool active;
  final List<Enrollment> enrollments;

  Member({
    required this.id,
    required this.fullName,
    required this.dateOfBirth,
    this.notes,
    required this.active,
    this.enrollments = const [],
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      fullName: json['full_name'],
      dateOfBirth: DateTime.parse(json['date_of_birth']),
      notes: json['notes'],
      active: json['active'],
      enrollments:
          (json['enrollments'] as List<dynamic>?)
              ?.map((e) => Enrollment.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'notes': notes,
      'active': active,
    };
  }
}
