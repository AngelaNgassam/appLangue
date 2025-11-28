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

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final ApiService api = ApiService();
  int unreadCount = 0;
  late final List<Widget> _screens;
  Map<String, dynamic>? userProfile;
  bool profileLoading = true;
  late AnimationController _navAnimationController;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _loadUserProfile();
    _navAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
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

  Future<void> _loadUserProfile() async {
    try {
      final data = await api.getProfile(widget.userId);
      setState(() {
        userProfile = data;
        profileLoading = false;
      });
    } catch (e) {
      setState(() => profileLoading = false);
      print("❌ Error loading profile: $e");
    }
  }

  @override
  void dispose() {
    _navAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildAnimatedBottomNav(),
    );
  }

  Widget _buildAnimatedBottomNav() {
    final navItems = [
      {'icon': Icons.home_rounded, 'label': 'Accueil'},
      {'icon': Icons.emoji_events_rounded, 'label': 'Classement'},
      {'icon': Icons.analytics_rounded, 'label': 'Statistiques'},
      {'icon': Icons.menu_book_rounded, 'label': 'Cours'},
      {'icon': Icons.feedback_rounded, 'label': 'Feedback'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.only(top: 12, bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(navItems.length, (index) {
            final isActive = _currentIndex == index;
            return _buildNavItem(
              icon: navItems[index]['icon'] as IconData,
              label: navItems[index]['label'] as String,
              index: index,
              isActive: isActive,
            );
          }),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        _navAnimationController.forward(from: 0);
      },
      child: AnimatedBuilder(
        animation: _navAnimationController,
        builder: (context, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Cercle de fond animé
                  if (isActive)
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _navAnimationController,
                          curve: Curves.elasticOut,
                        ),
                      ),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF4CAF50).withOpacity(0.2),
                              Color(0xFFB4E7B4).withOpacity(0.3),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF4CAF50).withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Icône avec animation
                  Transform.translate(
                    offset: Offset(0, isActive ? -8 : 0),
                    child: Icon(
                      index == 5 ? Icons.notifications_rounded : icon,
                      size: isActive ? 28 : 24,
                      color: isActive
                          ? Color(0xFF4CAF50)
                          : Colors.grey.shade400,
                    ),
                  ),
                  // Badge notifications
                  if (index == 5 && unreadCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: AnimatedScale(
                        scale: isActive ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? Color(0xFF4CAF50)
                      : Colors.grey.shade500,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ============= HOME SCREEN =============
class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  Map<String, dynamic>? userProfile;
  bool profileLoading = true;
  late AnimationController _headerAnimController;
  late AnimationController _cardAnimController;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _headerAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cardAnimController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _headerAnimController.forward();
        _cardAnimController.forward();
      }
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      final data = await ApiService().getProfile(widget.userId);
      setState(() {
        userProfile = data;
        profileLoading = false;
      });
    } catch (e) {
      setState(() => profileLoading = false);
      print("❌ Error loading profile: $e");
    }
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _cardAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildWelcomeSection(),
            const SizedBox(height: 40),
            _buildActionCards(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOut),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4CAF50),
              Color(0xFF66BB6A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF4CAF50).withOpacity(0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Salut 👋',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profileLoading
                        ? 'Chargement...'
                        : '${userProfile?['firstName'] ?? ''} ${userProfile?['lastName'] ?? ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Row(
              children: [
                _buildHeaderIconButton(
                  icon: Icons.person_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(userId: widget.userId),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                _buildHeaderIconButton(
                  icon: Icons.notifications_rounded,
                  onTap: () {
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _headerAnimController, curve: Curves.easeIn),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenue sur KmerLingo ! 🌍',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Apprends les langues locales camerounaises, progresse et deviens champion !',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCards() {
    final cards = [
      {
        'title': 'Cours',
        'icon': Icons.menu_book_rounded,
        'color': Color(0xFF4CAF50),
        'route': ModuleScreen(),
        'index': 0,
      },
      {
        'title': 'Statistiques',
        'icon': Icons.analytics_rounded,
        'color': Color(0xFFFDD835),
        'route': StatisticsScreen(userId: widget.userId),
        'index': 1,
      },
      {
        'title': 'Classement',
        'icon': Icons.emoji_events_rounded,
        'color': Color(0xFF42A5F5),
        'route': DivisionLeaderboardPage(userId: widget.userId),
        'index': 2,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(
          cards.length,
          (index) {
            final card = cards[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _cardAnimController,
                    curve: Interval(
                      index * 0.15,
                      (index * 0.15) + 0.6,
                      curve: Curves.easeOut,
                    ),
                  ),
                ),
                child: _buildActionCard(
                  title: card['title'] as String,
                  icon: card['icon'] as IconData,
                  color: card['color'] as Color,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => card['route'] as Widget,
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Accédez maintenant',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: color,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

// ============= STATISTICS SCREEN (inchangé) =============
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
                const SizedBox(height: 16),
                _buildStatCard(
                  title: "Questions Incorrectes",
                  value: "${progression['wrong']}",
                  icon: Icons.cancel_rounded,
                  color: Colors.red,
                  index: 3,
                ),
                const SizedBox(height: 16),
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
          value: "Total: ${data['total']} | ✓ ${data['correct']} ✗ ${data['wrong']}",
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