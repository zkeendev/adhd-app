import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import './domain/auth_repository.dart';
import './data/firebase_auth_repository.dart';
import '../../core/providers/firebase_providers.dart';
import '../../core/utils/async_value_notifier.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return FirebaseAuthRepository(firebaseAuth);
});

final userStreamProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges();
});

final currentUserProvider = Provider<User?>((ref) {
  final User? currentUser = ref.watch(userStreamProvider).valueOrNull;
  return currentUser;
});

final currentUserIdProvider = Provider<String?>((ref) {
  final User? currentUser = ref.watch(currentUserProvider);
  return currentUser?.uid;
});

final authStateChangeNotifierProvider = Provider<AsyncValueNotifier<User?>>((ref) {
  final asyncValue = ref.watch(userStreamProvider);
  final notifier = AsyncValueNotifier<User?>(asyncValue);

  ref.listen<AsyncValue<User?>>(userStreamProvider, (previousState, newState) {
    notifier.update(newState);
  });

  ref.onDispose(() => notifier.dispose());

  return notifier;
});