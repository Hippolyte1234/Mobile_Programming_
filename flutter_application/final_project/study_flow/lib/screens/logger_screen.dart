/*
import 'package:flutter/material.dart';
import 'package:study_flow/models/study_session.dart';
import 'package:study_flow/services/study_session_service.dart';

class LoggerScreen extends StatefulWidget {
  const LoggerScreen({super.key});
  
  @override
  State<LoggerScreen> createState() => LoggerScreenState();  
  }

class LoggerScreenState extends State<LoggerScreen> {

  final StudySessionService _studySessionService = StudySessionService();

  TextEditingController subjectController = TextEditingController();
  TextEditingController durationController = TextEditingController();
  TextEditingController notesController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController startTimeController = TextEditingController();

  void createStudySession(StudySession session) {
    session.subject = subjectController.text;
    session.duration = durationController.text;
    session.notes = notesController.text;
    session.date = dateController.text;
    session.startTime = DateTime.parse(startTimeController.text);
    session.endTime = startTimeController.text.isNotEmpty
        ? DateTime.parse(startTimeController.text).add(Duration(minutes: int.parse(durationController.text)))
        : DateTime.now();
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Study Session'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              StudySession newSession = StudySession();
              createStudySession(newSession);
              _studySessionService.saveStudySession(newSession);
            },
          ),
        ],
      )
      ,
      body: Container(
        child: Column(
          children: [
            TextField(
              controller: subjectController,
              decoration: InputDecoration(
                labelText: 'Subject',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: durationController,
              decoration: InputDecoration(
                labelText: 'Duration (minutes)',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Notes',
              ),
              maxLines: 10,
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: dateController,
              decoration: InputDecoration(
                labelText: 'Date (YYYY-MM-DD)',
              ),
              keyboardType: TextInputType.datetime,
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: startTimeController,
              decoration: InputDecoration(
                labelText: 'Start Time (HH:MM)',
              ),
              keyboardType: TextInputType.datetime,
            ),

          ],)
      )
    );
  }
}
*/

import 'package:flutter/material.dart';
import 'package:study_flow/models/study_session.dart';
import 'package:study_flow/services/database_service.dart';
import 'package:study_flow/services/study_session_service.dart';

class LoggerScreen extends StatefulWidget {
  const LoggerScreen({super.key});
  
  @override
  State<LoggerScreen> createState() => LoggerScreenState();  
}

class LoggerScreenState extends State<LoggerScreen> {
  final StudySessionService _studySessionService = StudySessionService();
  final DatabaseService _databaseService = DatabaseService();

  final TextEditingController subjectController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Future<void> _saveSession() async {
    if (subjectController.text.isEmpty || 
        durationController.text.isEmpty || 
        _selectedDate == null || 
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    final DateTime startTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final int durationMinutes = int.tryParse(durationController.text) ?? 0;
    final DateTime endTime = startTime.add(Duration(minutes: durationMinutes));

    StudySession newSession = StudySession();
    newSession.subject = subjectController.text;
    newSession.duration = durationController.text; // Gardé en String selon ton modèle
    newSession.notes = notesController.text;
    newSession.date = "${startTime.year}-${startTime.month}-${startTime.day}";
    newSession.startTime = startTime;
    newSession.endTime = endTime;

    await _studySessionService.saveStudySession(newSession);
    await _databaseService.saveStudySession(newSession);
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  // Helper pour afficher le calendrier natif
  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // Helper pour afficher l'horloge native
  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Study Session'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSession, // Appel de la méthode corrigée
          ),
        ],
      ),
      // Remplacement du Container par un ListView pour permettre le scroll avec le clavier
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextField(
            controller: subjectController,
            decoration: const InputDecoration(
              labelText: 'Subject',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: durationController,
            decoration: const InputDecoration(
              labelText: 'Duration (minutes)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16.0),
          
          // Sélecteur de Date Stylisé (évite les erreurs de frappe)
          ListTile(
            title: Text(_selectedDate == null 
                ? 'Select Date' 
                : 'Date: ${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day}'),
            trailing: const Icon(Icons.calendar_today),
            tileColor: const Color.fromARGB(255, 53, 51, 51),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16.0),

          // Sélecteur d'Heure Stylisé
          ListTile(
            title: Text(_selectedTime == null 
                ? 'Select Start Time' 
                : 'Start Time: ${_selectedTime!.format(context)}'),
            trailing: const Icon(Icons.access_time),
            tileColor: const Color.fromARGB(255, 53, 51, 51),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onTap: _pickTime,
          ),
          const SizedBox(height: 16.0),
          
          TextField(
            controller: notesController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
            maxLines: 5, // Réduit à 5 pour laisser de la place visuelle, mais extensible
          ),
        ],
      ),
    );
  }
}
  