import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';
import 'login_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;

  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _repo = AuthRepository();
  final _otpController = TextEditingController();
  bool _loading = false;

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez entrer un code OTP à 6 chiffres."),
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
          const SnackBar(content: Text("Compte vérifié avec succès !")),
        );

        // ✅ Redirection vers la page de connexion
        await Future.delayed(
          const Duration(seconds: 1),
        ); // petite pause esthétique
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        // ⚠️ Message inattendu
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message ?? "Erreur de vérification")),
        );
      }
    } catch (e) {
      // ❌ Gestion propre des erreurs
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur : ${e.toString()}")));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vérification de l'OTP")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Icon(
                  Icons.lock_open_rounded,
                  size: 80,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 20),
                Text(
                  "Un code à 6 chiffres vous a été envoyé à l'adresse :",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.email,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: "Entrez le code OTP",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Vérifier"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
