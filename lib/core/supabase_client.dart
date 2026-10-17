import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> initSupabase() async {
  await Supabase.initialize(url: _supabaseUrl, publishableKey: _supabaseAnonKey);
}

SupabaseClient get supabase => Supabase.instance.client;
