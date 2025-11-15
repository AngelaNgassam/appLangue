import 'package:KmerLingo/core/services/api_service.dart';
import 'package:KmerLingo/presentation/screens/modules_screen.dart';
import 'package:KmerLingo/presentation/screens/rankingScreen.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  final String userId;

  const MainScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(),
      DivisionLeaderboardPage(userId: widget.userId),
      StatisticsScreen(userId: widget.userId),
      ModuleScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events_rounded), label: 'Classement'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Statistiques'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Cours'),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

/// ---------------- HOME SCREEN ----------------
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.lightBlue.shade200, Colors.blue.shade600],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.language_rounded, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Bienvenue sur KmerLingo !',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              'Apprends des langues, progresse et deviens champion !',
              style: TextStyle(fontSize: 18, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------- STATISTICS ----------------
class StatisticsScreen extends StatefulWidget {
  final String userId;

  const StatisticsScreen({super.key, required this.userId});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final ApiService api = ApiService();
  late Future<Map<String, dynamic>> statsFuture;

  @override
  void initState() {
    super.initState();
    statsFuture = api.fetchUserStats(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        title: const Text("Statistiques"),
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Erreur : ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final stats = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                /// Total points card
                _buildStatCard(
                  title: "Total Points",
                  value: "${stats['totalPoints']} pts",
                  icon: Icons.star_rounded,
                  color: Colors.orange,
                ),

                const SizedBox(height: 20),

                /// Questions correct / incorrect
                _buildStatCard(
                  title: "Questions Correctes",
                  value: "${stats['questionsCorrect']}",
                  icon: Icons.check_circle_rounded,
                  color: Colors.green,
                ),
                _buildStatCard(
                  title: "Questions Incorrectes",
                  value: "${stats['questionsWrong']}",
                  icon: Icons.cancel_rounded,
                  color: Colors.red,
                ),

                const SizedBox(height: 20),

                /// Lessons completed
                _buildStatCard(
                  title: "Leçons Complétées",
                  value: "${stats['totalLessonsCompleted']}",
                  icon: Icons.menu_book_rounded,
                  color: Colors.blue,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, size: 30, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
