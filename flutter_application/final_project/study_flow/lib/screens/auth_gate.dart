import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_flow/screens/homepage_screen.dart';
import 'package:study_flow/screens/login_screen.dart';

/// Listens to Firebase auth state and routes the user accordingly:
/// signed in -> [HomeScreen], signed out -> [LoginScreen].
///
/// Because this rebuilds whenever the auth state changes, screens no longer
/// need to manually navigate after sign in / sign out / register.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
