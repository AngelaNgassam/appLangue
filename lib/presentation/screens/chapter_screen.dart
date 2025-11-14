import 'package:KmerLingo/core/services/api_service.dart';
import 'package:flutter/material.dart';
import '../../data/models/module.dart';
import '../../data/models/chapter.dart';
import 'lesson_screen.dart';

class ChapterScreen extends StatefulWidget {
  final Module module;
  const ChapterScreen({Key? key, required this.module}) : super(key: key);

  @override
  State<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<ChapterScreen> {
  final ApiService apiService = ApiService();
  late Future<List<Chapter>> _chaptersFuture;

  @override
  void initState() {
    super.initState();
    _chaptersFuture = fetchChapters();
  }

  Future<List<Chapter>> fetchChapters() async {
    final chaptersJson = await apiService.fetchChapters(widget.module.id);
    return chaptersJson.map<Chapter>((c) => Chapter.fromJson(c)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.module.title),
      ),
      body: FutureBuilder<List<Chapter>>(
        future: _chaptersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun chapitre disponible.'));
          } else {
            final chapters = snapshot.data!;
            return ListView.builder(
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(chapter.title),
                    subtitle: Text(chapter.objective),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      // Naviguer vers les leçons
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              LessonScreen(chapter: chapter),
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
