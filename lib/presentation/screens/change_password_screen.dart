import 'package:KmerLingo/core/services/api_service.dart';
import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String userId;

  const ChangePasswordScreen({Key? key, required this.userId})
      : super(key: key);

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final oldPassCtrl = TextEditingController();
  final newPassCtrl = TextEditingController();

  bool isLoading = false;
  bool showOld = false;
  bool showNew = false;

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final msg = await ApiService().changePassword(
        userId: widget.userId,
        oldPassword: oldPassCtrl.text,
        newPassword: newPassCtrl.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Changer le mot de passe"),
        centerTitle: true,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(22.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text(
                        "Sécurise ton compte",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 20),

                      // --- Champ ancien mot de passe ---
                      TextFormField(
                        controller: oldPassCtrl,
                        obscureText: !showOld,
                        decoration: InputDecoration(
                          labelText: "Ancien mot de passe",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                                showOld ? Icons.visibility_off : Icons.visibility),
                            onPressed: () {
                              setState(() => showOld = !showOld);
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty
                                ? "Champ obligatoire"
                                : null,
                      ),

                      const SizedBox(height: 20),

                      // --- Champ nouveau mot de passe ---
                      TextFormField(
                        controller: newPassCtrl,
                        obscureText: !showNew,
                        decoration: InputDecoration(
                          labelText: "Nouveau mot de passe",
                          prefixIcon: const Icon(Icons.lock_reset),
                          suffixIcon: IconButton(
                            icon: Icon(
                                showNew ? Icons.visibility_off : Icons.visibility),
                            onPressed: () {
                              setState(() => showNew = !showNew);
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.length < 6
                                ? "Minimum 6 caractères"
                                : null,
                      ),

                      const SizedBox(height: 30),

                      // --- Bouton ---
                      isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                                onPressed: submit,
                                child: const Text(
                                  "Mettre à jour",
                                  style: TextStyle(
                                      fontSize: 17, color: Colors.white),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
