import 'package:supabase_flutter/supabase_flutter.dart';

/// Central accessor for the Supabase client.
/// Use [SupabaseService.client] anywhere you need raw Supabase access.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  static Session? get currentSession => client.auth.currentSession;

  static bool get isLoggedIn => currentSession != null;
}
