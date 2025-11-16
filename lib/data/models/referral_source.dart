class ReferralSource {
  final String id;
  final String label;

  ReferralSource({required this.id, required this.label});

  factory ReferralSource.fromJson(Map<String, dynamic> json) {
    return ReferralSource(
      id: json['id'],
      label: json['label'],
    );
  }
}
