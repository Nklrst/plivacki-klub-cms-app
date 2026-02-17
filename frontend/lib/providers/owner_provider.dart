import 'package:flutter/material.dart';
import '../core/api_client.dart';

class DashboardStats {
  final int activeMembers;
  final int attendanceToday;
  final int revenueMonth;

  DashboardStats({
    required this.activeMembers,
    required this.attendanceToday,
    required this.revenueMonth,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      activeMembers: json['active_members'] ?? 0,
      attendanceToday: json['attendance_today'] ?? 0,
      revenueMonth: json['revenue_month'] ?? 0,
    );
  }
}

class TodaySchedule {
  final int scheduleId;
  final String groupName;
  final String time;
  final String location;
  final int enrolledCount;
  final int presentCount;

  TodaySchedule({
    required this.scheduleId,
    required this.groupName,
    required this.time,
    required this.location,
    required this.enrolledCount,
    required this.presentCount,
  });

  factory TodaySchedule.fromJson(Map<String, dynamic> json) {
    return TodaySchedule(
      scheduleId: json['schedule_id'] ?? 0,
      groupName: json['group_name'] ?? '',
      time: json['time'] ?? '',
      location: json['location'] ?? '',
      enrolledCount: json['enrolled_count'] ?? 0,
      presentCount: json['present_count'] ?? 0,
    );
  }
}

class OwnerProvider with ChangeNotifier {
  final ApiClient _apiClient;
  bool _isLoading = false;
  DashboardStats? _stats;
  List<TodaySchedule> _todaySchedules = [];

  OwnerProvider(this._apiClient);

  bool get isLoading => _isLoading;
  DashboardStats? get stats => _stats;
  List<TodaySchedule> get todaySchedules => _todaySchedules;

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch both in parallel
      final responses = await Future.wait([
        _apiClient.dio.get('/dashboard/stats'),
        _apiClient.dio.get('/dashboard/today-schedules'),
      ]);

      _stats = DashboardStats.fromJson(responses[0].data);

      final List<dynamic> schedData = responses[1].data;
      _todaySchedules = schedData
          .map((json) => TodaySchedule.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching dashboard data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
