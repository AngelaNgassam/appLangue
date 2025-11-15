class Point {
  String id;
  String userId;
  int value;
  DateTime updatedAt;

  Point({
    required this.id,
    required this.userId,
    required this.value,
    required this.updatedAt,
  });

  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      id: json['id'],
      userId: json['userId'],
      value: json['value'],
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "userId": userId,
      "value": value,
      "updatedAt": updatedAt.toIso8601String(),
    };
  }
}
