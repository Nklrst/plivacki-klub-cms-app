import 'schedule.dart';

class Enrollment {
  final int id;
  final int memberId;
  final int scheduleId;
  final bool active;
  final Schedule? schedule; // Nested schedule info

  Enrollment({
    required this.id,
    required this.memberId,
    required this.scheduleId,
    required this.active,
    this.schedule,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      id: json['id'],
      memberId: json['member_id'],
      scheduleId: json['schedule_id'],
      active: json['active'],
      schedule: json['schedule'] != null
          ? Schedule.fromJson(json['schedule'])
          : null,
    );
  }
}
