import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/attendance_model.dart';
import '../../../models/student_model.dart';
import '../../auth/providers/auth_provider.dart';
import 'attendance_summary_provider.dart';

class AttendanceMarkingNotifier extends StateNotifier<AsyncValue<List<StudentModel>>> {
  final SupabaseClient _supabase;
  final Ref _ref;

  AttendanceMarkingNotifier(this._supabase, this._ref) : super(const AsyncValue.loading());

  Future<void> fetchBatchStudents(String batchId) async {
    state = const AsyncValue.loading();
    try {
      final res = await _supabase
          .from(AppConstants.studentsTable)
          .select('*, users(*)')
          .eq('batch_id', batchId);
      
      final students = (res as List).map((e) => StudentModel.fromJson(e)).toList();
      state = AsyncValue.data(students);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Map<String, String>> getExistingAttendance({
    required String? batchId,
    required DateTime date,
    required bool isStaff,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T').first;
      final table = isStaff ? AppConstants.staffAttendanceTable : AppConstants.attendanceTable;
      final idField = isStaff ? 'user_id' : 'student_id';

      var query = _supabase.from(table).select().eq('date', dateStr);
      if (!isStaff && batchId != null) {
        query = query.eq('batch_id', batchId);
      }

      final res = await query;
      final Map<String, String> map = {};
      for (var row in (res as List)) {
        map[row[idField].toString()] = row['status'].toString();
      }
      return map;
    } catch (e) {
      print('Error fetching existing attendance: $e');
      return {};
    }
  }

  Future<void> fetchStaff() async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) return;
      
      final res = await _supabase
          .from('users')
          .select()
          .eq('institute_id', user.instituteId)
          .inFilter('role', ['admin', 'tutor']);
      
      final staff = (res as List).map((e) => StudentModel(
        id: e['id'], // Reusing StudentModel just for UI mapping (userId = id here)
        userId: e['id'],
        batchId: '',
        instituteId: e['institute_id'],
        studentName: e['name'],
        studentEmail: e['email'],
        studentAvatarUrl: e['avatar_url'],
      )).toList();
      state = AsyncValue.data(staff);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markStaffAttendance({
    required DateTime date,
    required Map<String, String> statusMap, // userId -> status
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final dateStr = date.toIso8601String().split('T').first;
      
      final attendanceList = statusMap.entries.map((entry) => {
        'user_id': entry.key,
        'date': dateStr,
        'status': entry.value,
        'institute_id': user.instituteId,
        'marked_by': user.id,
      }).toList();

      await _supabase.from(AppConstants.staffAttendanceTable).upsert(
        attendanceList,
        onConflict: 'user_id, date',
      );

      // Invalidate providers to refresh UI
      _ref.invalidate(attendanceSummaryProvider);
      _ref.invalidate(todayAttendanceProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAttendance({
    required String batchId,
    required DateTime date,
    required Map<String, String> statusMap, // studentId -> status
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final dateStr = date.toIso8601String().split('T').first;
      
      final attendanceList = statusMap.entries.map((entry) => {
        'student_id': entry.key,
        'batch_id': batchId,
        'date': dateStr,
        'status': entry.value,
        'institute_id': user.instituteId,
        'marked_by': user.id,
      }).toList();

      await _supabase.from(AppConstants.attendanceTable).upsert(
        attendanceList,
        onConflict: 'student_id, batch_id, date',
      );

      // Invalidate providers to refresh UI
      _ref.invalidate(attendanceSummaryProvider);
      _ref.invalidate(todayAttendanceProvider);
    } catch (e) {
      rethrow;
    }
  }
}

final attendanceMarkingProvider = 
    StateNotifierProvider<AttendanceMarkingNotifier, AsyncValue<List<StudentModel>>>((ref) {
  return AttendanceMarkingNotifier(ref.watch(supabaseProvider), ref);
});
