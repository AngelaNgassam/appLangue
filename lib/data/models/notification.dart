// models/notification.dart

class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String message;
   bool isRead;
  final bool isBroadcast;
  final DateTime sentAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    required this.isRead,
    required this.isBroadcast,
    required this.sentAt,
  });

  // Conversion JSON → Objet
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['userId'],
      type: json['type'],
      message: json['message'],
      isRead: json['isRead'] ?? false,
      isBroadcast: json['isBroadcast'] ?? false,
      sentAt: DateTime.parse(json['sentAt']),
    );
  }

  // Conversion Objet → JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'message': message,
      'isRead': isRead,
      'isBroadcast': isBroadcast,
      'sentAt': sentAt.toIso8601String(),
    };
  }

  // Copier l'objet avec des modifications (utile pour mettre isRead à true)
  AppNotification copyWith({
    String? id,
    String? userId,
    String? type,
    String? message,
    bool? isRead,
    bool? isBroadcast,
    DateTime? sentAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      isBroadcast: isBroadcast ?? this.isBroadcast,
      sentAt: sentAt ?? this.sentAt,
    );
  }
}
