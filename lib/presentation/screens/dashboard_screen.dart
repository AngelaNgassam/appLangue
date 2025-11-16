import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image illustrative
            Image.network(
              'https://cdn-icons-png.flaticon.com/512/3135/3135715.png', // Exemple d'illustration
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 30),
            // Message principal
            const Text(
              'Accès réservé au Web 🌐',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 15),
            // Explication
            const Text(
              'Veuillez vous connecter sur la version Web de l’application pour accéder à votre dashboard d’administrateur.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 40),
            // Bouton vers le site web (exemple)
            ElevatedButton.icon(
              onPressed: () {
                // Ici tu peux ajouter un lien vers le site web avec url_launcher
              },
              icon: const Icon(Icons.web),
              label: const Text('Se connecter sur le Web'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
