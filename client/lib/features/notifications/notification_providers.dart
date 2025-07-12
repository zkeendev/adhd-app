import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/providers/firebase_providers.dart';
import 'fcm_token_manager.dart';
import 'notification_service.dart';

// Provider for FlutterLocalNotificationsPlugin instance
final flutterLocalNotificationsProvider =
    Provider<FlutterLocalNotificationsPlugin>((ref) {
      return FlutterLocalNotificationsPlugin();
    });

/// Provider that creates and holds the single instance of our [NotificationService].
///
/// By creating the service here, we ensure it's a singleton for the app's
/// lifetime. The `ref.onDispose` ensures that any subscriptions inside the
/// service are cancelled when the app is closed.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService(
    auth: ref.watch(firebaseAuthProvider),
    messaging: ref.watch(firebaseMessagingProvider),
    localNotifications: ref.watch(flutterLocalNotificationsProvider),
    tokenManager: ref.watch(fcmTokenManagerProvider),
  );

  // Clean up the service's subscriptions when the provider is disposed.
  ref.onDispose(() => service.dispose());

  return service;
});

final fcmTokenManagerProvider = Provider<FCMTokenManager>((ref) {
  final manager = FCMTokenManager(
    db: ref.watch(firebaseFirestoreProvider),
    fcm: ref.watch(firebaseMessagingProvider),
  );
  ref.onDispose(() {
    manager.dispose();
  });
  return manager;
});
