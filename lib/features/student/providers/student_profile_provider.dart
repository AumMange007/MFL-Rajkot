import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/student_model.dart';
import '../../auth/providers/auth_provider.dart';

import '../../admin/providers/student_management_provider.dart';

class StudentProfileNotifier extends StateNotifier<AsyncValue<StudentModel?>> {
  final SupabaseClient _supabase;
  final String? _userId;
  final Ref _ref;

  StudentProfileNotifier(this._supabase, this._userId, this._ref) : super(const AsyncValue.loading()) {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    if (_userId == null) return;
    try {
      final data = await _supabase
          .from(AppConstants.studentsTable)
          .select('''
            *,
            users:user_id (id, name, email, avatar_url),
            batches:batch_id (
              name,
              tutors:tutor_id (name)
            )
          ''')
          .eq('user_id', _userId!)
          .maybeSingle();

      if (data == null) {
        state = const AsyncValue.data(null);
        return;
      }

      // Format the tutor name from the nested join safely
      final studentData = Map<String, dynamic>.from(data);
      final batches = data['batches'];
      if (batches is Map && batches['tutors'] != null) {
        studentData['tutors'] = batches['tutors'];
      }

      state = AsyncValue.data(StudentModel.fromJson(studentData));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile({
    String? mobile,
    String? parentMobile,
    String? address,
    String? dob,
  }) async {
    if (_userId == null) return;
    try {
      await _supabase.from(AppConstants.studentsTable).update({
        'mobile': mobile,
        'parent_mobile': parentMobile,
        'address': address,
        'dob': dob,
      }).eq('user_id', _userId!);
      
      // Refresh current student state
      await fetchProfile();
      
      // Invalidate admin's student list to reflect changes
      _ref.invalidate(studentManagementProvider);
    } catch (e) {
      rethrow;
    }
  }
}

final studentProfileProvider = 
    StateNotifierProvider<StudentProfileNotifier, AsyncValue<StudentModel?>>((ref) {
  final user = ref.watch(currentUserProvider);
  return StudentProfileNotifier(ref.watch(supabaseProvider), user?.id, ref);
});
