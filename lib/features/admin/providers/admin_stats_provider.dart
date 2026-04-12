import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';

class AdminStats {
  final int totalStudents;
  final int totalTutors;
  final int totalBatches;
  final int totalContent;

  AdminStats({
    required this.totalStudents,
    required this.totalTutors,
    required this.totalBatches,
    required this.totalContent,
  });
}

final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return AdminStats(totalStudents: 0, totalTutors: 0, totalBatches: 0, totalContent: 0);
  }

  try {
    // We use .select('id') without FetchOptions.
    // In Supabase Flutter 2.x, this returns a List directly.
    final studentRes = await supabase
        .from(AppConstants.studentsTable)
        .select('id')
        .eq('institute_id', user.instituteId);
    
    final tutorRes = await supabase
        .from(AppConstants.usersTable)
        .select('id')
        .eq('institute_id', user.instituteId)
        .eq('role', AppConstants.roleTutor);

    final batchRes = await supabase
        .from(AppConstants.batchesTable)
        .select('id')
        .eq('institute_id', user.instituteId);

    final contentRes = await supabase
        .from(AppConstants.contentLibTable)
        .select('id')
        .eq('institute_id', user.instituteId);

    // Explicitly cast to List so we can get .length
    final List students = (studentRes ?? []) as List;
    final List tutors = (tutorRes ?? []) as List;
    final List batches = (batchRes ?? []) as List;
    final List content = (contentRes ?? []) as List;

    return AdminStats(
      totalStudents: students.length,
      totalTutors: tutors.length,
      totalBatches: batches.length,
      totalContent: content.length,
    );
  } catch (e) {
    // Log error in console for debugging
    print('DEBUG: adminStatsProvider failed: $e');
    return AdminStats(totalStudents: 0, totalTutors: 0, totalBatches: 0, totalContent: 0);
  }
});
