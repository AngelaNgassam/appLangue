import 'package:KmerLingo/core/services/api_service.dart';
import 'package:flutter/material.dart';
import '../../data/models/chapter.dart';
import '../../data/models/lesson.dart';
import 'loading_screen.dart';  // 👉 IMPORT AJOUTÉ

class LessonScreen extends StatefulWidget {
  final Chapter chapter;
  const LessonScreen({Key? key, required this.chapter}) : super(key: key);

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen>
    with SingleTickerProviderStateMixin {
  final ApiService apiService = ApiService();
  late Future<List<Lesson>> _lessonsFuture;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _lessonsFuture = fetchLessons();

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

  Future<List<Lesson>> fetchLessons() async {
    final lessonsJson = await apiService.fetchLessons(widget.chapter.id);
    return lessonsJson.map<Lesson>((l) => Lesson.fromJson(l)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade600,
        title: Text(
          widget.chapter.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<Lesson>>(
        future: _lessonsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune leçon disponible.'));
          } else {
            final lessons = snapshot.data!;
            _animationController.forward();

            return Padding(
              padding: const EdgeInsets.all(12),
              child: ListView.builder(
                itemCount: lessons.length,
                itemBuilder: (context, index) {
                  final lesson = lessons[index];

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
                      child: _buildLessonCard(lesson),
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

  Widget _buildLessonCard(Lesson lesson) {
    return GestureDetector(
      onTap: () {
        // 👉 AFFICHER LE LOADING SCREEN 3 SECONDES AVANT LES QUESTIONS
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LoadingScreen(lesson: lesson),
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
              backgroundColor: Colors.green.shade100,
              child: const Icon(Icons.menu_book_rounded, color: Colors.green, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              lesson.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              lesson.objective,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Row(
              children: const [
                Text(
                  "Commencer",
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green),
                ),
                Spacer(),
                Icon(Icons.arrow_forward_rounded, color: Colors.green, size: 20),
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
          CircularProgressIndicator(color: Colors.green.shade700),
          const SizedBox(height: 15),
          const Text(
            "Chargement des leçons...",
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
