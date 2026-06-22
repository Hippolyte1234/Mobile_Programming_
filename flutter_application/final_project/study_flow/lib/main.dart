import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:study_flow/firebase_options.dart';
import 'package:study_flow/screens/ai_plan/ai_plan_screen.dart';
import 'package:study_flow/screens/homepage_screen.dart';
import 'package:study_flow/screens/history_screen.dart';
import 'package:study_flow/screens/habits_screen.dart';
import 'package:study_flow/screens/logger_screen.dart';
import 'package:study_flow/screens/login_screen.dart';
import 'package:study_flow/screens/settings_screen.dart';
import 'package:study_flow/screens/registration_screen.dart';
import 'package:study_flow/services/notification_service.dart';
import 'package:study_flow/services/notifications_service.dart' as awesome_notifications;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase successfully connected");
  } catch (e) {
    print("Firebase initialization failed: $e");
  }
  try {
    await awesome_notifications.NotificationService.init();
  } catch (e) {
    print("Awesome Notifications initialization failed: $e");
  }

  try {
    await NotificationService.instance.init();
  } catch (e) {
    print("Local notification initialization failed: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: 'login',
      routes: {
        'home': (context) => const HomepageScreen(),
        'history': (context) => const HistoryScreen(),
        'habits': (context) => const HabitsScreen(),
        'firestore': (context) => const AiPlanScreen(),
        'settings': (context) => const SettingsScreen(),
        'logger': (context) => const LoggerScreen(),
        'register': (context) => const RegisterScreen(),
        'login': (context) => const LoginScreen(),
      },
    );
  }
}
