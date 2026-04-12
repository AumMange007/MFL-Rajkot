import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../models/batch_model.dart';
import '../../../core/constants/app_constants.dart';

class TutorStats {
  final int totalBatches;
  final int totalStudents;
  final List<BatchModel> batches;

  TutorStats({
    required this.totalBatches,
    required this.totalStudents,
    required this.batches,
  });
}

final tutorDashboardProvider = FutureProvider<TutorStats>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) {
     return TutorStats(totalBatches: 0, totalStudents: 0, batches: []);
  }

  try {
    // 1. Fetch batches assigned to this tutor via the junction table
    final batchResponse = await supabase
        .from('batch_tutors')
        .select('batch_id, batches(*, batch_tutors(tutor_id, users:tutor_id(name)))')
        .eq('tutor_id', user.id);
    
    // Map the nested batch records to BatchModel
    final batches = (batchResponse as List)
        .where((e) => e['batches'] != null)
        .map((e) => BatchModel.fromJson(e['batches']))
        .toList();

    if (batches.isEmpty) {
      return TutorStats(totalBatches: 0, totalStudents: 0, batches: []);
    }

    // 2. Fetch total students in these batches
    final batchIds = batches.map((b) => b.id).toList();
    final studentRes = await supabase
        .from(AppConstants.studentsTable)
        .select('id')
        .inFilter('batch_id', batchIds);

    return TutorStats(
      totalBatches: batches.length,
      totalStudents: (studentRes as List).length,
      batches: batches,
    );
  } catch (e) {
    print('DEBUG: tutorDashboardProvider failed: $e');
    return TutorStats(totalBatches: 0, totalStudents: 0, batches: []);
  }
});
