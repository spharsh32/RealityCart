import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setSystemTheme() {
    _themeMode = ThemeMode.system;
    notifyListeners();
  }

  // Load theme from Firestore on login or app start
  Future<void> loadTheme() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final bool? isDark = doc.data()?['darkMode'];
          if (isDark != null) {
            _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
          } else {
            _themeMode = ThemeMode.system;
          }
          notifyListeners();
        }
      } catch (e) {
        debugPrint("Error loading theme: $e");
      }
    }
  }
}
