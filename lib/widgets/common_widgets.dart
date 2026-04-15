import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/common/providers/profile_photo_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE PHOTO ACTIONS HELPER
// ─────────────────────────────────────────────────────────────────────────────
class ProfilePhotoActions {
  static void showOptions({
    required BuildContext context,
    required WidgetRef ref,
    required String? currentImageUrl,
    String? targetUserId, // Optional, defaults to current user
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Profile Photo', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF0284C7).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF0284C7), size: 20),
                ),
                title: Text('Upload New Photo', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  if (targetUserId != null) {
                    ref.read(profilePhotoProvider.notifier).uploadForUser(targetUserId);
                  } else {
                    ref.read(profilePhotoProvider.notifier).pickAndUploadImage();
                  }
                },
              ),
              if (currentImageUrl != null && currentImageUrl.isNotEmpty) ...[
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                  ),
                  title: Text('Remove Photo', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(context: context, ref: ref, targetUserId: targetUserId);
                  },
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  static void _confirmDelete({required BuildContext context, required WidgetRef ref, String? targetUserId}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Photo?'),
        content: const Text('Are you sure you want to remove this profile photo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(profilePhotoProvider.notifier).deletePhoto(targetUserId);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADING SHIMMER
// ─────────────────────────────────────────────────────────────────────────────
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const ShimmerBox({super.key, this.width = double.infinity, this.height = 16, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
      highlightColor: isDark ? const Color(0xFF4A5568) : const Color(0xFFF8FAFC),
      child: Container(
        width: width, height: height,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radius)),
      ),
    );
  }
}

class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});
  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ShimmerBox(height: 16, width: 160), SizedBox(height: 10),
          ShimmerBox(height: 12), SizedBox(height: 6),
          ShimmerBox(height: 12, width: 240),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT CARD — used on dashboards
// ─────────────────────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({super.key, required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
              Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: theme.colorScheme.primary.withOpacity(0.5)),
            ),
            const SizedBox(height: 20),
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF0F172A)), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)), textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ERROR STATE
// ─────────────────────────────────────────────────────────────────────────────
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFE11D48)),
            ),
            const SizedBox(height: 20),
            Text('Something went wrong', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ROLE BADGE
// ─────────────────────────────────────────────────────────────────────────────
class RoleBadge extends StatelessWidget {
  final String role;
  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (role) {
      'admin'   => ('Admin',   const Color(0xFF0284C7)),
      'tutor'   => ('Tutor',   const Color(0xFF0284C7)),
      'student' => ('Student', const Color(0xFF0284C7)),
      'staff'   => ('Staff',   const Color(0xFF0284C7)),
      _         => ('User',    const Color(0xFF0284C7)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)))),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADING BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;

  const LoadingButton({super.key, required this.isLoading, required this.onPressed, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
              Text(label),
            ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP DRAWER
// ─────────────────────────────────────────────────────────────────────────────
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    // Role-based gradient matching each dashboard's identity
    final (gradStart, gradEnd, accentColor) = switch (user?.role) {
      'admin'   => (const Color(0xFF0369A1), const Color(0xFF0891B2), const Color(0xFF0284C7)),
      'tutor'   => (const Color(0xFF0369A1), const Color(0xFF0891B2), const Color(0xFF0284C7)),
      'student' => (const Color(0xFF0369A1), const Color(0xFF0891B2), const Color(0xFF0284C7)),
      'staff'   => (const Color(0xFF0369A1), const Color(0xFF0891B2), const Color(0xFF0284C7)),
      _         => (const Color(0xFF0369A1), const Color(0xFF0891B2), const Color(0xFF0284C7)),
    };

    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 24, 20, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [gradStart, gradEnd],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(user.avatarUrl!)
                      : null,
                  child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                      ? Text(user?.name[0].toUpperCase() ?? "U",
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white))
                      : null,
                ),
                const SizedBox(height: 14),
                Text(user?.name ?? "User",
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 2),
                Text(user?.email ?? "",
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.75))),
                const SizedBox(height: 10),
                RoleBadge(role: user?.role ?? 'student'),
              ],
            ),
          ),

          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerItem(
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  color: accentColor,
                  onTap: () {
                    context.pop();
                    final role = user?.role;
                    if (role == 'admin') {
                      context.go('/admin');
                    } else if (role == 'tutor') context.go('/tutor');
                    else if (role == 'student') context.go('/student');
                    else if (role == 'staff') context.go('/staff');
                  },
                ),
                if (user?.role == 'student' || user?.role == 'tutor' || user?.role == 'staff')
                  _DrawerItem(
                    icon: Icons.person_rounded,
                    title: 'My Profile',
                    color: accentColor,
                    onTap: () {
                      context.pop();
                      if (user?.role == 'student') {
                        context.push('/student/profile');
                      } else if (user?.role == 'tutor') {
                        context.push('/tutor/profile');
                      } else if (user?.role == 'staff') {
                        context.push('/staff/profile');
                      }
                    },
                  ),
                
                // -- Admin & Staff Quick Links --
                if (user?.role == 'admin' || user?.role == 'staff') ...[
                  _DrawerItem(icon: Icons.people_alt_rounded, title: 'Manage Students', color: accentColor, onTap: () { context.pop(); context.go('/${user!.role}/students'); }),
                  _DrawerItem(icon: Icons.admin_panel_settings_rounded, title: 'Staff & Tutors', color: accentColor, onTap: () { context.pop(); context.go('/${user!.role}/staff'); }),
                  _DrawerItem(icon: Icons.layers_rounded, title: 'Manage Batches', color: accentColor, onTap: () { context.pop(); context.go('/${user!.role}/batches'); }),
                  _DrawerItem(icon: Icons.analytics_rounded, title: 'Attendance Reports', color: accentColor, onTap: () { context.pop(); context.go('/${user!.role}/reports'); }),
                  _DrawerItem(icon: Icons.campaign_rounded, title: 'Announcements', color: accentColor, onTap: () { context.pop(); context.go('/${user!.role}/announcements'); }),
                  _DrawerItem(icon: Icons.menu_book_rounded, title: 'Content Library', color: accentColor, onTap: () { context.pop(); context.go('/${user!.role}/content'); }),
                  if (user?.role == 'admin')
                    _DrawerItem(icon: Icons.manage_search_rounded, title: 'Enrollment Pipeline', color: const Color(0xFF6366F1), onTap: () { context.pop(); context.go('/admin/leads'); }),
                  if (user?.role == 'staff' && (user?.isManager ?? false))
                    _DrawerItem(icon: Icons.manage_search_rounded, title: 'Enrollment Pipeline', color: const Color(0xFF6366F1), onTap: () { context.pop(); context.go('/staff/leads'); }),
                ],

                // -- Tutor Quick Links --
                if (user?.role == 'tutor') ...[
                  _DrawerItem(icon: Icons.layers_rounded, title: 'My Batches', color: accentColor, onTap: () { context.pop(); context.push('/tutor/batches'); }),
                  _DrawerItem(icon: Icons.people_alt_rounded, title: 'My Students', color: accentColor, onTap: () { context.pop(); context.push('/tutor/students'); }),
                  _DrawerItem(icon: Icons.checklist_rtl_rounded, title: 'Mark Attendance', color: accentColor, onTap: () { context.pop(); context.push('/tutor/mark-attendance'); }),
                  _DrawerItem(icon: Icons.campaign_rounded, title: 'Announcements', color: accentColor, onTap: () { context.pop(); context.push('/tutor/announcements'); }),
                  _DrawerItem(icon: Icons.menu_book_rounded, title: 'Content Library', color: accentColor, onTap: () { context.pop(); context.push('/tutor/content'); }),
                ],

                // -- Student Quick Links --
                if (user?.role == 'student') ...[
                  _DrawerItem(icon: Icons.menu_book_rounded, title: 'Content Library', color: accentColor, onTap: () { context.pop(); context.push('/student/content'); }),
                  _DrawerItem(icon: Icons.campaign_rounded, title: 'Announcements', color: accentColor, onTap: () { context.pop(); context.push('/student/announcements'); }),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Divider(),
                ),
                _DrawerItem(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  color: const Color(0xFFE11D48),
                  onTap: () {
                    context.pop();
                    ref.read(authNotifierProvider.notifier).signOut();
                  },
                ),
              ],
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 12, color: Color(0xFF94A3B8)),
                const SizedBox(width: 6),
                Text('MFL ELmana v1.0.0',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({required this.icon, required this.title, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF0F172A);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: c.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: c, size: 18),
      ),
      title: Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: c)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }
}
