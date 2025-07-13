import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../user_profile/user_profile.dart';

class FCMTokenManager {
  final FirebaseFirestore _db;
  final FirebaseMessaging _fcm;
  StreamSubscription? _tokenRefreshSubscription;

  FCMTokenManager({
    required FirebaseFirestore db,
    required FirebaseMessaging fcm,
  }) : _db = db,
       _fcm = fcm;

  Future<void> setupForUser(String userId) async {
    await _tokenRefreshSubscription?.cancel();

    final token = await _fcm.getToken();
    if (token == null) {
      debugPrint('[FCMTokenManager] Could not get FCM token for user $userId.');
      return;
    }
    await _saveTokenToFirestore(userId, token);

    _tokenRefreshSubscription = _fcm.onTokenRefresh.listen((refreshedToken) {
      _saveTokenToFirestore(userId, refreshedToken);
    });
    debugPrint('[FCMTokenManager] Setup complete for user $userId.');
  }

  Future<void> cleanupForUser(
    String userId, {
    bool deleteLocalToken = true,
  }) async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;

    final token = await _fcm.getToken();
    if (token != null) {
      await _removeTokenFromFirestore(userId, token);
    }

    if (deleteLocalToken) {
      await _fcm.deleteToken();
      debugPrint('[FCMTokenManager] Local FCM token deleted.');
    }
    debugPrint('[FCMTokenManager] Cleanup complete for user $userId.');
  }

  Future<void> _saveTokenToFirestore(String userId, String token) async {
    try {
      final userDocRef = _db.collection(UserProfile.collectionName).doc(userId);
      await userDocRef.update({
        UserProfile.fcmTokensField: FieldValue.arrayUnion([token]),
      });
      debugPrint('[FCMTokenManager] FCM token saved to Firestore');
    } catch (e) {
      debugPrint('[FCMTokenManager] Error saving FCM token to Firestore');
    }
  }

  Future<void> _removeTokenFromFirestore(String userId, String token) async {
    try {
      final userDocRef = _db.collection(UserProfile.collectionName).doc(userId);
      await userDocRef.update({
        UserProfile.fcmTokensField: FieldValue.arrayRemove([token]),
      });
      debugPrint('[FCMTokenManager] FCM token removed from Firestore');
    } catch (e) {
      debugPrint('[FCMTokenManager] Error removing FCM token from Firestore');
    }
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
  }
}
