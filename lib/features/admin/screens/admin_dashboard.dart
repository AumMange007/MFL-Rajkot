import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../router/app_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../widgets/common_widgets.dart';
import '../providers/admin_stats_provider.dart';
import '../../common/providers/profile_photo_provider.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user  = ref.watch(currentUserProvider);
    final stats = ref.watch(adminStatsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('MFL RAJKOAT'),
          ],
        ),
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
              onTap: () => ref.read(profilePhotoProvider.notifier).pickAndUploadImage(),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(user.avatarUrl!)
                    : null,
                child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                    ? Text(user?.name?[0].toUpperCase() ?? "A",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer))
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Greeting Card ──────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${user?.name?.split(' ').first ?? "Admin"} 👋',
                            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'MFL RAJKOAT Admin Portal',
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref.read(profilePhotoProvider.notifier).pickAndUploadImage(),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                              ? CachedNetworkImageProvider(user.avatarUrl!)
                              : null,
                          child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                              ? Text(user?.name?[0].toUpperCase() ?? "A",
                                  style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold))
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Stat Cards ──────────────────────────────────────────
              Text('Overview', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StatCard(
                    label: 'Students',
                    value: stats.maybeWhen(data: (s) => s.totalStudents.toString(), orElse: () => '—'),
                    icon: Icons.people_rounded,
                    gradient: const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  ),
                  _StatCard(
                    label: 'Tutors',
                    value: stats.maybeWhen(data: (s) => s.totalTutors.toString(), orElse: () => '—'),
                    icon: Icons.badge_rounded,
                    gradient: const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                  ),
                  _StatCard(
                    label: 'Batches',
                    value: stats.maybeWhen(data: (s) => s.totalBatches.toString(), orElse: () => '—'),
                    icon: Icons.layers_rounded,
                    gradient: const [Color(0xFF059669), Color(0xFF0D9488)],
                  ),
                  _StatCard(
                    label: 'E-Content',
                    value: stats.maybeWhen(data: (s) => s.totalContent.toString(), orElse: () => '—'),
                    icon: Icons.folder_copy_rounded,
                    gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Quick Actions ───────────────────────────────────────
              Text('Quick Actions', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              _ActionTile(icon: Icons.people_alt_rounded, title: 'Manage Students',
                  subtitle: 'Add, view, or remove students', color: const Color(0xFF4F46E5),
                  onTap: () => context.go('${AppRoutes.admin}/${AppRoutes.manageStudents}')),
              _ActionTile(icon: Icons.badge_rounded, title: 'Manage Staff & Tutors',
                  subtitle: 'Add/Remove tutors & staff', color: const Color(0xFF7C3AED),
                  onTap: () => context.go('${AppRoutes.admin}/${AppRoutes.manageStaff}')),
              _ActionTile(icon: Icons.layers_rounded, title: 'Manage Batches',
                  subtitle: 'Create batches and assign tutors', color: const Color(0xFF0891B2),
                  onTap: () => context.go('${AppRoutes.admin}/${AppRoutes.manageBatches}')),
              _ActionTile(icon: Icons.folder_rounded, title: 'E-Content Library',
                  subtitle: 'Upload and assign study material', color: const Color(0xFF059669),
                  onTap: () => context.go('${AppRoutes.admin}/${AppRoutes.contentLib}')),
              _ActionTile(icon: Icons.fact_check_rounded, title: 'Attendance Reports',
                  subtitle: 'View detailed attendance statistics', color: const Color(0xFF0D9488),
                  onTap: () => context.go('${AppRoutes.admin}/${AppRoutes.attendance}')),
              _ActionTile(icon: Icons.history_toggle_off_rounded, title: 'Tutor Reports',
                  subtitle: 'View tutor working hours', color: const Color(0xFF7C3AED),
                  onTap: () => context.go('${AppRoutes.admin}/${AppRoutes.tutorAttendance}')),
              _ActionTile(icon: Icons.campaign_rounded, title: 'Announcements',
                  subtitle: 'Broadcast messages to students', color: const Color(0xFFF59E0B),
                  onTap: () => context.go('${AppRoutes.admin}/${AppRoutes.announcements}')),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  const _StatCard({required this.label, required this.value, required this.icon, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: gradient.first.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 1),
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
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
