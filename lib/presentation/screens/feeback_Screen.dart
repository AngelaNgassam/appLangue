import 'package:flutter/material.dart';
import 'package:KmerLingo/core/services/api_service.dart';

class FeedbackScreen extends StatefulWidget {
  final String userId;
  const FeedbackScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController commentCtrl = TextEditingController();
  int rating = 0;
  bool isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _animationsReady = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Démarrage de l'animation après un micro-delay pour éviter l'erreur
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
      setState(() => _animationsReady = true);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    commentCtrl.dispose();
    super.dispose();
  }

  Future<void> submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await ApiService().submitFeedback(
        userId: widget.userId,
        rating: rating,
        comment: commentCtrl.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Merci pour votre feedback !")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget buildStar(int index) {
    return GestureDetector(
      onTap: () {
        setState(() => rating = index);
      },
      child: Icon(
        index <= rating ? Icons.star_rounded : Icons.star_border_rounded,
        color: Colors.amber,
        size: 40,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _animationsReady
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Title avec fade + slide
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: const Text(
                            "Votre Feedback",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Carte formulaire
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 6,
                            color: Colors.white.withOpacity(0.9),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  const Text(
                                    "Notez l'application",
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(5, (i) => buildStar(i + 1)),
                                  ),
                                  const SizedBox(height: 20),
                                  Form(
                                    key: _formKey,
                                    child: TextFormField(
                                      controller: commentCtrl,
                                      maxLines: 4,
                                      decoration: InputDecoration(
                                        labelText: "Votre commentaire (optionnel)",
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey.shade100,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 25),
                                  isLoading
                                      ? const CircularProgressIndicator()
                                      : SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: submitFeedback,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue.shade600,
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text(
                                              "Envoyer",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      ),
    );
  }
}
