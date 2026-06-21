import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:study_flow/firebase_options.dart';
import 'package:study_flow/screens/ai_plan/ai_plan_screen.dart';
import 'package:study_flow/screens/homepage_screen.dart';
import 'package:study_flow/screens/history_screen.dart';
import 'package:study_flow/screens/logger_screen.dart';
import 'package:study_flow/screens/login_screen.dart';
import 'package:study_flow/screens/logout_screen.dart';
import 'package:study_flow/screens/settings_screen.dart';
import 'package:study_flow/screens/auth_gate.dart';
import 'package:study_flow/screens/registration_screen.dart';
import 'package:study_flow/services/notification_service.dart';
import 'package:study_flow/services/notifications_service.dart' as awesome_notifications;
/*void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyFlow',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
<<<<<<< HEAD
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _pages = [
    _HomePage(),
    AiPlanScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.storage_outlined), label: 'Firestore'),

        ],
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Home')),
=======

    );
  }
}*/

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /*
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final dir = await getApplicationDocumentsDirectory();
  

  final isar = await Isar.open(
    [ShoeSchema, BrandSchema],
    directory: dir.path,
  );

  final dbService = DatabaseService(isar);*/

  try {
    await Firebase.initializeApp();
    print("Firebase successfully connected");
  } catch (e) {
    print("Firebase initialization failed: $e");
  }
  await awesome_notifications.NotificationService.init();

  await NotificationService.instance.init();

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    initialRoute: 'login',
    routes: {
      'home': (context) => HomepageScreen(),
      'history': (context) => HistoryScreen(),
      'firestore': (context) => AiPlanScreen(),
      'settings': (context) => SettingsScreen(),
      'logger': (context) => LoggerScreen(),
      'register': (context) => RegisterScreen(),
      'login': (context) => LoginScreen(),
    },
  ));
}
