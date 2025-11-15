import 'package:flutter/material.dart';
import 'package:KmerLingo/core/services/api_service.dart';
import 'package:KmerLingo/data/models/userRanking.dart';

class DivisionLeaderboardPage extends StatefulWidget {
  final String userId;

  const DivisionLeaderboardPage({Key? key, required this.userId}) : super(key: key);

  @override
  _DivisionLeaderboardPageState createState() => _DivisionLeaderboardPageState();
}

class _DivisionLeaderboardPageState extends State<DivisionLeaderboardPage> {
  late Future<List<UserRanking>> _rankingFuture;

  @override
  void initState() {
    super.initState();
    _rankingFuture = fetchLeaderboard();
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
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade600,
        title: const Text(
          'Classement de la division',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<UserRanking>>(
        future: _rankingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun utilisateur dans cette division.'));
          }

          final rankings = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: rankings.length,
              itemBuilder: (context, index) {
                final user = rankings[index];
                final isCurrentUser = user.userId == widget.userId;

                return AnimatedOpacity(
                  duration: Duration(milliseconds: 400 + index * 50),
                  opacity: 1,
                  curve: Curves.easeOut,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isCurrentUser ? Colors.green.shade100 : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Rank Circle
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: _getRankColor(index),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Username
                        Expanded(
                          child: Text(
                            user.userName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                        // Points
                        Text(
                          '${user.points} pts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue.shade700),
          const SizedBox(height: 15),
          const Text(
            "Chargement du classement...",
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
