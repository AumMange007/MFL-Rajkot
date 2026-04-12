import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../widgets/common_widgets.dart';
import '../providers/student_profile_provider.dart';
import '../../admin/providers/announcement_provider.dart';
import '../../common/providers/attendance_summary_provider.dart';

class StudentDashboard extends ConsumerWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user  = ref.watch(currentUserProvider);
    final profileState = ref.watch(studentProfileProvider);
    final attendanceStats = ref.watch(attendanceSummaryProvider);
    final announcementsState = ref.watch(announcementProvider);
    final todayStatus = ref.watch(todayAttendanceProvider);
    final theme = Theme.of(context);

    // Calculate unread announcements highlight (simple check for list non-empty)
    final hasAnnouncements = announcementsState.maybeWhen(
      data: (list) => list.isNotEmpty,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => context.push('/student/profile'),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty 
                    ? CachedNetworkImageProvider(user.avatarUrl!) 
                    : null,
                child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                    ? Text(user?.name?[0].toUpperCase() ?? "S", style: TextStyle(fontSize: 12, color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold))
                    : null,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Greeting Card ───────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF059669), Color(0xFF0D9488)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hello, ${user?.name?.split(' ').first ?? "Student"} 👋',
                              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('Stay updated with your institute.',
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.75))),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: () => context.push('/student/profile'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.edit_note_rounded, size: 14, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text('Edit Profile', style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/student/profile'),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                              ? CachedNetworkImageProvider(user.avatarUrl!) : null,
                          child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                              ? Text(user?.name?[0].toUpperCase() ?? "S",
                                  style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold))
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Today's Attendance Status (Requested Feature) ────────
              todayStatus.when(
                data: (status) => _buildTodayStatusCard(theme, status),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 28),

              // ── Batch & Tutor Info Card (Requested Feature) ──────────
              profileState.when(
                data: (student) => _buildAssignmentCard(theme, student),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 28),

              // ── Attendance summary ────────────────────────────────────
              const SectionHeader(title: 'My Attendance'),
              const SizedBox(height: 12),
              attendanceStats.when(
                data: (stats) => _buildAttendanceCard(theme, stats),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 28),

              // ── Navigation Sections ───────────────────────────────────
              const SectionHeader(title: 'My Sections'),
              const SizedBox(height: 12),
                            _StudentActionTile(icon: Icons.auto_stories_rounded, title: 'Library',
                  subtitle: 'E-Content & Study materials', color: const Color(0xFF7C3AED),
                  onTap: () => context.push('/student/library')),
              _StudentActionTile(icon: Icons.campaign_rounded, title: 'Announcements',
                  subtitle: 'Notice board from your institute', color: const Color(0xFF0891B2),
                  hasHighlight: hasAnnouncements,
                  onTap: () => context.push('/student/announcements')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayStatusCard(ThemeData theme, String? status) {
    status = status?.toLowerCase();
    final isMarked = status != null;
    
    final (label, color, icon) = switch (status) {
      'present' => ('Marked Present', Colors.green, Icons.check_circle_rounded),
      'absent' => ('Marked Absent', Colors.red, Icons.cancel_rounded),
      'late' => ('Marked Late', Colors.orange, Icons.access_time_filled_rounded),
      _ => ('Today\'s Attendance: Not Marked', Colors.grey, Icons.help_outline_rounded),
    };

    final HSLColor hsl = HSLColor.fromColor(color);
    final darkColor = hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMarked ? color.withOpacity(0.08) : theme.colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isMarked ? color.withOpacity(0.2) : theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMarked ? 'Status Recognized' : 'Awaiting Input',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: isMarked ? darkColor : null),
                ),
              ],
            ),
          ),
          if (isMarked)
            Icon(Icons.verified_user_rounded, color: color.withOpacity(0.5), size: 18),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(ThemeData theme, dynamic student) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.primaryContainer),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assigned Batch', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(student?.batchName ?? 'Loading...', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const VerticalDivider(thickness: 1, width: 32),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Tutor', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(student?.tutorName ?? 'Assigned soon', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(ThemeData theme, Map<String, int> stats) {
    final present = stats['present'] ?? 0;
    final total = stats['total'] ?? 0;
    final absent = stats['absent'] ?? 0;
    final lateCount = stats['late'] ?? 0;
    final double percent = (total > 0 ? present / total : 0.0).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircularPercentIndicator(
              radius: 50,
              lineWidth: 8,
              percent: percent,
              center: Text('${(percent * 100).toInt()}%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              progressColor: percent > 0.75 ? const Color(0xFF059669) : theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
              circularStrokeCap: CircularStrokeCap.round,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Overall attendance', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  _AttendanceRow(label: 'Present', value: '$present', color: const Color(0xFF059669)),
                  _AttendanceRow(label: 'Late', value: '$lateCount', color: const Color(0xFFD97706)),
                  _AttendanceRow(label: 'Absent', value: '$absent', color: const Color(0xFFDC2626)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool hasHighlight;

  const _StudentActionTile({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap, this.hasHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    if (hasHighlight)
                      Positioned(right: 0, top: 0,
                        child: Container(height: 10, width: 10,
                          decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5)))),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _AttendanceRow({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
