import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/firebase_providers.dart';
import 'user_profile_service.dart';

final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return UserProfileService(firestore);
});