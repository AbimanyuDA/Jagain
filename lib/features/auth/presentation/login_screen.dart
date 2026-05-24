import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login - Jagain'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.security,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                'Selamat Datang di Jagain',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Laporkan dan pantau kerusakan infrastruktur di sekitar Anda.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // TODO: Implement Login Form & Role Redirection
              ElevatedButton(
                onPressed: () {
                  // Bypass login for demo to general feed
                },
                child: const Text('Masuk sebagai Warga'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
