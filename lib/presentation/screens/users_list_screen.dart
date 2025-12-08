// import 'package:KmerLingo/core/services/api_service.dart';
// import 'package:flutter/material.dart';

// class UsersListScreen extends StatefulWidget {
//   const UsersListScreen({Key? key}) : super(key: key);

//   @override
//   State<UsersListScreen> createState() => _UsersListScreenState();
// }

// class _UsersListScreenState extends State<UsersListScreen> {
//   final ApiService _apiService = ApiService();
//   final TextEditingController _searchController = TextEditingController();
  
//   List<dynamic> users = [];
//   List<dynamic> searchResults = [];
//   bool isLoading = true;
//   bool isSearching = false;
//   int currentPage = 1;
//   int totalPages = 1;
//   bool hasMore = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadUsers();
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   // ============================================
//   // 📋 CHARGER TOUS LES UTILISATEURS
//   // ============================================
//   Future<void> _loadUsers({bool loadMore = false}) async {
//     if (!loadMore) {
//       setState(() {
//         isLoading = true;
//         currentPage = 1;
//       });
//     }

//     try {
//       final response = await _apiService.getAllUsers(
//         page: currentPage,
//         limit: 20,
//       );

//       setState(() {
//         if (loadMore) {
//           users.addAll(response['users']);
//         } else {
//           users = response['users'];
//         }
        
//         totalPages = response['pagination']['totalPages'];
//         hasMore = currentPage < totalPages;
//         isLoading = false;
//       });
//     } catch (e) {
//       print('❌ Erreur chargement users: $e');
//       setState(() {
//         isLoading = false;
//       });
//       _showError('Impossible de charger les utilisateurs');
//     }
//   }

//   // ============================================
//   // 🔍 RECHERCHER DES UTILISATEURS
//   // ============================================
//   Future<void> _searchUsers(String query) async {
//     if (query.isEmpty) {
//       setState(() {
//         isSearching = false;
//         searchResults.clear();
//       });
//       return;
//     }

//     if (query.length < 2) return;

//     setState(() {
//       isSearching = true;
//     });

//     try {
//       final results = await _apiService.searchUsers(query);
//       setState(() {
//         searchResults = results;
//       });
//     } catch (e) {
//       print('❌ Erreur recherche: $e');
//       _showError('Erreur lors de la recherche');
//     }
//   }

//   // ============================================
//   // 👥 SUIVRE / NE PLUS SUIVRE
//   // ============================================
//   Future<void> _toggleFollow(String userId, bool isFollowing, int index) async {
//     try {
//       if (isFollowing) {
//         await _apiService.unfollowUser(userId);
//         _showSuccess('Vous ne suivez plus cet utilisateur');
//       } else {
//         await _apiService.followUser(userId);
//         _showSuccess('Vous suivez maintenant cet utilisateur');
//       }

//       // Mettre à jour l'état local
//       setState(() {
//         if (isSearching) {
//           searchResults[index]['isFollowing'] = !isFollowing;
//           if (isFollowing) {
//             searchResults[index]['followersCount']--;
//           } else {
//             searchResults[index]['followersCount']++;
//           }
//         } else {
//           users[index]['isFollowing'] = !isFollowing;
//           if (isFollowing) {
//             users[index]['followersCount']--;
//           } else {
//             users[index]['followersCount']++;
//           }
//         }
//       });
//     } catch (e) {
//       print('❌ Erreur toggle follow: $e');
//       _showError('Une erreur est survenue');
//     }
//   }

//   // ============================================
//   // 📄 CHARGER PLUS D'UTILISATEURS (Pagination)
//   // ============================================
//   Future<void> _loadMoreUsers() async {
//     if (!hasMore || isLoading) return;

//     setState(() {
//       currentPage++;
//     });

//     await _loadUsers(loadMore: true);
//   }

//   // ============================================
//   // 🎨 AFFICHAGE DES MESSAGES
//   // ============================================
//   void _showSuccess(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }

//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }

//   // ============================================
//   // 🎨 BUILD UI
//   // ============================================
//   @override
//   Widget build(BuildContext context) {
//     final displayList = isSearching ? searchResults : users;

//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         title: const Text(
//           'Utilisateurs',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         backgroundColor: Colors.blue.shade700,
//         elevation: 0,
//       ),
//       body: Column(
//         children: [
//           // ============================================
//           // 🔍 BARRE DE RECHERCHE
//           // ============================================
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.blue.shade700,
//               borderRadius: const BorderRadius.only(
//                 bottomLeft: Radius.circular(30),
//                 bottomRight: Radius.circular(30),
//               ),
//             ),
//             child: TextField(
//               controller: _searchController,
//               onChanged: _searchUsers,
//               style: const TextStyle(color: Colors.white),
//               decoration: InputDecoration(
//                 hintText: 'Rechercher par nom ou email...',
//                 hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
//                 prefixIcon: const Icon(Icons.search, color: Colors.white),
//                 suffixIcon: _searchController.text.isNotEmpty
//                     ? IconButton(
//                         icon: const Icon(Icons.clear, color: Colors.white),
//                         onPressed: () {
//                           _searchController.clear();
//                           _searchUsers('');
//                         },
//                       )
//                     : null,
//                 filled: true,
//                 fillColor: Colors.white.withOpacity(0.2),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(30),
//                   borderSide: BorderSide.none,
//                 ),
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 20,
//                   vertical: 15,
//                 ),
//               ),
//             ),
//           ),

//           // ============================================
//           // 📋 LISTE DES UTILISATEURS
//           // ============================================
//           Expanded(
//             child: isLoading && users.isEmpty
//                 ? const Center(
//                     child: CircularProgressIndicator(),
//                   )
//                 : displayList.isEmpty
//                     ? Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               Icons.people_outline,
//                               size: 80,
//                               color: Colors.grey[400],
//                             ),
//                             const SizedBox(height: 16),
//                             Text(
//                               isSearching
//                                   ? 'Aucun utilisateur trouvé'
//                                   : 'Aucun utilisateur disponible',
//                               style: TextStyle(
//                                 fontSize: 18,
//                                 color: Colors.grey[600],
//                               ),
//                             ),
//                           ],
//                         ),
//                       )
//                     : RefreshIndicator(
//                         onRefresh: _loadUsers,
//                         child: NotificationListener<ScrollNotification>(
//                           onNotification: (ScrollNotification scrollInfo) {
//                             if (!isSearching &&
//                                 scrollInfo.metrics.pixels ==
//                                     scrollInfo.metrics.maxScrollExtent) {
//                               _loadMoreUsers();
//                             }
//                             return false;
//                           },
//                           child: ListView.builder(
//                             padding: const EdgeInsets.all(16),
//                             itemCount: displayList.length + (hasMore && !isSearching ? 1 : 0),
//                             itemBuilder: (context, index) {
//                               if (index == displayList.length) {
//                                 return const Center(
//                                   child: Padding(
//                                     padding: EdgeInsets.all(16),
//                                     child: CircularProgressIndicator(),
//                                   ),
//                                 );
//                               }

//                               final user = displayList[index];
//                               return _buildUserCard(user, index);
//                             },
//                           ),
//                         ),
//                       ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================
//   // 👤 CARTE UTILISATEUR
//   // ============================================
//   Widget _buildUserCard(Map<String, dynamic> user, int index) {
//     final isFollowing = user['isFollowing'] ?? false;
//     final firstName = user['firstName'] ?? '';
//     final lastName = user['lastName'] ?? '';
//     final email = user['email'] ?? '';
//     final followersCount = user['followersCount'] ?? 0;
//     final currentStreak = user['currentStreak'] ?? 0;

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             // ============================================
//             // 🎨 AVATAR ROND
//             // ============================================
//             Container(
//               width: 60,
//               height: 60,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 gradient: LinearGradient(
//                   colors: [
//                     Colors.blue.shade400,
//                     Colors.blue.shade700,
//                   ],
//                 ),
//               ),
//               child: Center(
//                 child: Text(
//                   '${firstName[0]}${lastName[0]}'.toUpperCase(),
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 16),

//             // ============================================
//             // 📝 INFORMATIONS UTILISATEUR
//             // ============================================
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     '$firstName $lastName',
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     email,
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     children: [
//                       Icon(
//                         Icons.people,
//                         size: 16,
//                         color: Colors.grey[500],
//                       ),
//                       const SizedBox(width: 4),
//                       Text(
//                         '$followersCount abonné${followersCount > 1 ? 's' : ''}',
//                         style: TextStyle(
//                           fontSize: 13,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       if (currentStreak > 0) ...[
//                         const SizedBox(width: 16),
//                         const Icon(
//                           Icons.local_fire_department,
//                           size: 16,
//                           color: Colors.orange,
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           '$currentStreak',
//                           style: const TextStyle(
//                             fontSize: 13,
//                             color: Colors.orange,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             // ============================================
//             // ➕ BOUTON FOLLOW/UNFOLLOW
//             // ============================================
//             GestureDetector(
//               onTap: () => _toggleFollow(user['id'], isFollowing, index),
//               child: Container(
//                 width: 40,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: isFollowing ? Colors.green : Colors.blue.shade700,
//                   boxShadow: [
//                     BoxShadow(
//                       color: (isFollowing ? Colors.green : Colors.blue)
//                           .withOpacity(0.3),
//                       blurRadius: 8,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Icon(
//                   isFollowing ? Icons.check : Icons.add,
//                   color: Colors.white,
//                   size: 24,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:KmerLingo/core/services/api_service.dart';
import 'package:KmerLingo/presentation/screens/user_profile_screen.dart';
import 'package:flutter/material.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({Key? key, required String userId}) : super(key: key);

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<dynamic> users = [];
  List<dynamic> searchResults = [];
  bool isLoading = true;
  bool isSearching = false;
  int currentPage = 1;
  int totalPages = 1;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================
  // 📋 CHARGER TOUS LES UTILISATEURS
  // ============================================
  Future<void> _loadUsers({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        isLoading = true;
        currentPage = 1;
      });
    }

    try {
      final response = await _apiService.getAllUsers(
        page: currentPage,
        limit: 20,
      );

      setState(() {
        if (loadMore) {
          users.addAll(response['users']);
        } else {
          users = response['users'];
        }
        
        totalPages = response['pagination']['totalPages'];
        hasMore = currentPage < totalPages;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement users: $e');
      setState(() {
        isLoading = false;
      });
      _showError('Impossible de charger les utilisateurs');
    }
  }

  // ============================================
  // 🔍 RECHERCHER DES UTILISATEURS
  // ============================================
  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        isSearching = false;
        searchResults.clear();
      });
      return;
    }

    if (query.length < 2) return;

    setState(() {
      isSearching = true;
    });

    try {
      final results = await _apiService.searchUsers(query);
      setState(() {
        searchResults = results;
      });
    } catch (e) {
      print('❌ Erreur recherche: $e');
      _showError('Erreur lors de la recherche');
    }
  }

  // ============================================
  // 👥 SUIVRE / NE PLUS SUIVRE
  // ============================================
  Future<void> _toggleFollow(String userId, bool isFollowing, int index) async {
    try {
      if (isFollowing) {
        await _apiService.unfollowUser(userId);
        _showSuccess('Vous ne suivez plus cet utilisateur');
      } else {
        await _apiService.followUser(userId);
        _showSuccess('Vous suivez maintenant cet utilisateur');
      }

      // Mettre à jour l'état local
      setState(() {
        if (isSearching) {
          searchResults[index]['isFollowing'] = !isFollowing;
          if (isFollowing) {
            searchResults[index]['followersCount']--;
          } else {
            searchResults[index]['followersCount']++;
          }
        } else {
          users[index]['isFollowing'] = !isFollowing;
          if (isFollowing) {
            users[index]['followersCount']--;
          } else {
            users[index]['followersCount']++;
          }
        }
      });
    } catch (e) {
      print('❌ Erreur toggle follow: $e');
      _showError('Une erreur est survenue');
    }
  }

  // ============================================
  // 👤 OUVRIR LE PROFIL UTILISATEUR
  // ============================================
  void _openUserProfile(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(user: user),
      ),
    ).then((_) {
      // Rafraîchir la liste après retour du profil
      _loadUsers();
    });
  }

  // ============================================
  // 📄 CHARGER PLUS D'UTILISATEURS (Pagination)
  // ============================================
  Future<void> _loadMoreUsers() async {
    if (!hasMore || isLoading) return;

    setState(() {
      currentPage++;
    });

    await _loadUsers(loadMore: true);
  }

  // ============================================
  // 🎨 AFFICHAGE DES MESSAGES
  // ============================================
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
        duration: const Duration(seconds: 2),
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================
  // 🎨 BUILD UI
  // ============================================
  @override
  Widget build(BuildContext context) {
    final displayList = isSearching ? searchResults : users;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          // ============================================
          // 📱 APP BAR AVEC GRADIENT
          // ============================================
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: Colors.blue.shade700,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Communauté',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade800,
                      Colors.blue.shade600,
                      Colors.blue.shade400,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ============================================
          // 🔍 BARRE DE RECHERCHE
          // ============================================
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _searchUsers,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom ou email...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.blue.shade700),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[400]),
                            onPressed: () {
                              _searchController.clear();
                              _searchUsers('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ============================================
          // 📊 STATISTIQUES
          // ============================================
          if (!isSearching)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.people,
                        title: 'Utilisateurs',
                        value: '${users.length}',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.person_add,
                        title: 'Suivis',
                        value: '${users.where((u) => u['isFollowing'] == true).length}',
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ============================================
          // 📋 LISTE DES UTILISATEURS
          // ============================================
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: isLoading && users.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.blue.shade700,
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chargement...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : displayList.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
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
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                isSearching
                                    ? 'Aucun utilisateur trouvé'
                                    : 'Aucun utilisateur disponible',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isSearching
                                    ? 'Essayez une autre recherche'
                                    : 'Revenez plus tard',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == displayList.length) {
                              return hasMore && !isSearching
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: CircularProgressIndicator(
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink();
                            }

                            final user = displayList[index];
                            return _buildUserCard(user, index);
                          },
                          childCount: displayList.length + (hasMore && !isSearching ? 1 : 0),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // 📊 CARTE DE STATISTIQUE
  // ============================================
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // 👤 CARTE UTILISATEUR
  // ============================================
  Widget _buildUserCard(Map<String, dynamic> user, int index) {
    final isFollowing = user['isFollowing'] ?? false;
    final firstName = user['firstName'] ?? '';
    final lastName = user['lastName'] ?? '';
    final email = user['email'] ?? '';
    final followersCount = user['followersCount'] ?? 0;
    final followingCount = user['followingCount'] ?? 0;
    final currentStreak = user['currentStreak'] ?? 0;

    return GestureDetector(
      onTap: () => _openUserProfile(user),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // ============================================
                  // 🎨 AVATAR ROND AVEC GRADIENT
                  // ============================================
                  Hero(
                    tag: 'avatar_${user['id']}',
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade300,
                            Colors.blue.shade700,
                            Colors.purple.shade400,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
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
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // ============================================
                  // 📝 INFORMATIONS UTILISATEUR
                  // ============================================
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$firstName $lastName',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // ============================================
                  // ➕ BOUTON FOLLOW/UNFOLLOW
                  // ============================================
                  GestureDetector(
                    onTap: () => _toggleFollow(user['id'], isFollowing, index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isFollowing
                            ? LinearGradient(
                                colors: [Colors.green.shade400, Colors.green.shade700],
                              )
                            : LinearGradient(
                                colors: [Colors.blue.shade400, Colors.blue.shade700],
                              ),
                        boxShadow: [
                          BoxShadow(
                            color: (isFollowing ? Colors.green : Colors.blue)
                                .withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        isFollowing ? Icons.check : Icons.add,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),

              // ============================================
              // 📊 STATISTIQUES UTILISATEUR
              // ============================================
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildUserStat(
                      icon: Icons.people,
                      label: 'Abonnés',
                      value: '$followersCount',
                      color: Colors.blue,
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey[300],
                    ),
                    _buildUserStat(
                      icon: Icons.person_add,
                      label: 'Abonnements',
                      value: '$followingCount',
                      color: Colors.purple,
                    ),
                    if (currentStreak > 0) ...[
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.grey[300],
                      ),
                      _buildUserStat(
                        icon: Icons.local_fire_department,
                        label: 'Série',
                        value: '$currentStreak',
                        color: Colors.orange,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // 📊 STATISTIQUE UTILISATEUR
  // ============================================
  Widget _buildUserStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}