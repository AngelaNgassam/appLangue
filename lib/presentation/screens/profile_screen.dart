import 'package:KmerLingo/core/services/api_service.dart';
import 'package:KmerLingo/presentation/screens/change_password_screen.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade600,
        title: const Text("Mon Profil", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : profile == null
              ? const Center(child: Text("Profil introuvable"))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // ----------------- HEADER -----------------
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade600, Colors.blue.shade300],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(35),
                            bottomRight: Radius.circular(35),
                          ),
                        ),
                        child: Column(
                          children: [
                            Hero(
                              tag: "profile_avatar_${widget.userId}",
                              child: CircleAvatar(
                                radius: 55,
                                backgroundColor: Colors.white,
                                child: const Icon(Icons.person, size: 60, color: Colors.blue),
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              "${profile!['firstName']} ${profile!['lastName']}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              profile!['email'],
                              style: const TextStyle(color: Colors.white70, fontSize: 15),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ----------------- CARD INFOS -----------------
                      AnimatedOpacity(
                        opacity: 1,
                        duration: const Duration(milliseconds: 600),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _infoTile(Icons.phone, "Téléphone", profile!['phone']),
                              const Divider(),
                              _infoTile(Icons.email, "Email", profile!['email']),
                              const Divider(),
                              _infoTile(Icons.verified_user, "ID Utilisateur", widget.userId),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ----------------- BOUTON CHANGE PASSWORD -----------------
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChangePasswordScreen(userId: widget.userId),
                              ),
                            );
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_reset, color: Colors.white),
                              SizedBox(width: 10),
                              Text(
                                "Changer le mot de passe",
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  // ----------------- WIDGET REUSABLE -----------------
  Widget _infoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.blue.shade50,
          child: Icon(icon, color: Colors.blue, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  )),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
