import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/user_model.dart';
import '../../../models/batch_model.dart';
import 'admin_stats_provider.dart';
import '../../auth/providers/auth_provider.dart';

// ── Batches Provider ─────────────────────────────────────────────────────────
final adminBatchesProvider = FutureProvider<List<BatchModel>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final data = await supabase
      .from(AppConstants.batchesTable)
      .select()
      .eq('institute_id', user.instituteId);
  
  return (data as List).map((e) => BatchModel.fromJson(e)).toList();
});

// ── Staff Management State ──────────────────────────────────────────────────
class StaffManagementNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final SupabaseClient _supabase;
  final UserModel? _admin;
  final Ref _ref;

  StaffManagementNotifier(this._supabase, this._admin, this._ref) : super(const AsyncValue.loading()) {
    fetchStaff();
  }

  Future<void> fetchStaff() async {
    if (_admin == null) return;
    state = const AsyncValue.loading();
    try {
      final data = await _supabase
          .from(AppConstants.usersTable)
          .select()
          .eq('institute_id', _admin.instituteId)
          .inFilter('role', ['tutor', 'staff'])
          .order('name', ascending: true);
      
      final staff = (data as List).map((e) => UserModel.fromJson(e)).toList();
      state = AsyncValue.data(staff);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addStaff({
    required String name,
    required String email,
    required String phone,
    required String username,
    required String password,
    required String role, // 'tutor' or 'staff'
  }) async {
    if (_admin == null) return;
    
    String effectiveEmail = email.trim();
    if (effectiveEmail.isEmpty) {
      effectiveEmail = '${username.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}@elite.com';
    }

    // Pre-check for username duplicate in current list to provide better error
    final currentStaff = state.valueOrNull ?? [];
    if (currentStaff.any((s) => s.username?.toLowerCase() == username.toLowerCase())) {
      throw 'Username "$username" is already taken. Please use a different username.';
    }

    try {
      // 1. Create Auth user via REST (the same hack we use for students to avoid session loss)
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse('${AppConstants.supabaseUrl}/auth/v1/signup'));
      request.headers.set('apikey', AppConstants.supabaseAnonKey);
      request.headers.set('Content-Type', 'application/json');
      request.add(utf8.encode(jsonEncode({
        'email': effectiveEmail,
        'password': password,
        'data': {
          'name': name,
          'role': role,
          'phone': phone,
          'needs_password_reset': true,
        },
      })));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;

      if (response.statusCode != 200 && response.statusCode != 201) {
        final msg = data['msg'] ?? data['error_description'] ?? 'Failed';
        if (msg.toString().contains('already registered')) throw 'Email already in use in Auth.';
        throw msg;
      }

      final userId = data['user']['id'] as String;

      // 2. Add to public.users
      await _supabase.from(AppConstants.usersTable).insert({
        'id': userId,
        'name': name,
        'email': effectiveEmail,
        'phone': phone,
        'username': username,
        'role': role,
        'institute_id': _admin.instituteId,
      });

      // 3. For tutors, add default record in tutors profile table too
      if (role == 'tutor') {
        await _supabase.from('tutors').insert({
          'user_id': userId,
          'institute_id': _admin.instituteId,
        });
      }

      await fetchStaff();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateStaffProfile({
    required String userId,
    required String name,
    required String role,
    required String phone,
    String? email,
  }) async {
    try {
      await _supabase.from(AppConstants.usersTable).update({
        'name': name,
        'role': role,
        'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
      }).eq('id', userId);

      await fetchStaff();
      // Invalidate stats to reflect possible role counts
      _ref.invalidate(adminStatsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> manualResetPassword(String userId, String newPassword) async {
    try {
      await _supabase.rpc('admin_reset_password', params: {
        'target_uid': userId,
        'new_password': newPassword,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteStaff(UserModel member) async {
    try {
      // Use the RPC bridge we built!
      await _supabase.rpc('delete_auth_user', params: {'target_uid': member.id});
      
      // Clear relevant admin stats/lists
      _ref.invalidate(adminStatsProvider);
      
      await fetchStaff();
    } catch (e) {
       rethrow;
    }
  }
}

final staffManagementProvider = 
    StateNotifierProvider<StaffManagementNotifier, AsyncValue<List<UserModel>>>((ref) {
  return StaffManagementNotifier(
    ref.watch(supabaseProvider),
    ref.watch(currentUserProvider),
    ref,
  );
});
