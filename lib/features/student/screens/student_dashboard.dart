import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../widgets/common_widgets.dart';
import '../providers/student_profile_provider.dart';
import '../../admin/providers/announcement_provider.dart';
import '../../common/providers/attendance_summary_provider.dart';
import '../../common/screens/conversations_list_screen.dart';

class StudentDashboard extends ConsumerWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileState = ref.watch(studentProfileProvider);
    final attendanceStats = ref.watch(attendanceSummaryProvider);
    final announcementsState = ref.watch(announcementProvider);
    final todayStatus = ref.watch(todayAttendanceProvider);

    final hasAnnouncements = announcementsState.maybeWhen(
      data: (list) => list.isNotEmpty,
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentProfileProvider);
          ref.invalidate(attendanceSummaryProvider);
          ref.invalidate(todayAttendanceProvider);
          ref.invalidate(announcementProvider);
          // Wait for the key future to complete before dismissing spinner
          try { await ref.read(todayAttendanceProvider.future); } catch (_) {}
        },
        child: CustomScrollView(
          slivers: [
          // ── Sliver App Bar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0891B2),
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.forum_outlined, color: Colors.white),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConversationsListScreen())),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () => ProfilePhotoActions.showOptions(
                    context: context,
                    ref: ref,
                    currentImageUrl: user?.avatarUrl,
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    backgroundImage: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                        ? CachedNetworkImageProvider(user.avatarUrl!) : null,
                    child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty)
                        ? Text(user?.name[0].toUpperCase() ?? 'S', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))
                        : null,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0369A1), Color(0xFF0891B2)],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 90, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Hello,', style: GoogleFonts.inter(fontSize: 14, color: Colors.white60)),
                    Text(user?.name.split(' ').first ?? 'Student', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => context.push('/student/profile'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit_note_rounded, size: 13, color: Colors.white),
                            const SizedBox(width: 5),
                            Text('Edit Profile', style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Today's Status Card ──────────────────────────
                  todayStatus.when(
                    data: (status) => _TodayStatusCard(status: status),
                    loading: () => const ShimmerBox(height: 80, radius: 16),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 20),

                  // ── Batch & Tutor Card ────────────────────────────
                  profileState.when(
                    data: (student) => _AssignmentCard(student: student),
                    loading: () => const ShimmerBox(height: 80, radius: 16),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),

                  // ── Attendance Summary ────────────────────────────
                  Text('MY ATTENDANCE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 0.8)),
                  const SizedBox(height: 12),
                  attendanceStats.when(
                    data: (stats) => _AttendanceSummaryCard(stats: stats),
                    loading: () => const ShimmerBox(height: 100, radius: 16),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),

                  // ── My Sections ────────────────────────────────────
                  Text('MY SECTIONS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 0.8)),
                  const SizedBox(height: 12),
                  _NavGroup(tiles: [
                    _NavTile(icon: Icons.auto_stories_rounded, title: 'Library', subtitle: 'E-Content & Study Materials', color: const Color(0xFF0891B2), onTap: () => context.push('/student/content')),
                    _NavTile(
                      icon: Icons.campaign_rounded, title: 'Announcements', subtitle: 'Notice board from institute', color: const Color(0xFFDC2626),
                      hasHighlight: hasAnnouncements,
                      onTap: () => context.push('/student/announcements'),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
                      icon: const Icon(Icons.logout_rounded, size: 16, color: Color(0xFF94A3B8)),
                      label: Text('Sign Out', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _TodayStatusCard extends StatelessWidget {
  final String? status;
  const _TodayStatusCard({this.status});

  @override
  Widget build(BuildContext context) {
    final s = status?.toLowerCase();
    final (label, color, icon) = switch (s) {
      'present' => ('Marked Present Today', const Color(0xFF059669), Icons.check_circle_rounded),
      'absent'  => ('Marked Absent Today', const Color(0xFFDC2626), Icons.cancel_rounded),
      'late'    => ('Marked Late', const Color(0xFFD97706), Icons.access_time_filled_rounded),
      _         => ('Not Yet Marked', const Color(0xFF94A3B8), Icons.radio_button_unchecked_rounded),
    };

    final formattedDate = DateFormat('EEE, d MMM yyyy').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Status for $formattedDate", style: GoogleFonts.inter(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
        ]),
      ]),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final dynamic student;
  const _AssignmentCard({this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: IntrinsicHeight(
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Batch', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(student?.batchName ?? '—', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
          ])),
          Container(width: 1, color: const Color(0xFFF1F5F9)),
          const SizedBox(width: 20),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tutor', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(student?.tutorName ?? '—', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)), overflow: TextOverflow.ellipsis),
          ])),
        ]),
      ),
    );
  }
}

class _AttendanceSummaryCard extends StatelessWidget {
  final Map<String, int> stats;
  const _AttendanceSummaryCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final present = stats['present'] ?? 0;
    final total = stats['total'] ?? 0;
    final absent = stats['absent'] ?? 0;
    final late = stats['late'] ?? 0;
    final percent = (total > 0 ? present / total : 0.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        CircularPercentIndicator(
          radius: 42,
          lineWidth: 7,
          percent: percent,
          center: Text('${(percent * 100).toInt()}%', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800)),
          progressColor: percent > 0.75 ? const Color(0xFF0284C7) : const Color(0xFFDC2626),
          backgroundColor: const Color(0xFFF1F5F9),
          circularStrokeCap: CircularStrokeCap.round,
        ),
        const SizedBox(width: 20),
        Expanded(child: Column(children: [
          _StatRow(label: 'Present', value: present, color: const Color(0xFF059669)),
          _StatRow(label: 'Late', value: late, color: const Color(0xFFD97706)),
          _StatRow(label: 'Absent', value: absent, color: const Color(0xFFDC2626)),
        ])),
      ]),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
        const Spacer(),
        Text('$value days', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
      ]),
    );
  }
}

// ── Navigation Group ──────────────────────────────────────────────────────────
class _NavGroup extends StatelessWidget {
  final List<_NavTile> tiles;
  const _NavGroup({required this.tiles});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: List.generate(tiles.length, (i) {
          final isLast = i == tiles.length - 1;
          return Column(children: [
            tiles[i],
            if (!isLast) const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF1F5F9)),
          ]);
        }),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool hasHighlight;

  const _NavTile({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap, this.hasHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Stack(children: [
              Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
              if (hasHighlight) Positioned(right: 0, top: 0, child: Container(width: 9, height: 9, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)))),
            ]),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF1E293B))),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
            ])),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
          ]),
        ),
      ),
    );
  }
}
