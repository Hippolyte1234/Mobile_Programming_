import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  Uint8List _xorCipher(String input, String key) {
    final inputBytes = utf8.encode(input);
    final keyBytes = utf8.encode(key);
    final resultBytes = Uint8List(inputBytes.length);

    for (int i = 0; i < inputBytes.length; i++) {
      resultBytes[i] = inputBytes[i] ^ keyBytes[i % keyBytes.length];
    }
    return resultBytes;
  }

  String _xorDecipher(Uint8List bytes, String key) {
    final keyBytes = utf8.encode(key);
    final resultBytes = Uint8List(bytes.length);

    for (int i = 0; i < bytes.length; i++) {
      resultBytes[i] = bytes[i] ^ keyBytes[i % keyBytes.length];
    }
    return utf8.decode(resultBytes);
  }

  /// Validates if the key matches the Gemini API key format (starts with AIza or AQ.).
  static bool isValidApiKey(String key) {
    return RegExp(r'^(AIza|AQ\.)[a-zA-Z0-9\-_\.]+$').hasMatch(key);
  }

  /// Gets the Gemini API key, first checking the environment definition, 
  /// and then checking the user's Firestore settings.
  Future<String?> getApiKey() async {
    const envKey = String.fromEnvironment('GEMINI_API_KEY');
    if (envKey.isNotEmpty) return envKey;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final dynamic data = doc.data()?['geminiApiKey'];
    if (data == null) return null;

    if (data is Blob) {
      return _xorDecipher(data.bytes, user.uid);
    } else if (data is String) {
      // Migrate old plain-text key to encrypted Blob
      final encryptedBytes = _xorCipher(data, user.uid);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'geminiApiKey': Blob(encryptedBytes),
      }, SetOptions(merge: true));
      return data;
    }
    return null;
  }

  /// Saves the user's custom Gemini API key to their Firestore document.
  Future<void> saveApiKey(String key) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("No user logged in");

    final encryptedBytes = _xorCipher(key.trim(), user.uid);
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'geminiApiKey': Blob(encryptedBytes),
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
      model: 'gemini-2.5-flash-lite',
      apiKey: apiKey,
    );
  }
}
