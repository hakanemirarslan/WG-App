import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/groups_repository.dart';

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) => GroupsRepository());

final myGroupsProvider = FutureProvider<List<Group>>((ref) {
  return ref.watch(groupsRepositoryProvider).fetchMyGroups();
});

final groupProvider = FutureProvider.family<Group, String>((ref, groupId) {
  return ref.watch(groupsRepositoryProvider).fetchGroup(groupId);
});

final groupMembersProvider = FutureProvider.family<List<Member>, String>((ref, groupId) {
  return ref.watch(groupsRepositoryProvider).fetchMembers(groupId);
});
