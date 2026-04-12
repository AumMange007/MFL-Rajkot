import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';

class TutorAttendanceReport {
  final String tutorName;
  final String date;
  final DateTime punchIn;
  final DateTime? punchOut;
  final int? durationMinutes;

  TutorAttendanceReport({
    required this.tutorName,
    required this.date,
    required this.punchIn,
    this.punchOut,
    this.durationMinutes,
  });

  factory TutorAttendanceReport.fromJson(Map<String, dynamic> json) => TutorAttendanceReport(
    tutorName:       json['users']['name'] as String,
    date:            json['date'] as String,
    punchIn:         DateTime.parse(json['punch_in'] as String),
    punchOut:        json['punch_out'] != null ? DateTime.parse(json['punch_out'] as String) : null,
    durationMinutes: json['duration_minutes'] as int?,
  );
}

final tutorAttendanceReportProvider = FutureProvider<List<TutorAttendanceReport>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final res = await supabase
      .from(AppConstants.tutorAttendanceTable)
      .select('*, users(name)')
      .eq('institute_id', user.instituteId)
      .order('punch_in', ascending: false);
  
  return (res as List).map((e) => TutorAttendanceReport.fromJson(e)).toList();
});
