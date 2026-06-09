import 'package:flutter/material.dart';
import 'package:study_flow/models/study_session.dart';
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
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: Center(
        child: FutureBuilder<List<StudySession>>(
          future: _fetchAllSessions(),  
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Erreur : ${snapshot.error}'));
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
        Text('No study sessions logged yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
      ],
    );
  }
  Widget _buildSessionList(List<StudySession> sessions) {
    return ListView.builder(
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return ListTile(
          title: Text(session.subject??'Unknown Subject'),
          subtitle: Text('${session.duration} - ${session.date}'),
          onTap: () {
          },
          );
      },
    );
  }
}
