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
import '../../common/providers/attendance_summary_provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:coaching_app/models/tutor_attendance_model.dart';
import '../../common/screens/conversations_list_screen.dart';

class TutorDashboard extends ConsumerWidget {
  const TutorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final tutorState = ref.watch(tutorDashboardProvider);
    final attendanceState = ref.watch(tutorAttendanceProvider);
    final attendanceStats = ref.watch(attendanceSummaryProvider);
    final announcementsState = ref.watch(announcementProvider);
    final hasAnnouncements = announcementsState.maybeWhen(
      data: (list) => ref.read(announcementProvider.notifier).hasUnread(list),
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      drawer: const AppDrawer(),
      body: CustomScrollView(
        slivers: [
          // ── Sliver App Bar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0284C7),
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
                        ? Text(user?.name[0].toUpperCase() ?? 'T', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))
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
                    Text('Welcome back,', style: GoogleFonts.inter(fontSize: 14, color: Colors.white60)),
                    Text(user?.name.split(' ').first ?? 'Tutor', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Text('Tutor Portal • MFL Rajkot', style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
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
                  // ── Punch Card ────────────────────────────────────
                  _PunchCard(attendanceState: attendanceState),
                  const SizedBox(height: 24),

                  // ── My Stats ──────────────────────────────────────
                  Text('MY OVERVIEW', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 0.8)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _InfoCard(
                        label: 'Students',
                        value: tutorState.maybeWhen(data: (s) => s.totalStudents.toString(), orElse: () => '—'),
                        icon: Icons.people_rounded, color: const Color(0xFF0284C7),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _InfoCard(
                        label: 'Batches',
                        value: tutorState.maybeWhen(data: (s) => s.totalBatches.toString(), orElse: () => '—'),
                        icon: Icons.layers_rounded, color: const Color(0xFF0891B2),
                      )),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Attendance Summary ────────────────────────────
                  Text('MY PRESENCE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 0.8)),
                  const SizedBox(height: 12),
                  attendanceStats.when(
                    data: (stats) => _AttendanceSummaryCard(stats: stats),
                    loading: () => const ShimmerBox(height: 100, radius: 16),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),

                  // ── Assigned Batches ──────────────────────────────
                  Text('ASSIGNED BATCHES', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 0.8)),
                  const SizedBox(height: 12),
                  tutorState.when(
                    data: (stats) {
                      if (stats.batches.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: Text('No batches assigned yet.', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13)),
                        );
                      }
                      return SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: stats.batches.length,
                          itemBuilder: (context, i) {
                            final b = stats.batches[i];
                            return Container(
                              width: 160,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: const Color(0xFF0891B2).withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF0891B2), shape: BoxShape.circle)),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text(b.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  ]),
                                  const SizedBox(height: 6),
                                  Text('${b.tutorIds.length} tutor(s)', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                    loading: () => const ShimmerBox(height: 90, radius: 16),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),

                  // ── Quick Actions ─────────────────────────────────
                  Text('QUICK ACTIONS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 0.8)),
                  const SizedBox(height: 12),
                  _NavGroup(tiles: [
                    _NavTile(icon: Icons.fact_check_rounded, title: 'Mark Attendance', color: const Color(0xFF059669), onTap: () => context.push('/tutor/mark-attendance')),
                    _NavTile(icon: Icons.layers_rounded, title: 'My Batches', color: const Color(0xFF0891B2), onTap: () => context.push('/tutor/batches')),
                    _NavTile(icon: Icons.upload_file_rounded, title: 'E-Content Library', color: const Color(0xFF0891B2), onTap: () => context.push('/tutor/content')),
                    _NavTile(
                      icon: Icons.campaign_rounded, title: 'Announcements', color: const Color(0xFFDC2626),
                      hasHighlight: hasAnnouncements,
                      onTap: () { ref.read(announcementProvider.notifier).markAsSeen(); context.push('/tutor/announcements'); },
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
    );
  }
}

// ── Punch Card ────────────────────────────────────────────────────────────────
class _PunchCard extends ConsumerStatefulWidget {
  final AsyncValue<StaffAttendanceModel?> attendanceState;
  const _PunchCard({required this.attendanceState});

  @override
  ConsumerState<_PunchCard> createState() => _PunchCardState();
}

class _PunchCardState extends ConsumerState<_PunchCard> {
  Future<void> _handlePunch(bool isPunchedIn) async {
    try {
      if (isPunchedIn) {
        await ref.read(tutorAttendanceProvider.notifier).punchOut();
      } else {
        await ref.read(tutorAttendanceProvider.notifier).punchIn();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.attendanceState.when(
      data: (attendance) {
        final isPunchedIn = attendance != null;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPunchedIn ? [const Color(0xFF0F172A), const Color(0xFF1E293B)] : [const Color(0xFF0284C7), const Color(0xFF0891B2)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: (isPunchedIn ? const Color(0xFF0F172A) : const Color(0xFF0284C7)).withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(isPunchedIn ? Icons.verified_user_rounded : Icons.fingerprint_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isPunchedIn ? 'Active On Duty' : 'Not Clocked In', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(
                      isPunchedIn ? 'Punched in at ${attendance.punchInAt.hour}:${attendance.punchInAt.minute.toString().padLeft(2, "0")}' : 'Tap to mark your attendance',
                      style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _handlePunch(isPunchedIn),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: isPunchedIn ? Colors.red[700] : const Color(0xFF0284C7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  elevation: 0,
                ),
                child: Text(isPunchedIn ? 'Punch Out' : 'Punch In', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
        );
      },
      loading: () => const ShimmerBox(height: 80, radius: 20),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Info Card ─────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _InfoCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

// ── Attendance Summary Card ────────────────────────────────────────────────
class _AttendanceSummaryCard extends StatelessWidget {
  final Map<String, int> stats;
  const _AttendanceSummaryCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final present = stats['present'] ?? 0;
    final total = stats['total'] ?? 0;
    final absent = stats['absent'] ?? 0;
    final late = stats['late'] ?? 0;
    final percent = total > 0 ? present / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 38,
            lineWidth: 6,
            percent: percent.clamp(0.0, 1.0),
            center: Text('${(percent * 100).toInt()}%', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800)),
            progressColor: percent > 0.75 ? const Color(0xFF059669) : const Color(0xFFDC2626),
            backgroundColor: const Color(0xFFF1F5F9),
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(width: 20),
          Expanded(child: Column(
            children: [
              _Row(label: 'Present', value: '$present days', color: const Color(0xFF059669)),
              _Row(label: 'Late', value: '$late days', color: const Color(0xFFD97706)),
              _Row(label: 'Absent', value: '$absent days', color: const Color(0xFFDC2626)),
            ],
          )),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Row({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
        const Spacer(),
        Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
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
  final Color color;
  final VoidCallback onTap;
  final bool hasHighlight;

  const _NavTile({required this.icon, required this.title, required this.color, required this.onTap, this.hasHighlight = false});

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
            Expanded(child: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF1E293B)))),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
          ]),
        ),
      ),
    );
  }
}
