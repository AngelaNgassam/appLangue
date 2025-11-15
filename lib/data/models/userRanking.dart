class UserRanking {
  final String userId;
  final String userName;
  final int points;
  final int rank;

  UserRanking({
    required this.userId,
    required this.userName,
    required this.points,
    required this.rank,
  });

  factory UserRanking.fromJson(Map<String, dynamic> json, int index) {
    final user = json['user'];

    return UserRanking(
      userId: user['id'],
      userName: "${user['firstName']} ${user['lastName']}",
      points: json['point']?['value'] ?? 0,
      rank: index + 1,
    );
  }
}
