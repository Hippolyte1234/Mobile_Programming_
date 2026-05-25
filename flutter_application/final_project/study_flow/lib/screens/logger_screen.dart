import 'package:flutter/material.dart';
import 'package:study_flow/models/study_session.dart';

class LoggerScreen extends StatefulWidget {
  const LoggerScreen({super.key});
  
  @override
  State<LoggerScreen> createState() => LoggerScreenState();  
  }

class LoggerScreenState extends State<LoggerScreen> {

  TextEditingController subjectController = TextEditingController();
  TextEditingController durationController = TextEditingController();
  TextEditingController notesController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController startTimeController = TextEditingController();

  void saveStudySession(StudySession session) {
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
        title: Text('Log Study Session'),
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
          ],)
      )
    );
  }
}
  