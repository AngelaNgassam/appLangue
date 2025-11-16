// lib/main.dart

import 'package:KmerLingo/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'presentation/screens/register_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const int splashDurationSeconds = 5;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KmerLingo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryGreen,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          primary: AppColors.primaryGreen,
          secondary: AppColors.secondaryRed,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: SplashPage(durationSeconds: splashDurationSeconds),
    );
  }
}

class SplashPage extends StatefulWidget {
  final int durationSeconds;

  const SplashPage({super.key, this.durationSeconds = 5});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();

    Future.delayed(Duration(seconds: widget.durationSeconds), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RegisterScreen()),
      );
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final height = media.size.height;
    final isTablet = width > 600;

    const logoPath = 'assets/logo.png';

    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.lightGreen,
              AppColors.lightGreen.withOpacity(0.95),
              AppColors.primaryGreen.withOpacity(0.3),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Hero(
                tag: 'app_logo',
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: height * 0.4,
                    maxWidth: isTablet ? width * 0.5 : width * 0.75,
                  ),
                  child: Image.asset(
                    logoPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        padding: EdgeInsets.all(isTablet ? 60 : 50),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.language_rounded,
                          size: isTablet ? 120 : 90,
                          color: Colors.white,
                        ),
                      );
                    },
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

