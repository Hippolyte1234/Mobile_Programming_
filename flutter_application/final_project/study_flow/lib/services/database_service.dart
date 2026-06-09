import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/study_session.dart';

class DatabaseService {
  // Instance de Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveStudySession(StudySession session) async {
    try {
      
      await _db.collection('study_sessions').add(session.toMap());
      print("Session saved");
    } catch (e) {
      print("Error to save session : $e");
      rethrow; 
    }
  }

  Future<List<StudySession>> fetchHistory() async {
    try {
      QuerySnapshot snapshot = await _db.collection('study_sessions').get();
      
      return snapshot.docs.map((doc) {
        return StudySession.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print("Error fetching history from Firestore : $e");
      return [];
    }
  }
}