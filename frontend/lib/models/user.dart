enum UserRole { OWNER, COACH, PARENT }

class User {
  final int id;
  final String email;
  final String fullName;
  final UserRole role;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      role: _parseRole(json['role']),
    );
  }

  static UserRole _parseRole(String roleBase) {
    switch (roleBase) {
      case 'OWNER':
        return UserRole.OWNER;
      case 'COACH':
        return UserRole.COACH;
      case 'PARENT':
        return UserRole.PARENT;
      default:
        return UserRole.PARENT;
    }
  }
}
