import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Créer un compte
  Future<User?> signUp(String email, String password) async {
    final res = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    return res.user;
  }

  // Connexion
  Future<User?> signIn(String email, String password) async {
    final res = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return res.user;
  }

  // Déconnexion
  Future<void> signOut() => _auth.signOut();

  // Stream pour savoir si l'utilisateur est connecté
  Stream<User?> get user => _auth.authStateChanges();
}