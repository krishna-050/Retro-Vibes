import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:load_it/load_it.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retro_vibes/screens/bottom_navigation.dart';
import 'package:retro_vibes/screens/login_screen.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    User? fbUser;
    try {
      fbUser = FirebaseAuth.instance.currentUser;
    } catch (_) {}

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        if (isLoggedIn || fbUser != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const BottomNavigation()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double mediaHeight = size.height;
    double mediaWidth = size.width;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                "assets/images/splash.jpeg",
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppTheme.scaffoldBackground,
                  child: Center(
                    child: Text(
                      "RETRO VIBES",
                      style: TextStyle(
                        color: AppTheme.primaryAccent,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: mediaHeight * 0.08,
              left: mediaWidth * 0.43,
              child: BouncingDotsIndicator(color: AppTheme.yellow100),
            ),
          ],
        ),
      ),
    );
  }
}
