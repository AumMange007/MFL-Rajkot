import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/student_model.dart';
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

// ── Student Management State ──────────────────────────────────────────────────
class StudentManagementNotifier extends StateNotifier<AsyncValue<List<StudentModel>>> {
  final SupabaseClient _supabase;
  final UserModel? _admin;
  final Ref _ref;

  StudentManagementNotifier(this._supabase, this._admin, this._ref) : super(const AsyncValue.loading()) {
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    if (_admin == null) return;
    state = const AsyncValue.loading();
    _ref.invalidate(adminStatsProvider);
    try {
      final data = await _supabase
          .from(AppConstants.studentsTable)
          .select('''
            *,
            users:user_id (name, email, username, avatar_url),
            batches:batch_id (name)
          ''')
          .eq('institute_id', _admin.instituteId)
          .order('enrolled_at', ascending: false);
      
      final students = (data as List).map((e) => StudentModel.fromJson(e)).toList();
      state = AsyncValue.data(students);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addStudent({
    required String name,
    required String email,
    required String phone,
    required String username,
    required String password,
    required String batchId,
  }) async {
    if (_admin == null) return;
    
    String effectiveEmail = email.trim();
    if (effectiveEmail.isEmpty) {
      effectiveEmail = '${username.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}@elite.com';
    }
    
    // Pre-check for username duplicate in current list
    final currentStudents = state.valueOrNull ?? [];
    if (currentStudents.any((s) => s.studentUsername?.toLowerCase() == username.toLowerCase())) {
      throw 'Username "$username" is already taken.';
    }

    try {
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse('${AppConstants.supabaseUrl}/auth/v1/signup'));
      
      request.headers.set('apikey', AppConstants.supabaseAnonKey);
      request.headers.set('Content-Type', 'application/json');
      
      request.add(utf8.encode(jsonEncode({
        'email': effectiveEmail,
        'password': password,
        'data': {
          'name': name,
          'role': 'student',
          'phone': phone,
          'needs_password_reset': true,
        },
      })));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      final decodedResponse = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode != 200 && response.statusCode != 201) {
        final msg = decodedResponse['msg'] ?? decodedResponse['error_description'] ?? 'Failed';
        if (msg.toString().contains('User already registered') || msg.toString().contains('already exists')) {
          throw 'This email is already registered in Authentication. Please delete the user from the Supabase Dashboard -> Auth tab before re-creating them.';
        }
        throw msg;
      }

      final newUser = decodedResponse['user'];
      if (newUser == null) throw 'Failed to create auth user';
      final userId = newUser['id'] as String;

      await _supabase.from(AppConstants.usersTable).insert({
        'id': userId,
        'name': name,
        'email': effectiveEmail,
        'phone': phone,
        'username': username,
        'role': 'student',
        'institute_id': _admin.instituteId,
      });

      await _supabase.from(AppConstants.studentsTable).insert({
        'user_id': userId,
        'batch_id': batchId,
        'institute_id': _admin.instituteId,
      });

      await fetchStudents();
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

  Future<void> deleteStudent(StudentModel student) async {
    try {
      // 1. Delete from related DB tables first
      await _supabase.from(AppConstants.studentsTable).delete().eq('id', student.id);
      await _supabase.from(AppConstants.usersTable).delete().eq('id', student.userId);
      
      // 2. Delete from Auth (this is critical)
      await _supabase.rpc('delete_auth_user', params: {'target_uid': student.userId});
      
      // 3. Clear relevant caches to avoid stale UI
      _ref.invalidate(adminStatsProvider);
      _ref.invalidate(adminBatchesProvider);
      
      await fetchStudents();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateStudentProfile({
    required String studentId,
    required String name,
    required String batchId,
    required String level,
    required String language,
    required String vocabChap,
    required String grammarChap,
    required String kbChap,
    required String ubChap,
    String? mobile,
    String? parentMobile,
    String? address,
    String? dob,
  }) async {
    try {
      // 1. Update students table
      await _supabase.from(AppConstants.studentsTable).update({
        'batch_id': batchId,
        'level': level,
        'language': language,
        'vocab_chap': vocabChap,
        'grammar_chap': grammarChap,
        'kb_chap': kbChap,
        'ub_chap': ubChap,
        'mobile': mobile,
        'parent_mobile': parentMobile,
        'address': address,
        'dob': dob,
        'progress_updated_at': DateTime.now().toIso8601String(),
      }).eq('id', studentId);
      
      // 2. Refresh list
      await fetchStudents();
    } catch (e) {
      rethrow;
    }
  }
}

final studentManagementProvider = 
    StateNotifierProvider<StudentManagementNotifier, AsyncValue<List<StudentModel>>>((ref) {
  return StudentManagementNotifier(
    ref.watch(supabaseProvider),
    ref.watch(currentUserProvider),
    ref,
  );
});
