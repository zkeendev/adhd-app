import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:adhd_app/features/auth/presentation/auth_screen.dart';
import 'package:adhd_app/home_screen.dart';
import 'package:adhd_app/features/chat/presentation/chat_screen.dart';
import 'package:adhd_app/core/routing/app_shell.dart';
import 'package:adhd_app/features/auth/auth_providers.dart';

// Route Paths and Names
const String authRoutePath = '/auth';
const String authRouteName = 'auth';

// The StatefulShellRoute will be at the root '/' when the user is logged in.
// The paths for its branches (tabs) are defined relative to the application root.
const String homeRoutePath = '/home'; // Full path for the home tab
const String homeRouteName = 'home';

const String chatRoutePath = '/chat'; // Full path for the chat tab
const String chatRouteName = 'chat';

// Navigator Keys
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellHomeNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellHome',
);
final _shellChatNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellChat',
);

final goRouterProvider = Provider<GoRouter>((ref) {
  final authListenable = ref.watch(authStateChangeNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation:
        authRoutePath, // Start at auth, redirect will handle if logged in
    refreshListenable: authListenable,
    debugLogDiagnostics: true, // Useful for debugging navigation
    routes: [
      // Auth Route (outside the shell)
      GoRoute(
        path: authRoutePath,
        name: authRouteName,
        builder: (context, state) => const AuthScreen(),
      ),
      // StatefulShellRoute for logged-in state with BottomNavigationBar
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) {
          // Return the AppShell widget that contains the BottomNavigationBar and the shell content
          return AppShell(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          // Branch 1: Home Tab
          StatefulShellBranch(
            navigatorKey: _shellHomeNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: homeRoutePath, // e.g., '/home'
                name: homeRouteName,
                builder:
                    (BuildContext context, GoRouterState state) =>
                        const HomeScreen(),
                // Example of a sub-route within the Home tab:
                // routes: <RouteBase>[
                //   GoRoute(
                //     path: 'details/:id', // e.g., '/home/details/123'
                //     name: 'homeDetails',
                //     builder: (context, state) => HomeDetailsScreen(id: state.pathParameters['id']!),
                //   ),
                // ],
              ),
            ],
          ),
          // Branch 2: Chat Tab
          StatefulShellBranch(
            navigatorKey: _shellChatNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: chatRoutePath, // e.g., '/chat'
                name: chatRouteName,
                builder:
                    (BuildContext context, GoRouterState state) =>
                        const ChatScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final authValue = authListenable.value; // This is AsyncValue<User?>

      // While auth state is resolving, don't redirect.
      // This prevents a flicker if the app starts and auth state is not yet known.
      if (authValue.isLoading || !authValue.hasValue) {
        // Check for hasValue to ensure User? is resolved
        return null;
      }

      final isLoggedIn = authValue.valueOrNull != null;
      final String currentLocation =
          state.matchedLocation; // The path GoRouter is trying to go to

      // If the user is not logged in:
      if (!isLoggedIn) {
        // If they are trying to access any path other than the auth path, redirect them to auth.
        // If they are already at the auth path, no redirect is needed.
        return currentLocation == authRoutePath ? null : authRoutePath;
      }

      // If the user is logged in:
      // If they are trying to access the auth path, redirect them to the default logged-in screen (e.g., home tab).
      if (currentLocation == authRoutePath) {
        return homeRoutePath; // Default to home tab
      }

      // If the user is logged in and trying to access the root path '/'
      // (which is where StatefulShellRoute is mounted if no specific tab path is given),
      // redirect them to the default tab's path.
      if (currentLocation == '/') {
        return homeRoutePath;
      }

      // In all other cases (logged in and accessing a valid app path), no redirect is needed.
      return null;
    },
  );
});
