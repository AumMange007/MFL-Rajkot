import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';

class StaffAttendanceReport {
  final String personName;
  final String date;
  final DateTime punchIn;
  final DateTime? punchOut;
  final int? durationMinutes;
  final String role;
  final String avatarUrl;

  StaffAttendanceReport({
    required this.personName,
    required this.date,
    required this.punchIn,
    required this.role,
    this.avatarUrl = '',
    this.punchOut,
    this.durationMinutes,
  });

  factory StaffAttendanceReport.fromJson(Map<String, dynamic> json) {
    // Robust parsing for nested user data
    final userData = json['users'] as Map<String, dynamic>?;
    
    return StaffAttendanceReport(
      personName:       userData?['name']?.toString() ?? 'Unknown User',
      date:            json['date']?.toString() ?? '',
      role:            userData?['role']?.toString() ?? 'staff',
      avatarUrl:       userData?['avatar_url']?.toString() ?? '',
      punchIn:         DateTime.parse(json['punch_in_at'] as String),
      punchOut:        json['punch_out_at'] != null ? DateTime.parse(json['punch_out_at'] as String) : null,
      durationMinutes: json['punch_out_at'] != null 
          ? DateTime.parse(json['punch_out_at'] as String).difference(DateTime.parse(json['punch_in_at'] as String)).inMinutes 
          : null,
    );
  }
}

final staffAttendanceReportProvider = FutureProvider<List<StaffAttendanceReport>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  try {
    // Using a more flexible select without explicit fkey name to avoid 'fkey not found' errors
    // Supabase will automatically use the fkey between user_id and users.id
    final res = await supabase
        .from(AppConstants.staffAttendanceTable)
        .select('*, users!user_id(name, role, avatar_url)')
        .eq('institute_id', user.instituteId)
        .order('punch_in_at', ascending: false);
    
    return (res as List).map((e) => StaffAttendanceReport.fromJson(e)).toList();
  } catch (e) {
    print('Staff Attendance Report Fetch Error: $e');
    // Return empty list instead of mock data so user knows if DB is actually empty
    return [];
  }
});

final staffReportSearchProvider = StateProvider<String>((ref) => '');
final staffReportRoleFilterProvider = StateProvider<String>((ref) => 'all');
