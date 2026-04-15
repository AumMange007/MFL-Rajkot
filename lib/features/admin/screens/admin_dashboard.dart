import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../router/app_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../widgets/common_widgets.dart';
import '../providers/admin_stats_provider.dart';
import '../../common/screens/conversations_list_screen.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user  = ref.watch(currentUserProvider);
    final stats = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      drawer: const AppDrawer(),
      body: CustomScrollView(
        slivers: [
          // ── Sliver App Bar ───────────────────────────────────────────
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
                        ? Text(user?.name[0].toUpperCase() ?? 'A', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))
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
                    Text('Good day,', style: GoogleFonts.inter(fontSize: 14, color: Colors.white60)),
                    Text(user?.name.split(' ').first ?? 'Admin', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Text('Super Admin • MFL Rajkot', style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
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
                  // ── Bento Stats ─────────────────────────────────────
                  Row(
                    children: [
                      Expanded(child: _BentoStat(
                        label: 'Students',
                        value: stats.maybeWhen(data: (s) => s.totalStudents.toString(), orElse: () => '—'),
                        icon: Icons.people_rounded,
                        color: const Color(0xFF0284C7),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _BentoStat(
                        label: 'Tutors',
                        value: stats.maybeWhen(data: (s) => s.totalTutors.toString(), orElse: () => '—'),
                        icon: Icons.badge_rounded,
                        color: const Color(0xFF0891B2),
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _BentoStat(
                        label: 'Batches',
                        value: stats.maybeWhen(data: (s) => s.totalBatches.toString(), orElse: () => '—'),
                        icon: Icons.layers_rounded,
                        color: const Color(0xFF059669),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _BentoStat(
                        label: 'E-Content',
                        value: stats.maybeWhen(data: (s) => s.totalContent.toString(), orElse: () => '—'),
                        icon: Icons.folder_copy_rounded,
                        color: const Color(0xFFD97706),
                      )),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ── Management Section ───────────────────────────────
                  Text('Management', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 0.8)),
                  const SizedBox(height: 12),
                  _NavGroup(tiles: [
                    _NavTile(icon: Icons.people_alt_rounded, title: 'Students', subtitle: 'Manage enrollments', color: const Color(0xFF0284C7), onTap: () => context.go('${AppRoutes.admin}/${AppRoutes.manageStudents}')),
                    _NavTile(icon: Icons.badge_rounded, title: 'Staff & Tutors', subtitle: 'Team management', color: const Color(0xFF0284C7), onTap: () => context.go('${AppRoutes.admin}/${AppRoutes.manageStaff}')),
                    _NavTile(icon: Icons.layers_rounded, title: 'Batches', subtitle: 'Schedule & groups', color: const Color(0xFF0891B2), onTap: () => context.go('${AppRoutes.admin}/${AppRoutes.manageBatches}')),
                    _NavTile(icon: Icons.folder_rounded, title: 'E-Content Library', subtitle: 'Study materials', color: const Color(0xFF059669), onTap: () => context.go('${AppRoutes.admin}/${AppRoutes.contentLib}')),
                    _NavTile(icon: Icons.manage_search_rounded, title: 'Enrollment Pipeline', subtitle: 'View pipeline status', color: const Color(0xFF6366F1), onTap: () => context.go('${AppRoutes.admin}/${AppRoutes.leads}'), highlight: true),
                  ]),

                  const SizedBox(height: 24),

                  // ── Reports Section ──────────────────────────────────
                  Text('Reports & Communications', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 0.8)),
                  const SizedBox(height: 12),
                  _NavGroup(tiles: [
                    _NavTile(icon: Icons.fact_check_rounded, title: 'Mark Attendance', subtitle: 'Record daily presence', color: const Color(0xFFD946EF), onTap: () => context.go('${AppRoutes.admin}/${AppRoutes.markAttendance}')),
                    _NavTile(icon: Icons.analytics_rounded, title: 'Attendance Reports', subtitle: 'Student progress hub', color: const Color(0xFF0D9488), onTap: () => context.go('${AppRoutes.admin}/${AppRoutes.attendance}')),
                    _NavTile(icon: Icons.history_toggle_off_rounded, title: 'Staff & Tutor Logs', subtitle: 'Punch-in history', color: const Color(0xFF0D9488), onTap: () => context.go('${AppRoutes.admin}/${AppRoutes.tutorAttendance}')),
                    _NavTile(icon: Icons.campaign_rounded, title: 'Announcements', subtitle: 'Broadcast messages', color: const Color(0xFFDC2626), onTap: () => context.go('${AppRoutes.admin}/${AppRoutes.announcements}')),
                  ]),

                  const SizedBox(height: 16),
                  
                  // Logout
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

// ── Bento Stat Card ──────────────────────────────────────────────────────────
class _BentoStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _BentoStat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 16),
          Text(value, style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), height: 1)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Navigation Group (White Card) ────────────────────────────────────────────
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
          final tile = tiles[i];
          final isLast = i == tiles.length - 1;
          return Column(
            children: [
              tile,
              if (!isLast) const Divider(height: 1, indent: 60, endIndent: 16, color: Color(0xFFF1F5F9)),
            ],
          );
        }),
      ),
    );
  }
}

// ── Navigation Tile (Grouped) ─────────────────────────────────────────────
class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool highlight;

  const _NavTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.color,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF1E293B))),
                        if (highlight) ...[const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)), child: Text('NEW', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white)))],
                      ],
                    ),
                    if (subtitle != null)
                      Text(subtitle!, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
