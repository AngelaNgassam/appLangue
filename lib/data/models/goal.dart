class Goal {
  final String id;
  final String label;

  Goal({required this.id, required this.label});

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'],
      label: json['label'],
    );
  }
}
