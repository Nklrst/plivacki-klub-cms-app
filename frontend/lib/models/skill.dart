class Skill {
  final int id;
  final String name;
  final String description;
  final String category;
  final int displayOrder;

  Skill({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.displayOrder,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      category: json['category_label'] ?? json['category'] ?? 'Opšte',
      displayOrder: json['display_order'] ?? 0,
    );
  }
}

class MemberSkill {
  final int id;
  final int memberId;
  final int skillId;
  final DateTime acquiredAt;

  MemberSkill({
    required this.id,
    required this.memberId,
    required this.skillId,
    required this.acquiredAt,
  });

  factory MemberSkill.fromJson(Map<String, dynamic> json) {
    // [FIX] Logika za izvlačenje ID-ja veštine
    int extractedSkillId = 0;
    if (json['skill_id'] != null) {
      extractedSkillId = json['skill_id'];
    } else if (json['skill'] != null && json['skill']['id'] != null) {
      extractedSkillId = json['skill']['id'];
    }

    return MemberSkill(
      id: json['id'],
      memberId: json['member_id'] ?? 0,
      skillId: extractedSkillId, // Ovde sada sigurno dobijamo ID
      acquiredAt: json['acquired_at'] != null
          ? DateTime.parse(json['acquired_at'])
          : DateTime.now(),
    );
  }
}
