import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shoe_vault_project/models/shoe.dart';
import 'package:shoe_vault_project/screens/login_screen.dart';
import 'package:shoe_vault_project/screens/registration_screen.dart';
import 'package:shoe_vault_project/screens/settings_screen.dart';
import 'package:shoe_vault_project/screens/shoe_homescreen.dart';
import 'package:shoe_vault_project/services/database_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shoe_vault_project/services/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.init();
  // On programme le rappel quotidien une seule fois
  await NotificationService.scheduleDailyReminder();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final dir = await getApplicationDocumentsDirectory();
  

  final isar = await Isar.open(
    [ShoeSchema, BrandSchema],
    directory: dir.path,
  );

  final dbService = DatabaseService(isar);


  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    initialRoute: '/',
    routes: {
      'home': (context) => ShoeHomeScreen(dbService: dbService),
      'register': (context) => RegisterScreen(),
      '/': (context) => LoginScreen(dbService: dbService),
      'settings': (context) => SettingsScreen(),
    },
  ));
}

