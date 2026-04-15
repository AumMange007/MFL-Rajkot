import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';

final attendanceSummaryProvider = FutureProvider<Map<String, int>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};

  try {
    final isStudent = user.role == 'student';
    final stats = {'present': 0, 'absent': 0, 'late': 0, 'total': 0};

    if (isStudent) {
      // 1. Find all student record IDs for this user (they might have multiple if they moved batches)
      final studentIdsRes = await supabase.from('students').select('id').eq('user_id', user.id);
      final studentIds = (studentIdsRes as List?)?.map((e) => e['id'].toString()).toList() ?? [];

      if (studentIds.isEmpty) return stats;

      // 2. Query attendance for all these IDs
      final res = await supabase
          .from(AppConstants.attendanceTable)
          .select('date, status')
          .inFilter('student_id', studentIds);
      
      final uniqueResults = <String, String>{};
      for (var row in (res as List)) {
        final date = row['date']?.toString();
        final status = row['status']?.toString().toLowerCase();
        if (date != null && status != null) {
          uniqueResults[date] = status;
        }
      }

      for (var status in uniqueResults.values) {
        if (stats.containsKey(status)) stats[status] = stats[status]! + 1;
        stats['total'] = stats['total']! + 1;
      }
    } else {
      // Staff attendance
      final res = await supabase.from(AppConstants.staffAttendanceTable).select('date, status').eq('user_id', user.id);
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
    final dateStr = DateTime.now().toIso8601String().split('T').first;

    if (isStudent) {
      final studentIdsRes = await supabase.from('students').select('id').eq('user_id', user.id);
      final studentIds = (studentIdsRes as List?)?.map((e) => e['id'].toString()).toList() ?? [];
      if (studentIds.isEmpty) return null;

      final resList = await supabase
          .from(AppConstants.attendanceTable)
          .select('status, created_at')
          .inFilter('student_id', studentIds)
          .eq('date', dateStr)
          .order('created_at', ascending: false)
          .limit(1);
      
      final res = (resList as List?)?.isNotEmpty == true ? (resList as List).first : null;
      return res?['status']?.toString();
    } else {
      final resList = await supabase
          .from(AppConstants.staffAttendanceTable)
          .select('status, created_at')
          .eq('user_id', user.id)
          .eq('date', dateStr)
          .order('created_at', ascending: false)
          .limit(1);
      
      final res = (resList as List?)?.isNotEmpty == true ? (resList as List).first : null;
      return res?['status']?.toString();
    }
  } catch (e) {
    print('Today attendance error: $e');
    return null;
  }
});

final weeklyAttendanceProvider = FutureProvider.family<Map<String, int>, String>((ref, studentId) async {
  final supabase = ref.watch(supabaseProvider);
  try {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String().split('T').first;
    
    // Fetch unique attendance for the STUDENT'S USER across all batches
    // We join with students to find other entries for the same user
    final studentRes = await supabase.from('students').select('user_id').eq('id', studentId).maybeSingle();
    final userId = studentRes?['user_id'];

    if (userId == null) return {'present': 0, 'absent': 0, 'late': 0, 'total': 0};

    // Fetch all student entries for this user to combine their history
    final idsRes = await supabase.from('students').select('id').eq('user_id', userId);
    final ids = (idsRes as List?)?.map((e) => e['id'].toString()).toList() ?? [];

    if (ids.isEmpty) return {'present': 0, 'absent': 0, 'late': 0, 'total': 0};

    final res = await supabase
        .from(AppConstants.attendanceTable)
        .select('date, status')
        .inFilter('student_id', ids)
        .gte('date', sevenDaysAgo);

    final stats = {'present': 0, 'absent': 0, 'late': 0, 'total': 0};
    
    // Use a date map to avoid double-counting if duplicates exist from previous batch moves
    final dateStatusMap = <String, String>{};
    for (var row in (res as List)) {
      final date = row['date']?.toString();
      final status = row['status']?.toString().toLowerCase();
      if (date != null && status != null) {
        dateStatusMap[date] = status;
      }
    }

    for (var status in dateStatusMap.values) {
      if (stats.containsKey(status)) {
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
