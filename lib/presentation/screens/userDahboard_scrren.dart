import 'package:KmerLingo/core/constants/colors.dart';
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
    _loadUnreadCount();

    _screens = [
      HomeScreen(userId: widget.userId),
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
        selectedItemColor: AppColors.warning,
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
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
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

/// ---------------- HOME SCREEN REDESIGNED ----------------
class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? profile;
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final PageController _carouselController = PageController();
  int _currentCarouselPage = 0;

  final List<Map<String, dynamic>> carouselItems = [
    {
      'title': 'Apprends le Duala',
      'description':
          'Découvre la langue et la culture Duala, parlée au Cameroun',
      'icon': Icons.language_rounded,
      'color': Color(0xFF4CAF50),
    },
    {
      'title': 'Maîtrise le Bafut',
      'description': 'Plonge dans la richesse linguistique du Bafut',
      'icon': Icons.school_rounded,
      'color': Color(0xFF2196F3),
    },
    {
      'title': 'Explore le Medumba',
      'description': 'Une langue fascinante de l\'Ouest Cameroun',
      'icon': Icons.explore_rounded,
      'color': Color(0xFFFF9800),
    },
    {
      'title': 'Progresse chaque jour',
      'description': 'Accumule des points et grimpe dans le classement',
      'icon': Icons.trending_up_rounded,
      'color': Color(0xFF9C27B0),
    },
  ];

  @override
  void initState() {
    super.initState();
    loadProfile();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  Future<void> loadProfile() async {
    try {
      final data = await ApiService().getProfile(widget.userId);
      setState(() {
        profile = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print("❌ Error loading profile: $e");
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _carouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : CustomScrollView(
              slivers: [
                // En-tête avec dégradé vert
                SliverAppBar(
                  expandedHeight: 120,
                  floating: false,
                  pinned: true,
                  backgroundColor: const Color(0xFF4CAF50),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4CAF50),
                            const Color(0xFF66BB6A),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Salut + Nom
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Salut,',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      profile != null
                                          ? '${profile!['firstName']} ${profile!['lastName']}'
                                          : 'Utilisateur',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              // Icônes Profile et Notifications
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.person_rounded,
                                          color: Colors.white),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ProfileScreen(
                                                userId: widget.userId),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                          Icons.notifications_rounded,
                                          color: Colors.white),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => NotificationScreen(
                                              userId: widget.userId,
                                              onReadChanged: () {},
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Contenu principal
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),

                          // Carousel descriptif
                          SizedBox(
                            height: 220,
                            child: PageView.builder(
                              controller: _carouselController,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentCarouselPage = index;
                                });
                              },
                              itemCount: carouselItems.length,
                              itemBuilder: (context, index) {
                                return _buildCarouselCard(
                                    carouselItems[index]);
                              },
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Indicateurs de carousel
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              carouselItems.length,
                              (index) => Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                width: _currentCarouselPage == index ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _currentCarouselPage == index
                                      ? const Color(0xFF4CAF50)
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // 3 Box de navigation
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildNavigationBox(
                                        title: 'Cours',
                                        icon: Icons.menu_book_rounded,
                                        color: const Color(0xFF4CAF50),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ModuleScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildNavigationBox(
                                        title: 'Statistiques',
                                        icon: Icons.analytics_rounded,
                                        color: const Color(0xFF2196F3),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => StatisticsScreen(
                                                  userId: widget.userId),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildNavigationBox(
                                  title: 'Classement',
                                  icon: Icons.emoji_events_rounded,
                                  color: const Color(0xFFFF9800),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            DivisionLeaderboardPage(
                                                userId: widget.userId),
                                      ),
                                    );
                                  },
                                  fullWidth: true,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCarouselCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            item['color'],
            item['color'].withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: item['color'].withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item['icon'],
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              item['title'],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              item['description'],
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBox({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: fullWidth ? 140 : 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- STATISTICS (inchangé) ----------------
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

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

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

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required int index,
  }) {
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
    int i = 6;
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