// lib/presentation/screens/register_screen.dart
import 'package:KmerLingo/core/constants/colors.dart';
import 'package:KmerLingo/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';
import 'verify_otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _repo = AuthRepository();
  final _formKey = GlobalKey<FormState>();
  final _data = {
    'firstName': '',
    'lastName': '',
    'email': '',
    'phone': '',
    'password': '',
  };

  bool _loading = false;
  bool _obscurePassword = true;
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

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _loading = true);

    try {
      final message = await _repo.registerUser(_data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? 'Inscription réussie !'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyOtpScreen(email: _data['email']!),
        ),
      );
    } catch (e) {
      String errorMessage = 'Une erreur est survenue.';

      if (e is String) {
        errorMessage = e;
      } else if (e.toString().isNotEmpty) {
        errorMessage = e.toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  String? _validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName ne peut pas être vide';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email ne peut pas être vide';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'Email invalide';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Téléphone ne peut pas être vide';
    final regex = RegExp(r'^\+?[0-9]{7,15}$');
    if (!regex.hasMatch(value)) return 'Numéro de téléphone invalide';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) return 'Mot de passe ne peut pas être vide';
    if (value.length < 6) return 'Le mot de passe doit contenir au moins 6 caractères';
    return null;
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
                // Header avec logo et titre
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF2E7D32),
                          const Color(0xFF43A047),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Icône de langue animée
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1000),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.language,
                                  size: 50,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Créer un compte',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rejoignez KmerLingo aujourd\'hui',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Formulaire
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildTextField(
                            label: 'Nom',
                            icon: Icons.person_outline,
                            validator: (v) => _validateNotEmpty(v, 'Nom'),
                            onSaved: (v) => _data['firstName'] = v!.trim(),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Prénom',
                            icon: Icons.person,
                            validator: (v) => _validateNotEmpty(v, 'Prénom'),
                            onSaved: (v) => _data['lastName'] = v!.trim(),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                            onSaved: (v) => _data['email'] = v!.trim(),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Téléphone',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: _validatePhone,
                            onSaved: (v) => _data['phone'] = v!.trim(),
                          ),
                          const SizedBox(height: 16),
                         _buildTextField(
                          label: 'Mot de passe',
                          icon: Icons.lock_outline,
                          // 1. Utiliser la variable d'état pour masquer/afficher
                          obscureText: _obscurePassword, 
                          validator: _validatePassword,
                          onSaved: (v) => _data['password'] = v!.trim(),
                          // 2. Ajouter l'icône de basculement (suffixIcon)
                          suffixIcon: IconButton(
                            icon: Icon(
                              // Basculer l'icône entre visible et non visible
                              _obscurePassword ? Icons.visibility_off : Icons.visibility, 
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              // 3. Basculer l'état au clic pour reconstruire le widget
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                          const SizedBox(height: 32),
                          
                          // Bouton d'inscription
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
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
                                      'S\'inscrire',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Lien vers connexion
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Vous avez déjà un compte ? ",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[700],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Se connecter",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFFD32F2F),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
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

  Widget _buildTextField({
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    // Le paramètre obscureText est désormais facultatif et a une valeur par défaut
    bool obscureText = false, 
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
    // ✅ Nouveau paramètre pour l'icône à droite
    Widget? suffixIcon,
  }) {
    return TextFormField(
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onSaved: onSaved,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.grey[600],
        fontSize: 16,
    ),
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
      // ✅ Utiliser le suffixIcon ici
        suffixIcon: suffixIcon, 
        filled: true,
        fillColor: Colors.grey[50],
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
            color: AppColors.lightGreen, //Color(0xFFD32F2F),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFD32F2F),
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFD32F2F),
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
}