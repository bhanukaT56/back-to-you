import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Center(
        child: Text(
          'Login Screen - Coming Soon',
          style: TextStyle(
            color: Color(0xFF22D3EE),
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}