class Division {
  final String id;
  final String name;
  final int pointThreshold;
  final int order;

  Division({
    required this.id,
    required this.name,
    required this.pointThreshold,
    required this.order,
  });

  factory Division.fromJson(Map<String, dynamic> json) {
    return Division(
      id: json['id'],
      name: json['name'],
      pointThreshold: json['pointThreshold'],
      order: json['order'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'pointThreshold': pointThreshold,
        'order': order,
      };
}
