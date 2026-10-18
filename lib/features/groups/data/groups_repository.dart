import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';

class Group {
  final String id;
  final String name;

  Group({required this.id, required this.name});

  factory Group.fromMap(Map<String, dynamic> map) =>
      Group(id: map['id'] as String, name: map['name'] as String);
}

class Member {
  final String userId;
  final String displayName;
  final bool isAdmin;

  Member({required this.userId, required this.displayName, required this.isAdmin});

  factory Member.fromMap(Map<String, dynamic> map) => Member(
        userId: map['user_id'] as String,
        displayName: (map['profiles'] as Map<String, dynamic>)['display_name'] as String,
        isAdmin: map['role'] == 'admin',
      );
}

/// Error codes raised by the `security definer` functions in schema.sql.
/// The server sends them as the exception message.
enum GroupError { invalidInvite, lastAdmin, notAdmin, notAMember, unknown }

GroupError groupErrorFrom(Object error) {
  final message = error is PostgrestException ? error.message : '$error';
  if (message.contains('invalid_or_expired_invite')) return GroupError.invalidInvite;
  if (message.contains('last_admin')) return GroupError.lastAdmin;
  if (message.contains('not_admin')) return GroupError.notAdmin;
  if (message.contains('not_a_member') || message.contains('target_not_member')) {
    return GroupError.notAMember;
  }
  return GroupError.unknown;
}

class GroupsRepository {
  /// RLS only returns groups where I am an active member.
  Future<List<Group>> fetchMyGroups() async {
    final rows = await supabase.from('groups').select('id, name').order('created_at');
    return rows.map(Group.fromMap).toList();
  }

  Future<Group> fetchGroup(String groupId) async {
    final row = await supabase.from('groups').select('id, name').eq('id', groupId).single();
    return Group.fromMap(row);
  }

  Future<String> createGroup(String name) async {
    final id = await supabase.rpc('create_group', params: {'group_name': name});
    return id as String;
  }

  Future<String> joinGroup(String code) async {
    final id = await supabase.rpc('join_group', params: {'invite_code': code});
    return id as String;
  }

  /// Returns the new invite code (valid 7 days, SPEC 10).
  Future<String> createInvite(String groupId) async {
    final row = await supabase
        .from('invites')
        .insert({'group_id': groupId, 'created_by': supabase.auth.currentUser!.id})
        .select('code')
        .single();
    return row['code'] as String;
  }

  Future<List<Member>> fetchMembers(String groupId) async {
    final rows = await supabase
        .from('memberships')
        .select('user_id, role, profiles(display_name)')
        .eq('group_id', groupId)
        .isFilter('left_at', null)
        .order('joined_at');
    return rows.map(Member.fromMap).toList();
  }

  Future<void> leaveGroup(String groupId) =>
      supabase.rpc('leave_group', params: {'gid': groupId});

  Future<void> setMemberRole(String groupId, String userId, {required bool admin}) =>
      supabase.rpc('set_member_role', params: {
        'gid': groupId,
        'target': userId,
        'new_role': admin ? 'admin' : 'member',
      });
}
