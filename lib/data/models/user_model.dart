class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String role;

  final int currentStreak;      // 🔥 nouveau
  final int maxStreak;          // 🔥 nouveau
  final DateTime? lastActivityAt; // 🔥 nouveau

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    required this.currentStreak,
    required this.maxStreak,
    required this.lastActivityAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'] ?? 'USER', // 👈 correction, c’est "role" en minuscule

      currentStreak: json['currentStreak'] ?? 0,
      maxStreak: json['maxStreak'] ?? 0,
      lastActivityAt: json['lastActivityAt'] != null
          ? DateTime.parse(json['lastActivityAt'])
          : null,
    );
  }
}
