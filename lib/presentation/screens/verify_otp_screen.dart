// lib/presentation/screens/verify_otp_screen.dart

import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';
import 'dashboard_screen.dart'; // ton écran d'accueil après OTP

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
        const SnackBar(content: Text("Entrez votre code OTP à 6 chiffres.")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Appel à ton backend Laravel pour vérifier le code
      final message = await _repo.verifyOtp(widget.email, otp);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ?? 'OTP verified successfully!')),
      );

      // ✅ Rediriger vers le dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
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
      appBar: AppBar(title: const Text("Verification de l'OTP")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Text(
              "Un code de 6 chiffres vous a ete envoyé par email.",
              style: TextStyle(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Email caché (non visible, mais disponible)
            Offstage(
              offstage: true,
              child: Text(widget.email),
            ),

            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: "Enter OTP",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _loading ? null : _verifyOtp,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Next"),
            ),
          ],
        ),
      ),
    );
  }
}
