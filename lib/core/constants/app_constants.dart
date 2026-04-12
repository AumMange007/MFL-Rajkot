class AppConstants {
  // ── Supabase ──────────────────────────────────────────────────────────────
  // Replace these with your actual Supabase project URL and anon key
  static const supabaseUrl = 'https://qjtzkxmxukloqkfrarbq.supabase.co';
  static const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFqdHpreG14dWtsb3FrZnJhcmJxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUxMzA1MjcsImV4cCI6MjA5MDcwNjUyN30.0y4U27umj5yDgVpBvmvc4vX1IQn0Y1bAmajWBvE-nVs';

  // ── Table names ───────────────────────────────────────────────────────────
  static const institutesTable    = 'institutes';
  static const usersTable         = 'users';
  static const batchesTable       = 'batches';
  static const studentsTable      = 'students';
  static const tutorsTable        = 'tutors';
  static const attendanceTable    = 'attendance';
  static const contentLibTable    = 'content_library';
  static const batchContentTable  = 'batch_content';
  static const announcementsTable = 'announcements';
  static const tutorAttendanceTable = 'tutor_attendance';
  static const staffAttendanceTable = 'staff_attendance';

  // ── Storage ───────────────────────────────────────────────────────────────
  static const contentBucket  = 'content';
  static const profilesBucket = 'profiles';

  // ── Roles ─────────────────────────────────────────────────────────────────
  static const roleAdmin   = 'admin';
  static const roleTutor   = 'tutor';
  static const roleStudent = 'student';
}
