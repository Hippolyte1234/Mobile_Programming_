import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/study_session.dart';

class DatabaseService {
  // Instance de Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveStudySession(StudySession session) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("No user logged in");

      await _db
          .collection('users')
          .doc(user.uid)
          .collection('study_sessions')
          .add(session.toMap());
      print("Session saved");
    } catch (e) {
      print("Error to save session : $e");
      rethrow;
    }
  }

  Future<void> updateStudySession(StudySession session) async {
    try {
      if (session.firestoreId != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception("No user logged in");

        await _db
            .collection('users')
            .doc(user.uid)
            .collection('study_sessions')
            .doc(session.firestoreId)
            .update(session.toMap());
        print("Session updated");
      }
    } catch (e) {
      print("Error updating session: $e");
      rethrow;
    }
  }

  Future<void> deleteStudySession(StudySession session) async {
    try {
      if (session.firestoreId != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception("No user logged in");

        await _db
            .collection('users')
            .doc(user.uid)
            .collection('study_sessions')
            .doc(session.firestoreId)
            .delete();
        print("Session deleted");
      }
    } catch (e) {
      print("Error deleting session: $e");
      rethrow;
    }
  }

  Future<List<StudySession>> fetchHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return []; // Return empty list if no user is logged in

      QuerySnapshot snapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('study_sessions')
          .get();

      return snapshot.docs.map((doc) {
        return StudySession.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print("Error fetching history from Firestore : $e");
      return [];
    }
  }
}
