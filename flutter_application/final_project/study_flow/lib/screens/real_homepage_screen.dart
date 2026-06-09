import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class RealHomepageScreen extends StatefulWidget{
  const RealHomepageScreen({super.key});

  @override
  State<RealHomepageScreen> createState() => _RealHomepageScreenState();
}

class _RealHomepageScreenState extends State<RealHomepageScreen> {
  
  void logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, 'login'); 
    }
  }
  final user = FirebaseAuth.instance.currentUser;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Text('Homepage'),
        actions: [
            IconButton(
              onPressed: logout,
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
            ),
          ],
      ),
      body: Column(
        children: [
          Text('Logged in as ${user?.email}'),
          Expanded(
            child: Center(
              child:Text('Welcome to the Homepage!'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, 'logger');
        },
        child: Icon(Icons.add),
      ),
    );
  }
}