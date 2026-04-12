import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/user_model.dart';
import 'admin_stats_provider.dart';
import '../../auth/providers/auth_provider.dart';

// ── Tutor Management State ───────────────────────────────────────────────────
class TutorManagementNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final SupabaseClient _supabase;
  final UserModel? _admin;
  final Ref _ref;

  TutorManagementNotifier(this._supabase, this._admin, this._ref) : super(const AsyncValue.loading()) {
    fetchTutors();
  }

  Future<void> fetchTutors() async {
    if (_admin == null) return;
    state = const AsyncValue.loading();
    _ref.invalidate(adminStatsProvider);
    try {
      final data = await _supabase
          .from(AppConstants.usersTable)
          .select()
          .eq('institute_id', _admin!.instituteId)
          .eq('role', AppConstants.roleTutor)
          .order('name');
      
      final tutors = (data as List).map((e) => UserModel.fromJson(e)).toList();
      state = AsyncValue.data(tutors);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  Future<void> addTutor({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    if (_admin == null) return;

    String effectiveEmail = email.trim();
    if (effectiveEmail.isEmpty) {
      // Generate unique email based on timestamp to allow recreation of same name/username
      effectiveEmail = 'tutor_${DateTime.now().millisecondsSinceEpoch}@elite.com';
    }

    try {
      // Check for duplicate username (tutors use email/name usually, but we check users table)
      final existing = await _supabase.from(AppConstants.usersTable).select('id').eq('username', name.toLowerCase()).maybeSingle();
      if (existing != null) throw 'A user with this name/username already exists.';
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse('${AppConstants.supabaseUrl}/auth/v1/signup'));
      
      request.headers.set('apikey', AppConstants.supabaseAnonKey);
      request.headers.set('Content-Type', 'application/json');
      
      request.add(utf8.encode(jsonEncode({
        'email': effectiveEmail,
        'password': password,
        'data': {
          'name': name,
          'role': AppConstants.roleTutor,
          'phone': phone,
          'needs_password_reset': true,
        },
      })));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      final decodedResponse = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw decodedResponse['msg'] ?? decodedResponse['error_description'] ?? 'Failed to create auth user';
      }

      final newUser = decodedResponse['user'];
      if (newUser == null) throw 'Failed to create auth user';
      final userId = newUser['id'] as String;

      await _supabase.from(AppConstants.usersTable).insert({
        'id': userId,
        'name': name,
        'email': effectiveEmail,
        'phone': phone,
        'role': AppConstants.roleTutor,
        'institute_id': _admin!.instituteId,
      });

      await _supabase.from('tutors').insert({
        'user_id': userId,
        'institute_id': _admin!.instituteId,
      });

      await fetchTutors();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTutor(UserModel tutor) async {
    try {
      // 1. Clear any batch assignments
      await _supabase.from(AppConstants.batchesTable).update({'tutor_id': null}).eq('tutor_id', tutor.id);
      
      // 2. Clear tutor records
      await _supabase.from('tutors').delete().eq('user_id', tutor.id);
      
      // 3. Delete from Auth (public.users cascades if configured, but we do RPC for safety)
      await _supabase.rpc('delete_auth_user', params: {'target_uid': tutor.id});
      
      // 4. Invalidate related UI providers
      _ref.invalidate(adminStatsProvider);
      
      await fetchTutors();
    } catch (e) {
      rethrow;
    }
  }
}

final tutorManagementProvider = 
    StateNotifierProvider<TutorManagementNotifier, AsyncValue<List<UserModel>>>((ref) {
  return TutorManagementNotifier(
    ref.watch(supabaseProvider),
    ref.watch(currentUserProvider),
    ref,
  );
});
