import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  /// Gets the Gemini API key, first checking the environment definition, 
  /// and then checking the user's Firestore settings.
  Future<String?> getApiKey() async {
    const envKey = String.fromEnvironment('GEMINI_API_KEY');
    if (envKey.isNotEmpty) return envKey;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data()?['geminiApiKey'] as String?;
  }

  /// Saves the user's custom Gemini API key to their Firestore document.
  Future<void> saveApiKey(String key) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("No user logged in");

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'geminiApiKey': key.trim(),
    }, SetOptions(merge: true));
  }

  /// Clears the user's custom Gemini API key from Firestore.
  Future<void> clearApiKey() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'geminiApiKey': FieldValue.delete(),
    });
  }

  /// Initializes a GenerativeModel using the configured API key.
  /// Throws an exception if no key is configured.
  Future<GenerativeModel> getModel() async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("Gemini API Key is not configured.");
    }
    return GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }
}
