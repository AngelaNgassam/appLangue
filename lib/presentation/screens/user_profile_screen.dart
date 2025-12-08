import 'package:KmerLingo/core/services/api_service.dart';
import 'package:flutter/material.dart';

class UserProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  bool isFollowing = false;
  int followersCount = 0;
  int followingCount = 0;
  
  List<dynamic> followers = [];
  List<dynamic> following = [];
  bool isLoadingFollowers = true;
  bool isLoadingFollowing = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    isFollowing = widget.user['isFollowing'] ?? false;
    followersCount = widget.user['followersCount'] ?? 0;
    followingCount = widget.user['followingCount'] ?? 0;
    
    _loadFollowers();
    _loadFollowing();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ============================================
  // 📋 CHARGER LES FOLLOWERS
  // ============================================
  Future<void> _loadFollowers() async {
    setState(() => isLoadingFollowers = true);
    try {
      final data = await _apiService.getUserFollowers(widget.user['id']);
      setState(() {
        followers = data;
        isLoadingFollowers = false;
      });
    } catch (e) {
      print('❌ Erreur chargement followers: $e');
      setState(() => isLoadingFollowers = false);
    }
  }

  // ============================================
  // 📋 CHARGER LES FOLLOWING
  // ============================================
  Future<void> _loadFollowing() async {
    setState(() => isLoadingFollowing = true);
    try {
      final data = await _apiService.getUserFollowing(widget.user['id']);
      setState(() {
        following = data;
        isLoadingFollowing = false;
      });
    } catch (e) {
      print('❌ Erreur chargement following: $e');
      setState(() => isLoadingFollowing = false);
    }
  }

  // ============================================
  // 👥 SUIVRE / NE PLUS SUIVRE
  // ============================================
  Future<void> _toggleFollow() async {
    try {
      if (isFollowing) {
        await _apiService.unfollowUser(widget.user['id']);
        _showSuccess('Vous ne suivez plus cet utilisateur');
        setState(() {
          isFollowing = false;
          followersCount--;
        });
      } else {
        await _apiService.followUser(widget.user['id']);
        _showSuccess('Vous suivez maintenant cet utilisateur');
        setState(() {
          isFollowing = true;
          followersCount++;
        });
      }
    } catch (e) {
      print('❌ Erreur toggle follow: $e');
      _showError('Une erreur est survenue');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.user['firstName'] ?? '';
    final lastName = widget.user['lastName'] ?? '';
    final email = widget.user['email'] ?? '';
    final currentStreak = widget.user['currentStreak'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // ============================================
            // 📱 HEADER AVEC GRADIENT
            // ============================================
            SliverAppBar(
              expandedHeight: 300,
              floating: false,
              pinned: true,
              backgroundColor: Colors.blue.shade700,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade800,
                        Colors.blue.shade600,
                        Colors.purple.shade400,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      
                      // ============================================
                      // 👤 AVATAR
                      // ============================================
                      Hero(
                        tag: 'avatar_${widget.user['id']}',
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.3),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              firstName.isNotEmpty && lastName.isNotEmpty
                                  ? '${firstName[0]}${lastName[0]}'.toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // ============================================
                      // 📝 NOM
                      // ============================================
                      Text(
                        '$firstName $lastName',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // ============================================
            // 📊 STATISTIQUES
            // ============================================
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn(
                        icon: Icons.people,
                        label: 'Abonnés',
                        value: '$followersCount',
                        color: Colors.blue,
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        color: Colors.grey[300],
                      ),
                      _buildStatColumn(
                        icon: Icons.person_add,
                        label: 'Abonnements',
                        value: '$followingCount',
                        color: Colors.purple,
                      ),
                      if (currentStreak > 0) ...[
                        Container(
                          width: 1,
                          height: 50,
                          color: Colors.grey[300],
                        ),
                        _buildStatColumn(
                          icon: Icons.local_fire_department,
                          label: 'Série',
                          value: '$currentStreak',
                          color: Colors.orange,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // ============================================
                  // 🔘 BOUTON FOLLOW/UNFOLLOW
                  // ============================================
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _toggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFollowing
                            ? Colors.grey[300]
                            : Colors.blue.shade700,
                        foregroundColor: isFollowing
                            ? Colors.black87
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: isFollowing ? 0 : 5,
                        shadowColor: Colors.blue.withOpacity(0.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isFollowing ? Icons.check : Icons.person_add,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isFollowing ? 'Abonné' : 'Suivre',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ============================================
            // 📑 TABS (FOLLOWERS / FOLLOWING)
            // ============================================
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.blue.shade700,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue.shade700,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.people),
                    text: 'Abonnés ($followersCount)',
                  ),
                  Tab(
                    icon: const Icon(Icons.person_add),
                    text: 'Abonnements ($followingCount)',
                  ),
                ],
              ),
            ),

            // ============================================
            // 📋 CONTENU DES TABS
            // ============================================
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // TAB 1: FOLLOWERS
                  _buildFollowersList(),
                  
                  // TAB 2: FOLLOWING
                  _buildFollowingList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // 📊 COLONNE DE STATISTIQUE
  // ============================================
  Widget _buildStatColumn({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // ============================================
  // 👥 LISTE DES FOLLOWERS
  // ============================================
  Widget _buildFollowersList() {
    if (isLoadingFollowers) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue.shade700),
            const SizedBox(height: 16),
            Text(
              'Chargement des abonnés...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (followers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 60,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun abonné',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Personne ne suit cet utilisateur pour le moment',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFollowers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: followers.length,
        itemBuilder: (context, index) {
          final follower = followers[index];
          return _buildUserListItem(follower);
        },
      ),
    );
  }

  // ============================================
  // 👥 LISTE DES FOLLOWING
  // ============================================
  Widget _buildFollowingList() {
    if (isLoadingFollowing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.purple.shade700),
            const SizedBox(height: 16),
            Text(
              'Chargement des abonnements...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (following.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_add_outlined,
                size: 60,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun abonnement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cet utilisateur ne suit personne',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFollowing,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: following.length,
        itemBuilder: (context, index) {
          final followingUser = following[index];
          return _buildUserListItem(followingUser);
        },
      ),
    );
  }

  // ============================================
  // 👤 ITEM UTILISATEUR DANS LA LISTE
  // ============================================
  Widget _buildUserListItem(Map<String, dynamic> user) {
    final firstName = user['firstName'] ?? '';
    final lastName = user['lastName'] ?? '';
    final email = user['email'] ?? '';
    final currentStreak = user['currentStreak'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade300,
                Colors.blue.shade700,
              ],
            ),
          ),
          child: Center(
            child: Text(
              firstName.isNotEmpty && lastName.isNotEmpty
                  ? '${firstName[0]}${lastName[0]}'.toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          '$firstName $lastName',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              email,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (currentStreak > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    size: 14,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$currentStreak jours de série',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
        ),
        onTap: () {
          // Ouvrir le profil de cet utilisateur
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileScreen(user: user),
            ),
          );
        },
      ),
    );
  }
}