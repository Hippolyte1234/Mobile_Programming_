import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_flow/screens/firestore_test_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Signing out triggers the AuthGate's authStateChanges stream, which sends
  // the user back to the LoginScreen automatically.
  void logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('StudyFlow'),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: logout,
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.home_outlined), text: 'Home'),
              Tab(icon: Icon(Icons.list_alt), text: 'CRUD'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _HomeTab(),
            FirestoreTestScreen(),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Center(
      child: Text('Logged in as ${user?.email}'),
    );
  }
}
