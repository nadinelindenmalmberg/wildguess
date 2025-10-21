import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'core/constants.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const WildGuessApp());
}

class WildGuessApp extends StatelessWidget {
  const WildGuessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}