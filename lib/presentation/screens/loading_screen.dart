import 'package:flutter/material.dart';
import 'dart:async';
import 'question_screen.dart';
import '../../data/models/lesson.dart';

class LoadingScreen extends StatefulWidget {
  final Lesson lesson;
  const LoadingScreen({super.key, required this.lesson});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {

  @override
  void initState() {
    super.initState();

    // ⏳ Attendre 3 secondes puis aller sur QuestionScreen
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuestionScreen(lesson: widget.lesson),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade600,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animation chargement
            const CircularProgressIndicator(
              strokeWidth: 6,
              color: Colors.white,
            ),
            const SizedBox(height: 25),

            const Text(
              "Chargement...",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold
              ),
            ),
          ],
        ),
      ),
    );
  }
}
