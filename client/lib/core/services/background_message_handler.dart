import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../config/firebase_options.dart';

/// A top-level function to handle background messages.
///
/// This handler is registered in `AppInitializationService` and is called by the
/// OS when a message is received while the app is in the background or terminated.
/// It must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> backgroundMessageHandler(RemoteMessage message) async {
  // Must re-initialize Firebase in this separate isolate.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[BackgroundMessageHandler] Received background message: ${message.messageId}');
  // TODO: Implement logic to handle background data payloads if needed.
}