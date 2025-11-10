// lib/presentation/screens/register_screen.dart

import 'package:applangue/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';
import 'verify_otp_screen.dart'; // <-- import ici

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _loading = true);

    try {
      final message = await _repo.registerUser(_data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ?? 'Registration successful')),
      );

      // ✅ Redirection vers verify OTP
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyOtpScreen(email: _data['email']!),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'First Name'),
                onSaved: (v) => _data['firstName'] = v ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Last Name'),
                onSaved: (v) => _data['lastName'] = v ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                onSaved: (v) => _data['email'] = v ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Phone'),
                onSaved: (v) => _data['phone'] = v ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                onSaved: (v) => _data['password'] = v ?? '',
              ),
              const SizedBox(height: 20),
              
              ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Register'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Vous avez déjà un compte ? "),
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
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
