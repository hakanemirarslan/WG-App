import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) => ProfileRepository());

final myProfileProvider = FutureProvider<Profile>((ref) {
  return ref.watch(profileRepositoryProvider).fetchMyProfile();
});

final myPrivateProfileProvider = FutureProvider.autoDispose<PrivateProfile>((ref) {
  return ref.watch(profileRepositoryProvider).fetchMyPrivateProfile();
});
