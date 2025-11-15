class Ranking {
  String id;
  String userId;
  String pointId;
  int rank;
  String divisionId;
  DateTime periodStart;
  DateTime periodEnd;

  Ranking({
    required this.id,
    required this.userId,
    required this.pointId,
    required this.rank,
    required this.divisionId,
    required this.periodStart,
    required this.periodEnd,
  });

  factory Ranking.fromJson(Map<String, dynamic> json) {
    return Ranking(
      id: json['id'],
      userId: json['userId'],
      pointId: json['pointId'],
      rank: json['rank'],
      divisionId: json['divisionId'],
      periodStart: DateTime.parse(json['periodStart']),
      periodEnd: DateTime.parse(json['periodEnd']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "userId": userId,
      "pointId": pointId,
      "rank": rank,
      "divisionId": divisionId,
      "periodStart": periodStart.toIso8601String(),
      "periodEnd": periodEnd.toIso8601String(),
    };
  }
}
