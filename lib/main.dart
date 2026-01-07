import 'package:flutter/material.dart';
import 'package:flutter_app/screen/login.screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: const Color(0xFF3BA8C9), 
        secondaryHeaderColor: const Color(0xFFE472C0),
        fontFamily: 'Roboto',
      ),
      // home: HomeScreenPage(),
      home: const AuthScreen(),
    );
  }
}
