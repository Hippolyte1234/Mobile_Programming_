/*
import 'package:flutter/material.dart';

class HomepageScreen extends StatefulWidget{
  const HomepageScreen({super.key});

  @override
  State<HomepageScreen> createState() => _HomepageScreenState();
}

class _HomepageScreenState extends State<HomepageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Homepage'),
      ),
      body: Center(
        child: Text('Welcome to the Homepage!'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/history');
          }
          else if (index == 2) {
            Navigator.pushNamed(context, '/settings');
          }
          else if (index == 0) {
            Navigator.pushNamed(context, '/home');
          }
          else if (index == 3) {
            Navigator.pushNamed(context, '/firestore');
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storage_outlined),
            label: 'Firestore',
          )
        ],
      ),
    );
  }
}
*/

import 'package:flutter/material.dart';
import 'package:study_flow/screens/firestore_test_screen.dart';
import 'package:study_flow/screens/history_screen.dart';
import 'package:study_flow/screens/real_homepage_screen.dart';
import 'package:study_flow/screens/settings_screen.dart';

class HomepageScreen extends StatefulWidget {
  const HomepageScreen({super.key});

  @override
  State<HomepageScreen> createState() => _HomepageScreenState();
}

class _HomepageScreenState extends State<HomepageScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    RealHomepageScreen(),
    HistoryScreen(),
    SettingsScreen(),
    FirestoreTestScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Flow'),
        centerTitle: true,
      ),
      body: _pages[_currentIndex], 
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), label: 'AI Plan'),
        ],
      ),
    );
  }
}

