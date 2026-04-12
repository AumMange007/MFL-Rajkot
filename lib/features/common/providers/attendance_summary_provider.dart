import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';

final attendanceSummaryProvider = FutureProvider<Map<String, int>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};

  try {
    final isStudent = user.role == 'student';
    final table = isStudent ? AppConstants.attendanceTable : AppConstants.staffAttendanceTable;
    final idField = isStudent ? 'student_id' : 'user_id';

    String targetId = user.id;
    if (isStudent) {
      final studentRes = await supabase.from('students').select('id').eq('user_id', user.id).maybeSingle();
      if (studentRes == null) return {};
      targetId = studentRes['id'];
    }

    final res = await supabase.from(table).select('status').eq(idField, targetId);
    
    final stats = {'present': 0, 'absent': 0, 'late': 0, 'total': 0};
    if (res != null) {
      for (var row in (res as List)) {
        final status = row['status']?.toString().toLowerCase();
        if (status != null && stats.containsKey(status)) {
          stats[status] = stats[status]! + 1;
        }
        stats['total'] = stats['total']! + 1;
      }
    }
    return stats;
  } catch (e) {
    print('Attendance summary error: $e');
    return {'present': 0, 'absent': 0, 'late': 0, 'total': 0};
  }
});

final todayAttendanceProvider = FutureProvider<String?>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  try {
    final isStudent = user.role == 'student';
    final table = isStudent ? AppConstants.attendanceTable : AppConstants.staffAttendanceTable;
    final idField = isStudent ? 'student_id' : 'user_id';
    final dateStr = DateTime.now().toIso8601String().split('T').first;

    String targetId = user.id;
    if (isStudent) {
      final studentRes = await supabase.from('students').select('id').eq('user_id', user.id).maybeSingle();
      if (studentRes == null) return null;
      targetId = studentRes['id'];
    }

    final res = await supabase
        .from(table)
        .select('status')
        .eq(idField, targetId)
        .eq('date', dateStr)
        .maybeSingle();
    
    return res?['status']?.toString();
  } catch (e) {
    print('Today attendance error: $e');
    return null;
  }
});

final weeklyAttendanceProvider = FutureProvider.family<Map<String, int>, String>((ref, studentId) async {
  final supabase = ref.watch(supabaseProvider);
  try {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String().split('T').first;
    
    final res = await supabase
        .from(AppConstants.attendanceTable)
        .select('status')
        .eq('student_id', studentId)
        .gte('date', sevenDaysAgo);

    final stats = {'present': 0, 'absent': 0, 'late': 0, 'total': 0};
    for (var row in (res as List)) {
      final status = row['status']?.toString().toLowerCase();
      if (status != null && stats.containsKey(status)) {
        stats[status] = stats[status]! + 1;
      }
      stats['total'] = stats['total']! + 1;
    }
    return stats;
  } catch (e) {
    return {'present': 0, 'absent': 0, 'late': 0, 'total': 0};
  }
});

final weeklyStaffAttendanceProvider = FutureProvider.family<Map<String, int>, String>((ref, userId) async {
  final supabase = ref.watch(supabaseProvider);
  try {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String().split('T').first;
    
    final res = await supabase
        .from(AppConstants.staffAttendanceTable)
        .select('status')
        .eq('user_id', userId)
        .gte('date', sevenDaysAgo);

    final stats = {'present': 0, 'absent': 0, 'late': 0, 'total': 0};
    for (var row in (res as List)) {
      final status = row['status']?.toString().toLowerCase();
      if (status != null && stats.containsKey(status)) {
        stats[status] = stats[status]! + 1;
      }
      stats['total'] = stats['total']! + 1;
    }
    return stats;
  } catch (e) {
    return {'present': 0, 'absent': 0, 'late': 0, 'total': 0};
  }
});

final weeklyTutorAttendanceProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, tutorId) async {
  final supabase = ref.watch(supabaseProvider);
  try {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String().split('T').first;
    
    final res = await supabase
        .from('tutor_attendance')
        .select('duration_minutes')
        .eq('tutor_id', tutorId)
        .gte('date', sevenDaysAgo);

    int daysWorked = 0;
    int totalMinutes = 0;
    for (var row in (res as List)) {
      daysWorked++;
      totalMinutes += (row['duration_minutes'] as int?) ?? 0;
    }
    return {
      'days_worked': daysWorked,
      'total_hours': (totalMinutes / 60).toStringAsFixed(1),
    };
  } catch (e) {
    return {'days_worked': 0, 'total_hours': "0.0"};
  }
});
