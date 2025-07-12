import 'package:adhd_app/features/auth/application/auth_controller.dart';
import 'package:adhd_app/features/auth/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the userStreamProvider to get the current user's information
    // This is useful for displaying user-specific content like their email.
    final userAsyncValue = ref.watch(userStreamProvider);
    final user = userAsyncValue.valueOrNull; // Get User? or null

    // Watch the AuthController's state for the sign-out operation (loading/error)
    final authOperationState = ref.watch(authControllerProvider);
    final isSigningOut = authOperationState.isLoading;

    // Listen for errors during sign-out to show a SnackBar
    ref.listen<AsyncValue<void>>(authControllerProvider, (_, state) {
      state.whenOrNull(
        error: (error, stackTrace) {
          // Ensure widget is still mounted before showing SnackBar
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error.toString()), // Uses message from SignOutFailure
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        // Optionally, hide the back button if you don't want users to navigate
        // back to the auth screen manually after being redirected here.
        // GoRouter's redirect logic should handle this, but can be explicit.
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Sign Out',
            // Disable button if already signing out
            onPressed:
                isSigningOut
                    ? null
                    : () async {
                      // Call the signOut method on your AuthController
                      await ref.read(authControllerProvider.notifier).signOut();
                      // GoRouter will handle navigation to the login screen
                      // due to the auth state change.
                    },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                'Welcome to the Home Screen!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (user != null)
                Text(
                  'You are signed in as: ${user.email ?? 'Unknown Email'}',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                )
              else if (userAsyncValue.isLoading)
                const CircularProgressIndicator() // Show loading if user data is still fetching
              else
                Text(
                  'User information not available.', // Should not happen if redirected correctly
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 40),
              if (isSigningOut)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).signOut();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
