import 'package:flutter/material.dart';
import 'package:shoe_vault_project/screens/login_screen.dart';
import 'package:shoe_vault_project/services/database_service.dart';

class RegisteredScreen extends StatelessWidget {
  const RegisteredScreen({super.key, required this.dbService});

  final DatabaseService dbService;

  @override
  // SUPPRESSION de async et Future
  Widget build(BuildContext context) { 
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Registration successful! Please log in.'),
            const SizedBox(height: 20),
            ElevatedButton(
              // Utilisation d'une fonction anonyme () => ...
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen(dbService: dbService)),
                );
              },
              child: const Text('Go to Login Screen'),
            ),
          ],
        ),
      ),
    );
  }
}