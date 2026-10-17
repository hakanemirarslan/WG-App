import '../../../core/supabase_client.dart';

class Profile {
  final String id;
  final String displayName;
  final String locale;

  Profile({required this.id, required this.displayName, required this.locale});

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        id: map['id'] as String,
        displayName: map['display_name'] as String,
        locale: map['locale'] as String,
      );
}

class ProfileRepository {
  Future<Profile> fetchMyProfile() async {
    final userId = supabase.auth.currentUser!.id;
    final row = await supabase.from('profiles').select().eq('id', userId).single();
    return Profile.fromMap(row);
  }

  Future<void> updateProfile({required String displayName, required String locale}) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase.from('profiles').update({
      'display_name': displayName,
      'locale': locale,
    }).eq('id', userId);
  }
}
