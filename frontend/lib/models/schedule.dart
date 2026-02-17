class Schedule {
  final int id;
  final String groupName;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final int capacity;
  final bool isActive;
  final int currentEnrollmentsCount;
  final String location; // Mora postojati ovde

  Schedule({
    required this.id,
    required this.groupName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    required this.isActive,
    required this.currentEnrollmentsCount,
    required this.location,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      groupName: json['group_name'] ?? 'Škola plivanja',
      dayOfWeek: json['day_of_week'].toString(),
      startTime: json['start_time'].toString(),
      endTime: json['end_time'].toString(),
      capacity: json['capacity'] ?? 0,
      isActive: json['is_active'] ?? true,
      currentEnrollmentsCount: json['current_enrollments_count'] ?? 0,
      // [FIX] Čitamo lokaciju, ako nema stavljamo prazno ili default
      location: json['location'] ?? 'Lokacija nije uneta',
    );
  }

  String get formattedTime {
    final start = startTime.length > 5 ? startTime.substring(0, 5) : startTime;
    final end = endTime.length > 5 ? endTime.substring(0, 5) : endTime;
    return "$start - $end";
  }

  String get dayName => dayOfWeek;
}
