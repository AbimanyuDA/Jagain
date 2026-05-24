import 'package:flutter/material.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Akun - Jagain'),
      ),
      body: const Center(
        child: Text('Register Screen - Tempat mendaftar untuk Akun Warga.'),
      ),
    );
  }
}
