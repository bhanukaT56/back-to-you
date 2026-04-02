import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  Future<void> _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF083344),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFF22D3EE),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Text(
                  '🔍',
                  style: TextStyle(fontSize: 48),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Back To You',
              style: TextStyle(
                color: Color(0xFF22D3EE),
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'campus lost & found',
              style: TextStyle(
                color: Color(0xFF555555),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: Color(0xFF22D3EE),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}