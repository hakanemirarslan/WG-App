import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';
import '../../settings/providers/profile_providers.dart';
import 'groups_providers.dart';

/// Keeps group names/photos and member names/photos fresh without a reload: when
/// Realtime reports an UPDATE on `groups` or `profiles`, the providers showing them
/// load again. No filter is needed: Realtime applies RLS, so only my groups and the
/// people I share a group with arrive. Watched by the screens that show them; the
/// subscription ends when none of them is open (autoDispose).
final groupLiveUpdatesProvider = Provider.autoDispose<void>((ref) {
  final channel = supabase
      .channel('group_meta')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'groups',
        callback: (payload) {
          final id = payload.newRecord['id'] as String?;
          if (id != null) ref.invalidate(groupProvider(id));
          ref.invalidate(myGroupsProvider);
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'profiles',
        callback: (payload) {
          ref.invalidate(groupMembersProvider);
          if (payload.newRecord['id'] == supabase.auth.currentUser?.id) {
            ref.invalidate(myProfileProvider);
          }
        },
      )
      .subscribe();
  ref.onDispose(() => supabase.removeChannel(channel));
});
