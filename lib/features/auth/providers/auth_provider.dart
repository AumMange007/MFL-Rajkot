import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../models/user_model.dart';
import '../../../core/constants/app_constants.dart';

// ── Shared Preferences Keys ──
const _kCachedUserKey = 'mfl_cached_user';

final supabaseProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseProvider).auth.onAuthStateChange;
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final SupabaseClient _supabase;

  AuthNotifier(this._supabase) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    // 1. Try to load from cache first for instant UI (Fixes "Slow Load" flaw)
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_kCachedUserKey);
    if (cachedData != null) {
      try {
        final user = UserModel.fromJson(jsonDecode(cachedData));
        state = AsyncValue.data(user);
      } catch (_) {}
    }

    // 2. Refresh from source of truth
    final session = _supabase.auth.currentSession;
    if (session == null) {
      // If no session, clear cache and state
      await prefs.remove(_kCachedUserKey);
      state = const AsyncValue.data(null);
      return;
    }
    await _fetchUser(session.user.id);
  }

  Future<void> signIn(String identifier, String password) async {
    state = const AsyncValue.loading();
    try {
      String email = identifier;
      
      if (!identifier.contains('@')) {
        final res = await _supabase.rpc('get_email_from_username', params: {'uname': identifier});
        if (res == null) throw 'Username not found';
        email = res as String;
      }

      final response = await _supabase.auth.signInWithPassword(email: email, password: password);
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

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCachedUserKey);
    await _supabase.auth.signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refreshUser() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid != null) await _fetchUser(uid);
  }

  Future<void> _fetchUser(String uid) async {
    try {
      final data = await _supabase
          .from(AppConstants.usersTable)
          .select()
          .eq('id', uid)
          .maybeSingle();

      if (data == null) {
        throw 'Your profile record is missing. Please contact Admin.';
      }
      
      final user = UserModel.fromJson(data);
      
      // 3. Cache the fresh user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCachedUserKey, jsonEncode(user.toJson()));
      
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error('Login error: $e', st);
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref.watch(supabaseProvider));
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authNotifierProvider).valueOrNull;
});
