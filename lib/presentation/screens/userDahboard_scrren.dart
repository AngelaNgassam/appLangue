import 'package:flutter/material.dart';
import 'package:KmerLingo/core/services/api_service.dart';
import 'package:KmerLingo/presentation/screens/feeback_Screen.dart';
import 'package:KmerLingo/presentation/screens/modules_screen.dart';
import 'package:KmerLingo/presentation/screens/notification_screen.dart';
import 'package:KmerLingo/presentation/screens/profile_screen.dart';
import 'package:KmerLingo/presentation/screens/rankingScreen.dart';

class MainScreen extends StatefulWidget {
  final String userId;

  const MainScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final ApiService api = ApiService();
  int unreadCount = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount(); // Charger le nombre de notifications non lues au démarrage

    _screens = [
      HomeScreen(),
      DivisionLeaderboardPage(userId: widget.userId),
      StatisticsScreen(userId: widget.userId),
      ModuleScreen(),
      ProfileScreen(userId: widget.userId),
      FeedbackScreen(userId: widget.userId),
      NotificationScreen(
        userId: widget.userId,
        onReadChanged: () => _loadUnreadCount(),
      ),
    ];
  }

  Future<void> _loadUnreadCount() async {
    final notifications = await api.fetchNotifications(widget.userId);
    setState(() {
      unreadCount = notifications.where((n) => !n.isRead).length;
    });
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
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'Accueil'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_rounded), label: 'Classement'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.analytics_rounded), label: 'Statistiques'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_rounded), label: 'Cours'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: 'Profile'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.feedback_rounded), label: 'Feedback'),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_rounded),
                if (unreadCount > 0)
                  Positioned(
                    right: -6,
                    top: -3,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Notifications',
          ),
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
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(25),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade800,
              Colors.blue.shade500,
              Colors.lightBlue.shade300,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // 🔥 ICON + ANIMATION
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              tween: Tween(begin: 0, end: 1),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.language_rounded,
                  size: 110,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 35),

            // ⭐ TITRE PRINCIPAL
            const Text(
              "Bienvenue sur KmerLingo",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.3,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 15),

            // 📘 SOUS-TEXTE / SLOGAN
            const Text(
              "Améliore ton niveau en langues avec plaisir.\n"
              "Progresse chaque jour, débloque des niveaux\n"
              "et deviens un vrai champion du langage !",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                color: Colors.white70,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 40),

            // 🔥 BOUTON START (optionnel)
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOut,
              tween: Tween(begin: 0, end: 1),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: child,
                );
              },
              child: GestureDetector(
                onTap: () {
                  // → Navigation si tu veux
                  // Navigator.push(context, MaterialPageRoute(builder: (_) => NextScreen()));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Text(
                    "Commencer",
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
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