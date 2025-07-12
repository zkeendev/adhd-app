import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Retrieves the GoRouter instance for app navigation.
    final router = ref.watch(goRouterProvider);

    // Returns the MaterialApp with routing configuration.
    return MaterialApp.router(
      routerConfig: router,
      title: 'ADHD App',
      debugShowCheckedModeBanner: false,
    );
  }
}