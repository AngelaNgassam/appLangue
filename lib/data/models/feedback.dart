class FeedbackModel {
  final String id;
  final String userId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  // 🔹 Conversion JSON → FeedbackModel
  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'],
      userId: json['userId'],
      rating: json['rating'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  // 🔹 Conversion FeedbackModel → JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
