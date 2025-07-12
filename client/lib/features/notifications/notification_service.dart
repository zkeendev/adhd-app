import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'fcm_token_manager.dart';


class NotificationService {
  final FirebaseAuth _auth;
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final FCMTokenManager _tokenManager;

  // Internal state management for stream subscriptions.
  StreamSubscription? _authStateSubscription;
  StreamSubscription? _foregroundMessageSubscription;
  String? _currentUserId;

  NotificationService({
    required FirebaseAuth auth,
    required FirebaseMessaging messaging,
    required FlutterLocalNotificationsPlugin localNotifications,
    required FCMTokenManager tokenManager,
  })  : _auth = auth,
        _messaging = messaging,
        _localNotifications = localNotifications,
        _tokenManager = tokenManager;


  Future<void> initialize() async {
    debugPrint('[NotificationService] Initializing runtime listeners...');
    await _requestPermissions();
    _listenForForegroundMessages();
    _listenForAuthStateChanges();
    debugPrint('[NotificationService] Runtime listeners initialized.');
  }


  void dispose() {
    debugPrint('[NotificationService] Disposing listeners...');
    _authStateSubscription?.cancel();
    _foregroundMessageSubscription?.cancel();
  }


  Future<void> _requestPermissions() async {
    try {
      final settings = await _messaging.requestPermission();
      debugPrint('[NotificationService] Device permission status: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('[NotificationService] Failed to request permissions: $e');
    }
  }


  void _listenForAuthStateChanges() {
    _authStateSubscription = _auth.authStateChanges().listen((User? user) async {
      final previousUserId = _currentUserId;

      if (user == null) { // USER LOGGED OUT
        if (previousUserId != null) {
          debugPrint('[NotificationService] Auth state changed: User logged out.');
          await _tokenManager.cleanupForUser(previousUserId);
        }
        _currentUserId = null;
      } else { // USER LOGGED IN
        debugPrint('[NotificationService] Auth state changed: User logged in (${user.uid}).');
        
        if (previousUserId != null && previousUserId != user.uid) {
          debugPrint('[NotificationService] Cleaning up previous user ($previousUserId) before switching.');
          // On user switch, remove the token from the old user's doc,
          // but DO NOT delete it from the device.
          await _tokenManager.cleanupForUser(
            previousUserId, 
            deleteLocalToken: false,
          );
        }

        _currentUserId = user.uid;
        await _tokenManager.setupForUser(user.uid);
      }
    });
  }

  
  void _listenForForegroundMessages() {
    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
      onError: (error) {
        debugPrint('[NotificationService] Error in foreground message stream: $error');
      },
    );
  }


  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[NotificationService] Received foreground message: ${message.messageId}');

    final notification = message.notification;
    if (notification != null && !kIsWeb) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          // Uses the channel ID that was created in AppInitializationService.
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  }
}