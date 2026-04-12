import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/force_reset_password_screen.dart';
import '../features/auth/screens/force_profile_fill_screen.dart';
import '../features/admin/screens/admin_dashboard.dart';
import '../features/admin/screens/manage_students_screen.dart';
import '../features/admin/screens/manage_staff_screen.dart';
import '../features/admin/screens/manage_batches_screen.dart';
import '../features/admin/screens/manage_announcements_screen.dart';
import '../features/admin/screens/attendance_reports_screen.dart';

import '../features/tutor/screens/tutor_dashboard.dart';
import '../features/tutor/screens/tutor_profile_screen.dart';
import '../features/staff/screens/staff_dashboard.dart';
import '../features/admin/screens/tutor_attendance_report_screen.dart';
import '../features/common/screens/mark_attendance_screen.dart';
import '../features/student/screens/student_dashboard.dart';
import '../features/student/screens/student_profile_screen.dart';
import '../features/library/screens/library_screen.dart';
import '../features/admin/screens/content_library_screen.dart' as adminLib;
import '../features/admin/screens/manage_tutors_screen.dart';
import '../features/auth/providers/auth_provider.dart';

class AppRoutes {
  static const splash  = '/splash';
  static const login   = '/login';
  static const forceReset = '/force-reset';
  static const forceProfile = '/force-profile';
  static const admin   = '/admin';
  static const tutor   = '/tutor';
  static const staff   = '/staff';
  static const student = '/student';
  
  // Shared / Feature paths
  static const profile        = 'profile';
  static const manageStudents = 'students';
  static const manageStaff   = 'staff';
  static const manageBatches  = 'batches';
  static const announcements  = 'announcements';
  static const attendance     = 'reports';
  static const markAttendance = 'mark-attendance';
  static const tutorAttendance = 'tutor-reports';
  static const contentLib     = 'content';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final user      = authState.valueOrNull;
      final loc       = state.matchedLocation;

      if (isLoading) return AppRoutes.splash;
      if (user == null) {
        return (loc == AppRoutes.login) ? null : AppRoutes.login;
      }

      if (user.role != 'admin' && user.needsPasswordReset && loc != AppRoutes.forceReset) {
        return AppRoutes.forceReset;
      }
      
      if (user.role != 'admin' && !user.needsPasswordReset && !user.isProfileComplete && loc != AppRoutes.forceProfile) {
        return AppRoutes.forceProfile;
      }

      if (loc == AppRoutes.splash || loc == AppRoutes.login || loc == AppRoutes.forceReset || loc == AppRoutes.forceProfile) {
        if (loc == AppRoutes.forceReset && (user.needsPasswordReset && user.role != 'admin')) return null;
        if (loc == AppRoutes.forceProfile && (!user.isProfileComplete && user.role != 'admin')) return null;

        return switch (user.role) {
          'admin'   => AppRoutes.admin,
          'tutor'   => AppRoutes.tutor,
          'staff'   => AppRoutes.staff,
          'student' => AppRoutes.student,
          _         => AppRoutes.login,
        };
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.forceReset, builder: (_, __) => const ForceResetPasswordScreen()),
      GoRoute(path: AppRoutes.forceProfile, builder: (_, __) => const ForceProfileFillScreen()),
      
      // Admin shell
      GoRoute(
        path: AppRoutes.admin,
        builder: (_, __) => const AdminDashboard(),
        routes: [
          GoRoute(path: AppRoutes.manageStudents, builder: (_, __) => const ManageStudentsScreen()),
          GoRoute(path: AppRoutes.manageStaff, builder: (_, __) => const ManageStaffScreen()),
          GoRoute(path: AppRoutes.manageBatches, builder: (_, __) => const ManageBatchesScreen()),
          GoRoute(path: AppRoutes.announcements, builder: (_, __) => const ManageAnnouncementsScreen()),
          GoRoute(path: AppRoutes.attendance, builder: (_, __) => const AttendanceReportsScreen()),
          GoRoute(path: AppRoutes.markAttendance, builder: (_, __) => const MarkAttendanceScreen()),
          GoRoute(path: AppRoutes.tutorAttendance, builder: (_, __) => const TutorAttendanceReportScreen()),
          GoRoute(path: AppRoutes.contentLib, builder: (_, __) => const adminLib.ContentLibraryScreen()),
        ],
      ),

      // Tutor shell
      GoRoute(
        path: AppRoutes.tutor,
        builder: (_, __) => const TutorDashboard(),
        routes: [
          GoRoute(path: AppRoutes.profile, builder: (_, __) => const TutorProfileScreen()),
          GoRoute(path: AppRoutes.markAttendance, builder: (_, __) => const MarkAttendanceScreen()),
          GoRoute(path: AppRoutes.manageBatches, builder: (_, __) => const ManageBatchesScreen()),
          GoRoute(path: AppRoutes.contentLib, builder: (_, __) => const adminLib.ContentLibraryScreen()),
          GoRoute(path: AppRoutes.announcements, builder: (_, __) => const ManageAnnouncementsScreen()),
          GoRoute(path: AppRoutes.manageStudents, builder: (_, __) => const ManageStudentsScreen()),
        ],
      ),

      // Student shell
      GoRoute(
        path: AppRoutes.student,
        builder: (_, __) => const StudentDashboard(),
        routes: [
          GoRoute(path: AppRoutes.profile, builder: (_, __) => const StudentProfileScreen()),
          GoRoute(path: AppRoutes.announcements, builder: (_, __) => const ManageAnnouncementsScreen()),
          GoRoute(path: AppRoutes.contentLib, builder: (_, __) => const adminLib.ContentLibraryScreen()),
        ],
      ),

      // Staff shell
      GoRoute(
        path: AppRoutes.staff,
        builder: (_, __) => const StaffDashboard(),
        routes: [
          GoRoute(path: AppRoutes.announcements, builder: (_, __) => const ManageAnnouncementsScreen()),
          GoRoute(path: AppRoutes.manageStudents, builder: (_, __) => const ManageStudentsScreen()),
          GoRoute(path: AppRoutes.contentLib, builder: (_, __) => const adminLib.ContentLibraryScreen()),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(body: Center(child: Text('Coming Soon: ${state.matchedLocation}'))),
  );
});
