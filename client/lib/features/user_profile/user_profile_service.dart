import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_profile.dart';

class UserProfileService {
  final FirebaseFirestore _firestore;

  UserProfileService(this._firestore);

  /// Creates a user profile document in Firestore.
  ///
  /// Throws a [FirebaseException] if the operation fails.
  Future<void> createUserProfile(UserProfile userProfile) async {
    try {
      await _firestore
          .collection(UserProfile.collectionName)
          .doc(userProfile.uid)
          .set(userProfile.toJson());
    } on FirebaseException {
      // Re-throw the specific Firebase exception to be handled by the caller.
      rethrow;
    } catch (e) {
      // For any other unexpected errors, wrap them in a generic Exception.
      throw Exception(
          'An unknown error occurred while creating the user profile: $e');
    }
  }
}