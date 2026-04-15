import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../widgets/common_widgets.dart';
import '../../admin/providers/announcement_provider.dart';
import '../../tutor/providers/tutor_attendance_provider.dart';
import 'package:coaching_app/models/tutor_attendance_model.dart';
import '../../../router/app_router.dart';

class StaffDashboard extends ConsumerWidget {
  const StaffDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final attendanceState = ref.watch(tutorAttendanceProvider);
    final isManager = user?.isManager ?? false;
    final announcementsState = ref.watch(announcementProvider);
    final hasUnread = announcementsState.maybeWhen(
      data: (list) => ref.read(announcementProvider.notifier).hasUnread(list),
      orElse: () => false,
    );

    final portalColor = const Color(0xFF0891B2);
    final gradientColors = [const Color(0xFF0369A1), const Color(0xFF0891B2)];

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
            backgroundColor: portalColor,
            leading: Builder(builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            )),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradientColors)),
                padding: const EdgeInsets.fromLTRB(24, 90, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(children: [
                      GestureDetector(
                        onTap: () => ProfilePhotoActions.showOptions(
                          context: context,
                          ref: ref,
                          currentImageUrl: user?.avatarUrl,
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          backgroundImage: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty) ? CachedNetworkImageProvider(user.avatarUrl!) : null,
                          child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty) ? Text(user?.name[0].toUpperCase() ?? 'S', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)) : null,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(user?.name.split(' ').first ?? 'Staff', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                          child: Text(isManager ? '⭐ Manager Portal' : 'Staff Portal', style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ])),
                    ]),
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
                  // ── Punch Card ───────────────────────────────────
                  _PunchCard(attendanceState: attendanceState),
                  const SizedBox(height: 28),

                  // ── Management Section ────────────────────────────
                  Text('MANAGEMENT', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 0.8)),
                  const SizedBox(height: 12),
                  _NavGroup(tiles: [
                    _NavTile(icon: Icons.people_alt_rounded, title: 'Students', color: const Color(0xFF0284C7), onTap: () => context.go('${AppRoutes.staff}/${AppRoutes.manageStudents}')),
                    _NavTile(
                      icon: isManager ? Icons.admin_panel_settings_rounded : Icons.badge_rounded,
                      title: isManager ? 'Staff & Tutors' : 'Tutors',
                      color: const Color(0xFF0891B2),
                      onTap: () => context.go('${AppRoutes.staff}/${AppRoutes.manageStaff}'),
                    ),
                    _NavTile(icon: Icons.layers_rounded, title: 'Batches', color: const Color(0xFF0891B2), onTap: () => context.go('${AppRoutes.staff}/${AppRoutes.manageBatches}')),
                    _NavTile(icon: Icons.folder_copy_rounded, title: 'E-Content Library', color: const Color(0xFFD97706), onTap: () => context.go('${AppRoutes.staff}/${AppRoutes.contentLib}')),
                    if (isManager)
                      _NavTile(icon: Icons.manage_search_rounded, title: 'Enrollment Pipeline', color: const Color(0xFF6366F1), onTap: () => context.go('${AppRoutes.staff}/${AppRoutes.leads}'), hasHighlight: true),
                  ]),

                  const SizedBox(height: 24),

                  // ── Reports & Comms Section ────────────────────────
                  Text('REPORTS & COMMUNICATIONS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 0.8)),
                  const SizedBox(height: 12),
                  _NavGroup(tiles: [
                    _NavTile(icon: Icons.fact_check_rounded, title: 'Mark Attendance', color: const Color(0xFFD946EF), onTap: () => context.go('${AppRoutes.staff}/${AppRoutes.markAttendance}')),
                    _NavTile(icon: Icons.analytics_rounded, title: 'Student Attendance Logs', color: const Color(0xFF059669), onTap: () => context.go('${AppRoutes.staff}/${AppRoutes.attendance}')),
                    if (isManager)
                      _NavTile(icon: Icons.history_toggle_off_rounded, title: 'Staff & Tutor Logs', color: const Color(0xFF6366F1), onTap: () => context.go('${AppRoutes.staff}/${AppRoutes.tutorAttendance}')),
                    _NavTile(
                      icon: Icons.campaign_rounded, title: 'Announcements', color: const Color(0xFFDC2626),
                      hasHighlight: hasUnread,
                      onTap: () {
                        ref.read(announcementProvider.notifier).markAsSeen();
                        context.go('${AppRoutes.staff}/${AppRoutes.announcements}');
                      },
                    ),
                  ]),
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
              colors: isPunchedIn ? [const Color(0xFF064E3B), const Color(0xFF065F46)] : [const Color(0xFF0369A1), const Color(0xFF0891B2)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(isPunchedIn ? Icons.verified_rounded : Icons.fingerprint_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isPunchedIn ? 'On Duty' : 'Not Clocked In', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              Text(
                isPunchedIn ? 'Since ${attendance.punchInAt.hour}:${attendance.punchInAt.minute.toString().padLeft(2, "0")}' : 'Tap to clock in for today',
                style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
              ),
            ])),
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
          ]),
        );
      },
      loading: () => const ShimmerBox(height: 80, radius: 20),
      error: (_, __) => const SizedBox.shrink(),
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
