import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ShinguMealApp());
}

class ShinguMealApp extends StatelessWidget {
  const ShinguMealApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '신구대 급식',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8)),
        fontFamily: 'NotoSansKR',
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
