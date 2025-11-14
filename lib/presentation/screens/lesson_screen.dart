import 'package:KmerLingo/core/services/api_service.dart';
import 'package:flutter/material.dart';
import '../../data/models/chapter.dart';
import '../../data/models/lesson.dart';
import 'question_screen.dart';

class LessonScreen extends StatefulWidget {
  final Chapter chapter;
  const LessonScreen({Key? key, required this.chapter}) : super(key: key);

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final ApiService apiService = ApiService();
  late Future<List<Lesson>> _lessonsFuture;

  @override
  void initState() {
    super.initState();
    _lessonsFuture = fetchLessons();
  }

  Future<List<Lesson>> fetchLessons() async {
    final lessonsJson = await apiService.fetchLessons(widget.chapter.id);
    return lessonsJson.map<Lesson>((l) => Lesson.fromJson(l)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chapter.title),
      ),
      body: FutureBuilder<List<Lesson>>(
        future: _lessonsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune leçon disponible.'));
          } else {
            final lessons = snapshot.data!;
            return ListView.builder(
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(lesson.title),
                    subtitle: Text(lesson.objective),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      // Naviguer vers les questions de la leçon
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              QuestionScreen(lesson: lesson),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
