import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/notifications/notification_providers.dart';
import 'core/services/app_initialization_service.dart';
import 'app.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize app services (Firebase Core)
  await AppInitializationService.initialize();

  // Create a ProviderContainer to access providers before runApp
  final container = ProviderContainer();

  // Initialize our notification service
  // We read the provider to create the service instance, then call initialize.
  await container.read(notificationServiceProvider).initialize();
  
  runApp(
    // Pass the existing container to ProviderScope
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}