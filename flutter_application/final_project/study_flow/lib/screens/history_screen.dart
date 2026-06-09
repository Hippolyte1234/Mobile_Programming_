import 'package:flutter/material.dart';
import 'package:study_flow/models/study_session.dart';
import 'package:study_flow/services/notifications_service.dart';
import 'package:study_flow/services/study_session_service.dart';
import 'package:study_flow/services/database_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final StudySessionService _studySessionService = StudySessionService();
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Center(
        child: FutureBuilder<List<StudySession>>(
          future: _fetchAllSessions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error : ${snapshot.error}'));
            }

            final sessions = snapshot.data ?? [];
            if (sessions.isEmpty) {
              return _buildEmptyState();
            }
            return _buildSessionList(sessions);
          },
        ),
      ),
    );
  }

  Future<List<StudySession>> _fetchAllSessions() async {
    final localSessions = await _studySessionService.fetchHistory();
    final remoteSessions = await _databaseService.fetchHistory();

    // On combine les deux listes dans une seule
    return [...localSessions, ...remoteSessions];
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.history, size: 80, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          'No study sessions logged yet',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildSessionList(List<StudySession> sessions) {
    return ListView.builder(
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return ListTile(
          title: Text(session.subject ?? 'Unknown Subject'),
          subtitle: Text('${session.duration} - ${session.date}'),
          onTap: () {
            _showEditDialog(session);
          },
        );
      },
    );
  }

  void _showEditDialog(StudySession session) {
    final TextEditingController subjectController = TextEditingController(
      text: session.subject,
    );
    final TextEditingController durationController = TextEditingController(
      text: session.duration,
    );
    final TextEditingController notesController = TextEditingController(
      text: session.notes,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Session'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (e.g., 2h 30m)',
                  ),
                ),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _studySessionService.deleteStudySession(session);
                if (session.firestoreId != null) {
                  await _databaseService.deleteStudySession(session);
                }
                await NotificationService.showStudySessionDeletedNotification();

                if (!context.mounted) return;
                Navigator.pop(context);
                setState(() {}); // Refresh the list
              },
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                session.subject = subjectController.text;
                session.duration = durationController.text;
                session.notes = notesController.text;

                if (session.firestoreId != null) {
                  await _databaseService.updateStudySession(session);
                } else {
                  await _studySessionService.updateStudySession(session);
                }
                await NotificationService.showStudySessionModifiedNotification();


                if (!context.mounted) return;
                Navigator.pop(context);
                setState(() {}); // Refresh the list
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
