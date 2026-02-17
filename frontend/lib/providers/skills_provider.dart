import 'package:flutter/material.dart';
import '../core/api_client.dart';

class SkillStatus {
  final int skillId;
  final String skillName;
  bool isMastered;

  SkillStatus({
    required this.skillId,
    required this.skillName,
    required this.isMastered,
  });

  factory SkillStatus.fromJson(Map<String, dynamic> json) {
    return SkillStatus(
      skillId: json['skill_id'],
      skillName: json['skill_name'],
      isMastered: json['is_mastered'] ?? false,
    );
  }
}

class SkillsProvider with ChangeNotifier {
  final ApiClient _apiClient;
  bool _isLoading = false;

  SkillsProvider(this._apiClient);

  bool get isLoading => _isLoading;

  /// Fetch all 14 skills with is_mastered status for a specific member
  Future<List<SkillStatus>> fetchMemberSkills(int memberId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        '/skills/members/$memberId/status',
      );

      final List<dynamic> data = response.data;
      return data.map((json) => SkillStatus.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching member skills: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Batch update: send list of mastered skill IDs
  Future<void> updateMemberSkills(
    int memberId,
    List<int> masteredSkillIds,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiClient.dio.put(
        '/skills/members/$memberId/batch',
        data: {'mastered_skill_ids': masteredSkillIds},
      );
    } catch (e) {
      print('Error updating member skills: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle a single skill for a member (instant switch)
  Future<bool> toggleSkill(int memberId, int skillId, bool isMastered) async {
    try {
      if (isMastered) {
        await _apiClient.dio.post(
          '/skills/members/$memberId',
          data: {'skill_id': skillId},
        );
      } else {
        await _apiClient.dio.delete('/skills/members/$memberId/$skillId');
      }
      return true;
    } catch (e) {
      print("Error toggling skill: $e");
      return false;
    }
  }
}
