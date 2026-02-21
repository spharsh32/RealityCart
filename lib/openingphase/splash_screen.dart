import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:reality_cart/openingphase/onboarding_screen.dart';
import 'package:reality_cart/user/home_screen.dart';
import 'package:reality_cart/admin/screens/admin_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Wait for 3 seconds for the splash effect
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Check if the user is an Admin by looking in the 'admins' collection
        DocumentSnapshot adminDoc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(user.uid)
            .get();

        if (mounted) {
          if (adminDoc.exists) {
            // User is an Admin
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
            );
          } else {
            // User is a regular Customer
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        }
      } catch (e) {
        // In case of error (e.g. no internet), default to regular Home or Login
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    } else {
      // No user logged in, show Onboarding
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Image.asset(
              'assets/images/app_logo.png',
              width: 150,
              height: 150,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.shopping_cart, size: 150, color: Colors.orange),
            ),
            const SizedBox(height: 20),

          ],
        ),
      ),
    );
  }
}
