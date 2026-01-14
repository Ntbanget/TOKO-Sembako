import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

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

  void _checkAuth() async {
    // Simulasi loading 3 detik
    await Future.delayed(const Duration(seconds: 3));
    final prefs = await SharedPreferences.getInstance();
    final String? role = prefs.getString('role');

    if (!mounted) return;

    if (role != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(role: role)),
      );
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // UPDATE: Menggunakan Logo Gambar
            Image.asset(
              "assets/images/logo.png",
              width: 150,
              height: 150,
              fit: BoxFit.contain,
              // Fallback jika gambar gagal dimuat
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.shopping_basket,
                size: 100,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "TOKO KITA",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
