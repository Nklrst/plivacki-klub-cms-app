import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/member.dart';
import '../models/schedule.dart';
import '../models/enrollment.dart';
import '../models/skill.dart';

class MemberProvider with ChangeNotifier {
  final ApiClient _apiClient;
  List<Member> _members = [];
  bool _isLoading = false;

  // Konstruktor prima ApiClient (pravilno)
  MemberProvider(this._apiClient);

  List<Member> get members => [..._members];
  bool get isLoading => _isLoading;

  // --- MEMBERS (CRUD) ---

  Future<void> fetchMyMembers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/members/mine');
      final List<dynamic> data = response.data;
      _members = data.map((json) => Member.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching members: $e');
      // Ne radimo rethrow da ne bismo srušili UI ako nema interneta
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateMember(
    int id,
    String fullName,
    DateTime birthDate,
    String? notes,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final memberData = {
        'full_name': fullName,
        'date_of_birth': birthDate.toIso8601String().split('T')[0],
        'notes': notes,
      };

      await _apiClient.dio.put('/members/$id', data: memberData);
      await fetchMyMembers(); // Osveži listu
    } catch (e) {
      print('Error updating member: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMember(
    String fullName,
    DateTime birthDate,
    String? notes,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final memberData = {
        'full_name': fullName,
        'date_of_birth': birthDate.toIso8601String().split('T')[0],
        'notes': notes,
      };

      await _apiClient.dio.post('/members/', data: memberData);
      await fetchMyMembers();
    } catch (e) {
      print('Error adding member: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- SCHEDULES & ENROLLMENTS ---

  Future<List<Schedule>> fetchSchedules() async {
    try {
      final response = await _apiClient.dio.get('/schedules/?active_only=true');
      final List<dynamic> data = response.data;
      return data.map((json) => Schedule.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching schedules: $e');
      return [];
    }
  }

  Future<List<Enrollment>> fetchEnrollments(int memberId) async {
    try {
      final response = await _apiClient.dio.get(
        '/schedules/members/$memberId/enrollments',
      );
      final List<dynamic> data = response.data;
      return data.map((json) => Enrollment.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching enrollments: $e');
      return [];
    }
  }

  Future<void> enrollMember(
    int memberId,
    int scheduleId,
    DateTime startDate,
  ) async {
    try {
      final data = {
        'member_id': memberId,
        'schedule_id': scheduleId,
        'start_date': startDate.toIso8601String().split('T')[0],
      };
      await _apiClient.dio.post('/schedules/enrollments', data: data);
      await fetchMyMembers(); // Osveži da se vidi na dashboardu
    } catch (e) {
      print('Error enrolling member: $e');
      rethrow;
    }
  }

  // --- NOVO: ZAHTEV ZA PROMENU TERMINA ---

  Future<void> sendScheduleRequest(String message) async {
    try {
      await _apiClient.dio.post(
        '/schedules/requests',
        data: {'message': message, 'request_type': 'CHANGE_REQUEST'},
      );
      print("Zahtev poslat: $message");
    } catch (e) {
      print('Error sending request: $e');
      // Samo ispišemo grešku, ne rušimo aplikaciju
    }
  }

  // --- SKILLS (Veštine) ---

  Future<List<Skill>> fetchAllSkills() async {
    try {
      final response = await _apiClient.dio.get('/skills/');
      final List<dynamic> data = response.data;
      return data.map((json) => Skill.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching skills: $e');
      return [];
    }
  }

  Future<List<MemberSkill>> fetchMemberSkills(int memberId) async {
    try {
      final response = await _apiClient.dio.get('/skills/members/$memberId');
      final List<dynamic> data = response.data;
      return data.map((json) => MemberSkill.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching member skills: $e');
      return [];
    }
  }
}
