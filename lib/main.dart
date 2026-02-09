import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const TokoKitaApp());
}

class TokoKitaApp extends StatelessWidget {
  const TokoKitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TOKO KITA',
      debugShowCheckedModeBanner: false,
      routes: {'/login': (context) => const LoginScreen()},
      home: const SplashScreen(),
    );
  }
}
