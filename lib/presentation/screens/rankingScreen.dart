import 'package:flutter/material.dart';
import 'package:KmerLingo/core/services/api_service.dart';
import 'package:KmerLingo/data/models/userRanking.dart';

class DivisionLeaderboardPage extends StatefulWidget {
  final String userId;

  const DivisionLeaderboardPage({Key? key, required this.userId}) : super(key: key);

  @override
  _DivisionLeaderboardPageState createState() => _DivisionLeaderboardPageState();
}

class _DivisionLeaderboardPageState extends State<DivisionLeaderboardPage>
    with SingleTickerProviderStateMixin {
  late Future<List<UserRanking>> _rankingFuture;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _rankingFuture = fetchLeaderboard();

    // AnimationController pour fade + slide
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

  Future<List<UserRanking>> fetchLeaderboard() async {
    final api = ApiService();
    final data = await api.fetchDivisionRanking(widget.userId);
    return List.generate(data.length, (index) => UserRanking.fromJson(data[index], index));
  }

  Future<void> _refresh() async {
    setState(() {
      _rankingFuture = fetchLeaderboard();
    });
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 0:
        return Colors.amber.shade400; // 1er
      case 1:
        return Colors.grey.shade400; // 2ème
      case 2:
        return Colors.brown.shade400; // 3ème
      default:
        return Colors.blueAccent; // Autres
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background dégradé
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6DD5FA), Color(0xFF2980B9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar custom
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: const [
                    Icon(Icons.leaderboard, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Classement de la division',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<UserRanking>>(
                  future: _rankingFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoading();
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Erreur : ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'Aucun utilisateur dans cette division.',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final rankings = snapshot.data!;
                    _animationController.forward();

                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: rankings.length,
                        itemBuilder: (context, index) {
                          final user = rankings[index];
                          final isCurrentUser = user.userId == widget.userId;

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
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.2),
                                end: Offset.zero,
                              ).animate(animation),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isCurrentUser ? Colors.green.shade100 : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.07),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: _getRankColor(index),
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        user.userName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isCurrentUser
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${user.points} pts',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isCurrentUser
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: Colors.white,
      ),
    );
  }
}
