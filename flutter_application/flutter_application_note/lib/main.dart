import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_note/models/note_database.dart';
import 'package:flutter_application_note/pages/homepage.dart';
import 'package:flutter_application_note/pages/notes_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}