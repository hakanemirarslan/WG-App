import '../../../core/supabase_client.dart';

class Profile {
  final String id;
  final String displayName;
  final String locale;

  /// Storage path of the profile photo (SPEC 18), null = none.
  final String? avatarPath;

  Profile({required this.id, required this.displayName, required this.locale, this.avatarPath});

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
    id: map['id'] as String,
    displayName: map['display_name'] as String,
    locale: map['locale'] as String,
    avatarPath: map['avatar_path'] as String?,
  );
}

/// Name and phone from `profile_private`: only the user can read them (RLS).
/// Accounts created before 2026-10-25 may have none of them.
class PrivateProfile {
  final String? firstName;
  final String? lastName;
  final String? phone;

  const PrivateProfile({this.firstName, this.lastName, this.phone});

  factory PrivateProfile.fromMap(Map<String, dynamic> map) => PrivateProfile(
    firstName: map['first_name'] as String?,
    lastName: map['last_name'] as String?,
    phone: map['phone'] as String?,
  );
}

class ProfileRepository {
  Future<Profile> fetchMyProfile() async {
    final userId = supabase.auth.currentUser!.id;
    final row = await supabase.from('profiles').select().eq('id', userId).single();
    return Profile.fromMap(row);
  }

  Future<PrivateProfile> fetchMyPrivateProfile() async {
    final userId = supabase.auth.currentUser!.id;
    final row = await supabase
        .from('profile_private')
        .select('first_name, last_name, phone')
        .eq('id', userId)
        .maybeSingle();
    return row == null ? const PrivateProfile() : PrivateProfile.fromMap(row);
  }

  /// Upsert: older accounts have no row yet. Empty values are stored as null.
  Future<void> savePrivateProfile(PrivateProfile profile) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase.from('profile_private').upsert({
      'id': userId,
      'first_name': profile.firstName,
      'last_name': profile.lastName,
      'phone': profile.phone,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> updateProfile({required String displayName, required String locale}) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase
        .from('profiles')
        .update({'display_name': displayName, 'locale': locale})
        .eq('id', userId);
  }

  /// Sets or clears (null) my profile photo (`profiles_update_own`).
  Future<void> setAvatar(String? path) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase.from('profiles').update({'avatar_path': path}).eq('id', userId);
  }

  /// Photo path per user id for everyone whose profile I may read (RLS: myself and
  /// the people I share a group with). One query for all avatars on screen.
  Future<Map<String, String>> fetchAvatarPaths() async {
    final rows = await supabase
        .from('profiles')
        .select('id, avatar_path')
        .not('avatar_path', 'is', null);
    return {for (final row in rows) row['id'] as String: row['avatar_path'] as String};
  }
}
