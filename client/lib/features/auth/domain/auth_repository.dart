import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Stream<User?> authStateChanges();
  User? get currentUser;
  Future<UserCredential> signUpWithEmailAndPassword(String email, String password);
  Future<UserCredential> signInWithEmailAndPassword(String email, String password);
  Future<void> signOut();
}