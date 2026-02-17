import 'package:flutter/material.dart';
import '../core/api_client.dart';

class ScheduleItem {
  final int id;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final int capacity;
  final String groupName;
  final String location;
  final bool isActive;
  final int currentEnrollments;

  ScheduleItem({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    required this.groupName,
    required this.location,
    required this.isActive,
    required this.currentEnrollments,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'] ?? 0,
      dayOfWeek: json['day_of_week'] ?? '',
      startTime: _formatTime(json['start_time']),
      endTime: _formatTime(json['end_time']),
      capacity: json['capacity'] ?? 10,
      groupName: json['group_name'] ?? 'Bez naziva',
      location: json['location'] ?? '',
      isActive: json['is_active'] ?? true,
      currentEnrollments: json['current_enrollments_count'] ?? 0,
    );
  }

  static String _formatTime(dynamic t) {
    if (t == null) return '';
    final s = t.toString();
    // Return HH:MM from HH:MM:SS or HH:MM
    if (s.length >= 5) return s.substring(0, 5);
    return s;
  }
}

class ScheduleProvider with ChangeNotifier {
  final ApiClient _apiClient;
  bool _isLoading = false;
  List<ScheduleItem> _schedules = [];

  ScheduleProvider(this._apiClient);

  bool get isLoading => _isLoading;
  List<ScheduleItem> get schedules => _schedules;

  List<ScheduleItem> getSchedulesForDay(String day) {
    return _schedules.where((s) => s.dayOfWeek == day).toList();
  }

  Future<void> fetchSchedules() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.dio.get(
        '/schedules/',
        queryParameters: {'active_only': false},
      );
      final List<dynamic> data = response.data;
      _schedules = data.map((j) => ScheduleItem.fromJson(j)).toList();
    } catch (e) {
      print('Error fetching schedules: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSchedule(Map<String, dynamic> data) async {
    try {
      await _apiClient.dio.post('/schedules/', data: data);
      await fetchSchedules();
      return true;
    } catch (e) {
      print('Error adding schedule: $e');
      return false;
    }
  }

  Future<bool> updateSchedule(int id, Map<String, dynamic> data) async {
    try {
      await _apiClient.dio.put('/schedules/$id', data: data);
      await fetchSchedules();
      return true;
    } catch (e) {
      print('Error updating schedule: $e');
      return false;
    }
  }

  Future<bool> deleteSchedule(int id) async {
    try {
      await _apiClient.dio.delete('/schedules/$id');
      await fetchSchedules();
      return true;
    } catch (e) {
      print('Error deleting schedule: $e');
      return false;
    }
  }
}
