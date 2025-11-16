import 'package:KmerLingo/core/services/api_service.dart';
import 'package:KmerLingo/presentation/screens/feeback_Screen.dart';
import 'package:KmerLingo/presentation/screens/modules_screen.dart';
import 'package:KmerLingo/presentation/screens/profile_screen.dart';
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
      ProfileScreen(userId: widget.userId),
      FeedbackScreen(userId: widget.userId),
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
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Feedback'),
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
// ---------------- STATISTICS ----------------
class StatisticsScreen extends StatefulWidget {
  final String userId;

  const StatisticsScreen({super.key, required this.userId});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService api = ApiService();
  late Future<Map<String, dynamic>> statsFuture;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    statsFuture = api.fetchUserStats(widget.userId);

    // ✅ AnimationController correctement initialisé
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // On lance l’animation après la frame initiale pour éviter l’erreur
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text("Statistiques"),
        backgroundColor: Colors.blue.shade600,
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
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
          final points = stats["points"];
          final progression = stats["progression"];
          final ranking = stats["ranking"];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatCard(
                  title: "Total Points",
                  value: "${points['totalPoints']} pts",
                  icon: Icons.star_rounded,
                  color: Colors.orange,
                  index: 0,
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  title: "Division",
                  value: ranking != null
                      ? "${ranking['division']} (Rank ${ranking['rank']})"
                      : "Non classé",
                  icon: Icons.leaderboard_rounded,
                  color: Colors.deepPurple,
                  index: 1,
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  title: "Questions Correctes",
                  value: "${progression['correct']}",
                  icon: Icons.check_circle_rounded,
                  color: Colors.green,
                  index: 2,
                ),
                _buildStatCard(
                  title: "Questions Incorrectes",
                  value: "${progression['wrong']}",
                  icon: Icons.cancel_rounded,
                  color: Colors.red,
                  index: 3,
                ),
                _buildStatCard(
                  title: "Précision",
                  value: "${progression['accuracy']}%",
                  icon: Icons.percent_rounded,
                  color: Colors.teal,
                  index: 4,
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  title: "Leçons Complétées",
                  value: "${progression['lessonsCompleted']}",
                  icon: Icons.menu_book_rounded,
                  color: Colors.blue,
                  index: 5,
                ),
                const SizedBox(height: 16),
                if (progression["byLanguage"] != null)
                  ..._buildLanguageStats(progression["byLanguage"]),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Carte Statistique avec animation FadeTransition
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required int index,
  }) {
    // Chaque carte a un intervalle différent pour un effet “staggered”
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        index * 0.1,
        1.0,
        curve: Curves.easeOut,
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        shadowColor: color.withOpacity(0.3),
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
      ),
    );
  }

  List<Widget> _buildLanguageStats(Map<String, dynamic> languages) {
    List<Widget> widgets = [];
    int i = 6; // Commence après les premières cartes
    languages.forEach((lang, data) {
      widgets.add(
        _buildStatCard(
          title: "Langue : $lang",
          value:
              "Total: ${data['total']}  |  ✓ ${data['correct']}  × ${data['wrong']}",
          icon: Icons.language_rounded,
          color: Colors.indigo,
          index: i++,
        ),
      );
    });
    return widgets;
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.orange.shade700),
          const SizedBox(height: 16),
          const Text(
            "Chargement des statistiques...",
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}