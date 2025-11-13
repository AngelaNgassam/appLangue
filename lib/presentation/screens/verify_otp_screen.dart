import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';
import 'login_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;

  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> with SingleTickerProviderStateMixin {
  final _repo = AuthRepository();
  final _otpController = TextEditingController();
  bool _loading = false;
  
  // Ajout des animations pour un effet d'apparition fluide (comme RegisterScreen)
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez entrer un code OTP à 6 chiffres."),
          backgroundColor: Color(0xFFD32F2F), // Style erreur
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final message = await _repo.verifyOtp(widget.email, otp);

      if (message != null &&
          message.contains("Account verified successfully")) {
        // ✅ Succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Compte vérifié avec succès !"),
            backgroundColor: Color(0xFF2E7D32), // Style succès
          ),
        );

        // ✅ Redirection vers la page de connexion
        await Future.delayed(
          const Duration(seconds: 1),
        ); 
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        // ⚠️ Message inattendu / Erreur serveur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message ?? "Erreur de vérification"),
            backgroundColor: const Color(0xFFD32F2F), // Style erreur
          ),
        );
      }
    } catch (e) {
      // ❌ Gestion propre des erreurs
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
        content: Text("Erreur : ${e.toString()}"),
        backgroundColor: const Color(0xFFD32F2F), // Style erreur
      ));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _animController.dispose(); // Dispose du contrôleur d'animation
    super.dispose();
  }

  // Fonction pour construire le champ de texte avec le style commun
  Widget _buildOtpTextField() {
    return TextField(
      controller: _otpController,
      keyboardType: TextInputType.number,
      maxLength: 6,
      textAlign: TextAlign.center, // Centrer le texte pour l'OTP
      style: const TextStyle(
        fontSize: 24, 
        fontWeight: FontWeight.bold,
        color: Color(0xFF2E7D32) // Couleur accentuée pour le code
      ),
      decoration: InputDecoration(
        labelText: "Entrez le code OTP",
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 16,
        ),
        helperText: 'Le code expire après quelques minutes.',
        counterText: "", // Masque le compteur de caractères
        filled: true,
        fillColor: Colors.grey[50],
        // Style de bordure arrondi et cohérent
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF2E7D32), // Focus en vert primaire
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              slivers: [
                // Header stylisé
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF2E7D32),
                          Color(0xFF43A047),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Icone de l'OTP
                        const Icon(
                          Icons.vpn_key_outlined,
                          size: 50,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Vérification du compte",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Entrez le code envoyé à votre adresse e-mail.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Contenu principal / Formulaire OTP
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        
                        // Texte d'instruction
                        Text(
                          "Un code à 6 chiffres vous a été envoyé à l'adresse :",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 8),
                        // Email
                        Text(
                          widget.email,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32), // Couleur principale pour l'email
                          ),
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Champ de saisie OTP
                        _buildOtpTextField(),
                        
                        const SizedBox(height: 32),
                        
                        // Bouton de vérification
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _verifyOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32), // Vert primaire
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: const Color(0xFF2E7D32).withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    "Vérifier le code",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 40),
                        
                        // Lien pour renvoyer le code (Optionnel, mais bon pour l'UX)
                        TextButton(
                          onPressed: _loading ? null : () {
                            // TODO: Implémenter la logique pour renvoyer l'OTP
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Fonctionnalité de renvoi de code à implémenter.")),
                            );
                          },
                          child: const Text(
                            "Renvoyer le code",
                            style: TextStyle(
                              color: Color(0xFFD32F2F), // Accent rouge
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}