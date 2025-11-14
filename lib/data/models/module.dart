import 'chapter.dart';
class Module {
  String id;
  String title;
  String description;
  int order;
  List<Chapter> chapters;

  Module({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.chapters,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      order: json['order'],
      chapters: json['chapters'] != null
          ? (json['chapters'] as List)
              .map((c) => Chapter.fromJson(c))
              .toList()
          : [],
    );
  }
}