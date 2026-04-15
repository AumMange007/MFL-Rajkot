import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../widgets/common_widgets.dart';

class StaffProfileScreen extends ConsumerStatefulWidget {
  const StaffProfileScreen({super.key});

  @override
  ConsumerState<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends ConsumerState<StaffProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      appBar: AppBar(
        title: Text('My Profile', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => ProfilePhotoActions.showOptions(
                      context: context,
                      ref: ref,
                      currentImageUrl: user?.avatarUrl,
                    ),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFFF1F5F9),
                          backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                              ? CachedNetworkImageProvider(user.avatarUrl!)
                              : null,
                          child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                              ? Text(user?.name[0].toUpperCase() ?? "S", style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF0284C7)))
                              : null,
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Color(0xFF0284C7), shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(user?.name ?? "Staff Member", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  RoleBadge(role: user?.role ?? 'staff'),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                  _InfoTile(label: 'Email', value: user?.email ?? '—', icon: Icons.email_outlined),
                  _InfoTile(label: 'User ID', value: user?.id ?? '—', icon: Icons.fingerprint_rounded),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Stats or Actions (Simplified for now)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                   _ActionTile(
                     icon: Icons.lock_reset_rounded,
                     title: 'Change Password',
                     onTap: () {
                       // Future implementation
                     },
                   ),
                   const Divider(height: 1),
                   _ActionTile(
                     icon: Icons.logout_rounded,
                     title: 'Logout',
                     color: Colors.red,
                     onTap: () => ref.read(authNotifierProvider.notifier).signOut(),
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _InfoTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
              Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
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
  final VoidCallback onTap;
  final Color? color;

  const _ActionTile({required this.icon, required this.title, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF1E293B);
    return ListTile(
      leading: Icon(icon, color: c, size: 20),
      title: Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: c)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
