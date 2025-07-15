import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/timezone_service.dart';
import '../auth_providers.dart';
import '../domain/auth_exceptions.dart';
import '../domain/auth_repository.dart';
import '../../user_profile/user_profile.dart';
import '../../user_profile/user_profile_providers.dart';
import '../../user_profile/user_profile_service.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(() {
  return AuthController();
});

class AuthController extends AsyncNotifier<void> {
  AuthRepository get _authRepository => ref.read(authRepositoryProvider);
  UserProfileService get _userProfileService =>
      ref.read(userProfileServiceProvider);
  TimezoneService get _timezoneService => ref.read(timezoneServiceProvider);

  @override
  Future<void> build() async {
    // No-op, build is for initial setup if needed
    return;
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signInWithEmailAndPassword(email, password);

      state = const AsyncValue.data(null);
    } on AuthException catch (e, s) {
      state = AsyncValue.error(e, s);
    } catch (e, s) {
      state = AsyncValue.error(LogInFailure(), s);
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      // Create user in Firebase Authentication
      final userCredential = await _authRepository.signUpWithEmailAndPassword(
        email,
        password,
      );

      // If auth user creation is successful, create user profile in Firestore
      if (userCredential.user != null) {
        final firebaseUser = userCredential.user!;

        final String localTimezone = await _timezoneService.getLocalTimezone();

        final newUserProfile = UserProfile(
          uid: firebaseUser.uid,
          email: firebaseUser.email,
          timezone: localTimezone,
          // displayName will be null initially
          // createdAt will be set to server timestamp by UserProfile.toJson()
        );

        // This call might throw FirebaseException
        await _userProfileService.createUserProfile(newUserProfile);

        state = const AsyncValue.data(null);
      } else {
        throw SignUpFailure(
          "User authentication successful, but user data was not available to create profile.",
        );
      }
    } on AuthException catch (e, s) {
      state = AsyncValue.error(e, s);
    } on FirebaseException catch (e, s) {
      // The user is created but the profile is not. Give a specific error.
      state = AsyncValue.error(
        SignUpFailure(
          "Your account was created, but setting up your profile failed. Please try logging in or contact support.",
        ),
        s,
      );
    } catch (e, s) {
      state = AsyncValue.error(
        SignUpFailure(
          "An unexpected error occurred during sign up and profile creation.",
        ),
        s,
      );
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signOut();

      state = const AsyncValue.data(null);
    } on AuthException catch (e, s) {
      state = AsyncValue.error(e, s);
    } catch (e, s) {
      state = AsyncValue.error(SignOutFailure(), s);
    }
  }
}
