import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/tutor_dashboard_provider.dart';
import '../providers/tutor_attendance_provider.dart';
import '../../../widgets/common_widgets.dart';
import '../../admin/providers/announcement_provider.dart';
import '../../common/providers/profile_photo_provider.dart';
import '../../common/providers/attendance_summary_provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:coaching_app/models/tutor_attendance_model.dart';

class TutorDashboard extends ConsumerWidget {
  const TutorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user  = ref.watch(currentUserProvider);
    final tutorState = ref.watch(tutorDashboardProvider);
    final attendanceState = ref.watch(tutorAttendanceProvider);
    final staffAttendanceStats = ref.watch(attendanceSummaryProvider);
    final announcementsState = ref.watch(announcementProvider);
    final theme = Theme.of(context);

    // Simple highlight check: If there are any announcements
    final hasAnnouncements = announcementsState.maybeWhen(
      data: (list) => ref.read(announcementProvider.notifier).hasUnread(list),
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutor Dashboard'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty 
                  ? CachedNetworkImageProvider(user.avatarUrl!) 
                  : null,
              child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                  ? Text(user?.name?[0].toUpperCase() ?? "T", style: TextStyle(fontSize: 12, color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold))
                  : null,
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
          padding: const EdgeInsets.all(20),
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
                    colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hello, ${user?.name?.split(' ').first ?? "Tutor"} 👋',
                              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('Manage your batches and students.',
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.75))),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text('Tutor Portal', style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref.read(profilePhotoProvider.notifier).pickAndUploadImage(),
                      child: Stack(
                        children: [
                          Container(
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
                                  ? Text(user?.name?[0].toUpperCase() ?? "T",
                                      style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold))
                                  : null,
                            ),
                          ),
                          Positioned(bottom: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF0EA5E9), width: 1.5)),
                              child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0EA5E9), size: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
 
              // ── Punch In / Out Card ──────────────────────────────────
              _buildPunchCard(context, ref, attendanceState, theme),
              const SectionHeader(title: 'My Overview'),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  StatCard(
                    label: 'My Students',
                    value: tutorState.maybeWhen(data: (s) => s.totalStudents.toString(), orElse: () => '—'),
                    icon: Icons.people_rounded,
                    color: const Color(0xFF2563EB),
                  ),
                  StatCard(
                    label: 'My Batches',
                    value: tutorState.maybeWhen(data: (s) => s.totalBatches.toString(), orElse: () => '—'),
                    icon: Icons.layers_rounded,
                    color: const Color(0xFF0891B2),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ── Assigned Batches Section ────────────────────────────────────
              const SectionHeader(title: 'My Assigned Batches'),
              const SizedBox(height: 12),
              tutorState.when(
                data: (stats) {
                  if (stats.batches.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.withOpacity(0.1))),
                      child: const Text('You are not assigned to any batches yet.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    );
                  }
                  return SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: stats.batches.length,
                      itemBuilder: (context, index) {
                        final b = stats.batches[index];
                        return Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(b.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: const Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text('${b.tutorIds.length} Tutors', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 32),

              // ── Staff attendance summary ────────────────────────────────────
              const SectionHeader(title: 'My Presence'),
              const SizedBox(height: 12),
              staffAttendanceStats.when(
                data: (stats) => _buildAttendanceCard(context, theme, stats),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 32),
 
              // ── Quick actions ─────────────────────────────────────────
              const SectionHeader(title: 'Quick Actions'),
              const SizedBox(height: 12),

                            _ActionCard(icon: Icons.campaign_rounded, title: 'Announcements',
                  subtitle: 'Notice board from institute', color: const Color(0xFFE11D48),
                  hasHighlight: hasAnnouncements,
                  onTap: () { ref.read(announcementProvider.notifier).markAsSeen(); context.push('/tutor/announcements'); }),
              _ActionCard(icon: Icons.layers_rounded, title: 'My Batches',
                  subtitle: 'View all your assigned batches', color: const Color(0xFF0891B2),
                  onTap: () => context.push('/tutor/batches')),
              _ActionCard(icon: Icons.fact_check_rounded, title: 'Mark Attendance',
                  subtitle: 'Record today\'s attendance', color: const Color(0xFF059669),
                  onTap: () => context.push('/tutor/mark-attendance')),
              _ActionCard(icon: Icons.upload_file_rounded, title: 'E-Content Library',
                  subtitle: 'Manage PDFs and study material', color: const Color(0xFF7C3AED),
                  onTap: () => context.push('/tutor/content')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPunchCard(BuildContext context, WidgetRef ref, AsyncValue<StaffAttendanceModel?> state, ThemeData theme) {
    return state.when(
      data: (attendance) {
        final isPunchedIn = attendance != null;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPunchedIn 
                ? [Colors.orange.shade400, Colors.red.shade600] 
                : [theme.colorScheme.primary, Colors.blue.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (isPunchedIn ? Colors.red : theme.colorScheme.primary).withOpacity(0.3),
                blurRadius: 15, offset: const Offset(0, 8)
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: Icon(isPunchedIn ? Icons.timer_rounded : Icons.timer_off_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isPunchedIn ? 'On Duty' : 'Ready to Start?', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                      Text(isPunchedIn ? 'Punch in at ${_formatTime(attendance.punchInAt)}' : 'Punch in to start your session', 
                          style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8))),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _handlePunch(context, ref, isPunchedIn),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: isPunchedIn ? Colors.red : theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text(isPunchedIn ? 'Punch Out' : 'Punch In', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }

  String _formatTime(DateTime dt) => '${dt.hour}:${dt.minute.toString().padLeft(2, "0")}';

  void _handlePunch(BuildContext context, WidgetRef ref, bool isPunchedIn) async {
    final notifier = ref.read(tutorAttendanceProvider.notifier);
    try {
      if (isPunchedIn) {
        await notifier.punchOut();
      } else {
        await notifier.punchIn();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildAttendanceCard(BuildContext context, ThemeData theme, Map<String, int> stats) {
    final present = stats['present'] ?? 0;
    final total = stats['total'] ?? 0;
    final absent = stats['absent'] ?? 0;
    final lateCount = stats['late'] ?? 0;
    final percent = total > 0 ? present / total : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircularPercentIndicator(
              radius: 40,
              lineWidth: 6,
              percent: percent,
              center: Text('${(percent * 100).toInt()}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              progressColor: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
              circularStrokeCap: CircularStrokeCap.round,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _MiniAttendanceRow(label: 'Present', value: '$present days', color: const Color(0xFF059669)),
                   _MiniAttendanceRow(label: 'Late', value: '$lateCount days', color: const Color(0xFFD97706)),
                   _MiniAttendanceRow(label: 'Absent', value: '$absent days', color: const Color(0xFFDC2626)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniAttendanceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _MiniAttendanceRow({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool hasHighlight;

  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap, this.hasHighlight = false});

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
