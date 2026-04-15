import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/tutor_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../admin/providers/tutor_management_provider.dart';

class TutorProfileNotifier extends StateNotifier<AsyncValue<TutorModel?>> {
  final SupabaseClient _supabase;
  final String? _userId;
  final Ref _ref;

  TutorProfileNotifier(this._supabase, this._userId, this._ref) : super(const AsyncValue.loading()) {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    if (_userId == null) return;
    try {
      final data = await _supabase
          .from(AppConstants.tutorsTable)
          .select('''
            *,
            users:user_id (id, name, email, avatar_url)
          ''')
          .eq('user_id', _userId)
          .maybeSingle();

      if (data == null) {
        // If profile doesn't exist, create an empty one (so RLS doesn't block it later)
        // or just return null
        state = const AsyncValue.data(null);
        return;
      }

      state = AsyncValue.data(TutorModel.fromJson(data));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile({
    String? mobile,
    String? address,
    String? bio,
    String? experience,
    String? specialization,
    String? qualification,
    String? dob,
  }) async {
    if (_userId == null) return;
    try {
      // Upsert so if it doesn't exist it creates it
      final user = _ref.read(currentUserProvider);
      if (user == null) return;

      await _supabase.from(AppConstants.tutorsTable).update({
        'institute_id': user.instituteId,
        'mobile': mobile,
        'address': address,
        'bio': bio,
        'experience': experience,
        'specialization': specialization,
        'qualification': qualification,
        'dob': dob,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', _userId);
      
      // Refresh local state
      await fetchProfile();
      
      // Invalidate management lists if needed
      _ref.invalidate(tutorManagementProvider);
    } catch (e) {
      rethrow;
    }
  }
}

final tutorProfileProvider = 
    StateNotifierProvider<TutorProfileNotifier, AsyncValue<TutorModel?>>((ref) {
  final user = ref.watch(currentUserProvider);
  return TutorProfileNotifier(ref.watch(supabaseProvider), user?.id, ref);
});
