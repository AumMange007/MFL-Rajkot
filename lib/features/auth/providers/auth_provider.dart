import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/user_model.dart';
import '../../../core/constants/app_constants.dart';

// ── Raw Supabase client provider ──────────────────────────────────────────────
final supabaseProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

// ── Auth state change stream ──────────────────────────────────────────────────
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseProvider).auth.onAuthStateChange;
});

// ── AuthNotifier — handles login / logout and holds the current UserModel ─────
class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final SupabaseClient _supabase;

  AuthNotifier(this._supabase) : super(const AsyncValue.loading()) {
    _init();
  }

  /// Check for an existing session on app start
  Future<void> _init() async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      state = const AsyncValue.data(null);
      return;
    }
    await _fetchUser(session.user.id);
  }

  /// Sign in with email/username + password
  Future<void> signIn(String identifier, String password) async {
    state = const AsyncValue.loading();
    try {
      String email = identifier;
      
      // If it doesn't look like an email, assume it's a username
      if (!identifier.contains('@')) {
        final res = await _supabase.rpc('get_email_from_username', params: {'uname': identifier});
        if (res == null) {
          throw 'Username not found';
        }
        email = res as String;
      }

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        await _fetchUser(response.user!.id);
      } else {
        state = AsyncValue.error('Login failed', StackTrace.current);
      }
    } on AuthException catch (e, st) {
      state = AsyncValue.error(e.message, st);
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
    }
  }

  /// Sign out and clear state
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    state = const AsyncValue.data(null);
  }

  /// Manually refresh the user data from public.users
  Future<void> refreshUser() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid != null) {
      await _fetchUser(uid);
    }
  }

  /// Fetch user profile row from the public.users table
  Future<void> _fetchUser(String uid) async {
    try {
      final data = await _supabase
          .from(AppConstants.usersTable)
          .select()
          .eq('id', uid)
          .maybeSingle(); // Better than .single() here as we want to handle null

      if (data == null) {
        throw 'Your profile record is missing in the database. Please contact Admin.';
      }
      
      state = AsyncValue.data(UserModel.fromJson(data));
    } catch (e, st) {
      print('DEBUG: _fetchUser failed for UID $uid: $e');
      state = AsyncValue.error('Login error: $e', st);
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref.watch(supabaseProvider));
});

// ── Convenience: get the current user synchronously ──────────────────────────
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authNotifierProvider).valueOrNull;
});
