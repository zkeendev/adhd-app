import 'package:adhd_app/features/auth/domain/auth_exceptions.dart';
import 'package:adhd_app/features/auth/domain/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthRepository(this._firebaseAuth);

  @override
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw LogInFailure.fromCode(e.code);
    } catch (_) {
      throw LogInFailure();
    }
  }

  @override
  Future<UserCredential> signUpWithEmailAndPassword(String email, String password) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw SignUpFailure.fromCode(e.code);
    } catch (_) {
      throw SignUpFailure();
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (_) {
      throw SignOutFailure();
    } catch (_) {
      throw SignOutFailure();
    }
  }
}
