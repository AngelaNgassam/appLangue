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

class _ChapterScreenState extends State<ChapterScreen>
    with SingleTickerProviderStateMixin {
  final ApiService apiService = ApiService();
  late Future<List<Chapter>> _chaptersFuture;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _chaptersFuture = fetchChapters();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<List<Chapter>> fetchChapters() async {
    final chaptersJson = await apiService.fetchChapters(widget.module.id);
    return chaptersJson.map<Chapter>((c) => Chapter.fromJson(c)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        backgroundColor: Colors.orange.shade600,
        title: Text(widget.module.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<Chapter>>(
        future: _chaptersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun chapitre disponible.'));
          } else {
            final chapters = snapshot.data!;
            _animationController.forward();

            return Padding(
              padding: const EdgeInsets.all(12),
              child: ListView.builder(
                itemCount: chapters.length,
                itemBuilder: (context, index) {
                  final chapter = chapters[index];

                  return FadeTransition(
                    opacity: Tween<double>(begin: 0, end: 1).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
                      ),
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
                        ),
                      ),
                      child: _buildChapterCard(chapter),
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildChapterCard(Chapter chapter) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, __, ___) => LessonScreen(chapter: chapter),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.orange.shade100,
              child: const Icon(Icons.book_rounded, color: Colors.orange, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              chapter.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              chapter.objective,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Row(
              children: const [
                Text(
                  "Commencer",
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange),
                ),
                Spacer(),
                Icon(Icons.arrow_forward_rounded, color: Colors.orange, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.orange.shade700),
          const SizedBox(height: 15),
          const Text(
            "Chargement des chapitres...",
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
