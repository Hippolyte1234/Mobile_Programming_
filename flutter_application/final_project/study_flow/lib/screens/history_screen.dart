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
  final TextEditingController _searchController = TextEditingController();

  List<StudySession> _allSessions = [];
  List<StudySession> _filteredSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllSessions();
    _searchController.addListener(_filterSessions);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllSessions() async {
    setState(() => _isLoading = true);

    // Fetch from both local and remote sources
    final remoteSessions = await _databaseService.fetchHistory();

    // Simple de-duplication based on firestoreId
    final uniqueSessions = <String, StudySession>{};
    for (var session in remoteSessions) {
      if (session.firestoreId != null) {
        uniqueSessions[session.firestoreId!] = session;
      }
    }

    if (mounted) {
      setState(() {
        _allSessions = uniqueSessions.values.toList();
        // Sort by start time, newest first
        _allSessions.sort((a, b) => (b.startTime ?? DateTime(0)).compareTo(a.startTime ?? DateTime(0)));
        _filteredSessions = _allSessions;
        _isLoading = false;
      });
    }
  }

  void _filterSessions() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSessions = _allSessions.where((session) {
        final subjectMatch = session.subject?.toLowerCase().contains(query) ?? false;
        final notesMatch = session.notes?.toLowerCase().contains(query) ?? false;
        return subjectMatch || notesMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: _filteredSessions.isEmpty ? _buildEmptyState() : _buildSessionList(_filteredSessions),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.history, size: 80, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          _searchController.text.isEmpty
              ? 'No study sessions logged yet'
              : 'No sessions found',
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Search by subject or notes',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
      ),
    );
  }

  Widget _buildSessionList(List<StudySession> sessions) {
    return ListView.builder(
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        final localScrollController = ScrollController();
        return ListTile(
          title: Text(session.subject ?? 'Unknown Subject', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Duration: ${session.duration} - Date: ${session.date}'),
              if (session.notes != null && session.notes!.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 100),
                  width: double.infinity, 
                  child: Scrollbar(
                    controller: localScrollController, 
                    thumbVisibility: true,             
                    trackVisibility: false,            
                    child: SingleChildScrollView(
                      controller: localScrollController,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0), 
                        child: Text(
                          session.notes!,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
                _fetchAllSessions(); // Refresh the list
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
                _fetchAllSessions(); // Refresh the list
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
