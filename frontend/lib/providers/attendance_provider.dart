import 'package:flutter/material.dart';
// [FIX] Dodat import zbog tipova
import '../core/api_client.dart';

class AttendanceRecord {
  final int id;
  final int memberId;
  final String memberName;
  final String? birthDate;
  final DateTime date;
  bool isPresent;
  final String? parentPhone;
  final String? medicalNotes;

  AttendanceRecord({
    required this.id,
    required this.memberId,
    required this.memberName,
    this.birthDate,
    required this.date,
    required this.isPresent,
    this.parentPhone,
    this.medicalNotes,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? 0,
      memberId: json['member_id'] ?? 0,
      memberName: json['member_name'] ?? 'Član #${json['member_id']}',
      birthDate: json['birth_date'],
      date: DateTime.parse(json['date']),
      isPresent: json['is_present'] ?? false,
      parentPhone: json['parent_phone'],
      medicalNotes: json['medical_notes'],
    );
  }
}

class AttendanceProvider with ChangeNotifier {
  final ApiClient _apiClient;
  bool _isLoading = false;

  // Stanje koje koristi tvoj UI
  List<AttendanceRecord> _attendanceList = [];

  AttendanceProvider(this._apiClient);

  bool get isLoading => _isLoading;
  List<AttendanceRecord> get attendanceList => _attendanceList;

  // 1. Učitavanje liste - HIBRIDNI PRISTUP
  // Vraća Future<List> (za Agenta) ALI i ažurira _attendanceList (za nas)
  Future<List<AttendanceRecord>> fetchGroupMembers(
    int scheduleId,
    DateTime date,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await _apiClient.dio.get(
        '/attendance/schedule/$scheduleId/date/$dateStr',
      );

      final List<dynamic> data = response.data;
      final records = data
          .map((json) => AttendanceRecord.fromJson(json))
          .toList();

      // [BITNO] Ažuriramo stanje u provajderu
      _attendanceList = records;

      _isLoading = false;
      notifyListeners();

      return records; // [BITNO] Vraćamo listu da zadovoljimo Agenta/Stari kod
    } catch (e) {
      print('Error fetching attendance: $e');
      _attendanceList = [];
      _isLoading = false;
      notifyListeners();
      return []; // Vraćamo praznu listu u slučaju greške
    }
  }

  // 2. Toggle Status
  void toggleAttendance(int memberId) {
    final index = _attendanceList.indexWhere(
      (element) => element.memberId == memberId,
    );
    if (index != -1) {
      _attendanceList[index].isPresent = !_attendanceList[index].isPresent;
      notifyListeners();
    }
  }

  // 3. Čuvanje prisustva
  Future<void> saveAttendance(
    int scheduleId,
    DateTime date,
    List<int> presentMemberIds,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final data = {
        'schedule_id': scheduleId,
        'date': dateStr,
        'member_ids': presentMemberIds,
      };

      await _apiClient.dio.post('/attendance/batch', data: data);
    } catch (e) {
      print('Error saving attendance: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
