import 'package:study_flow/models/study_session.dart';

class StudySessionService {
  static final StudySessionService _instance = StudySessionService._internal();

  StudySessionService._internal();

  factory StudySessionService() {
    return _instance;
  }

  final List<StudySession> _sessions = [];

  Future<List<StudySession>> fetchHistory() async {
    return List.from(_sessions);
  }

  Future<void> saveStudySession(StudySession session) async {
    _sessions.add(session);
  }
}