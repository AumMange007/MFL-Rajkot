import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../widgets/common_widgets.dart';
import '../../admin/providers/announcement_provider.dart';
import '../../common/providers/profile_photo_provider.dart';
import '../../tutor/providers/tutor_attendance_provider.dart';
import 'package:coaching_app/models/tutor_attendance_model.dart';

class StaffDashboard extends ConsumerWidget {
  const StaffDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final attendanceState = ref.watch(tutorAttendanceProvider);
    final theme = Theme.of(context);

    // Get unread announcements for the badge
    final announcementsState = ref.watch(announcementProvider);
    final hasUnread = announcementsState.maybeWhen(
      data: (list) => ref.read(announcementProvider.notifier).hasUnread(list),
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(user, theme, ref),
            const SizedBox(height: 24),
            
            // Attendance Card (Geofenced)
            _buildPunchCard(context, ref, attendanceState, theme),
            const SizedBox(height: 32),

            Text('Quick Actions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _ActionTile(
              icon: Icons.campaign_rounded,
              title: 'Announcements',
              subtitle: 'Internal notices & updates',
              color: const Color(0xFFF43F5E),
              hasHighlight: hasUnread,
              onTap: () {
                ref.read(announcementProvider.notifier).markAsSeen();
                context.push('/staff/announcements');
              },
            ),
            _ActionTile(
              icon: Icons.people_outline_rounded,
              title: 'Students',
              subtitle: 'View student registry',
              color: Colors.blue,
              onTap: () => context.push('/staff/students'),
            ),
            _ActionTile(
              icon: Icons.auto_stories_rounded,
              title: 'Study Materials',
              subtitle: 'View E-Content Library',
              color: Colors.amber,
              onTap: () => context.push('/staff/library'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic user, ThemeData theme, WidgetRef ref) {
    final attendance = ref.watch(tutorAttendanceProvider).valueOrNull;
    final isOnDuty = attendance != null;
    
    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: user?.avatarUrl != null ? CachedNetworkImageProvider(user!.avatarUrl!) : null,
              child: user?.avatarUrl == null ? Text(user?.name[0] ?? "S") : null,
            ),
            if (isOnDuty)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.surface, width: 2),
                    boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello, ${user?.name ?? "User"} 👋', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              Text(isOnDuty ? 'You are ON-DUTY' : 'Welcome to MFL ELmana', style: theme.textTheme.bodyMedium?.copyWith(color: isOnDuty ? Colors.greenAccent : theme.colorScheme.outline)),
            ],
          ),
        ),
      ],
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
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)] 
                : [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(isPunchedIn ? Icons.verified_user_rounded : Icons.location_on_rounded, color: Colors.white, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isPunchedIn ? 'You are ON-DUTY' : 'On-Premise Attendance', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(isPunchedIn ? 'Punched in at: ${attendance.punchInAt.hour}:${attendance.punchInAt.minute.toString().padLeft(2, '0')}' : 'Verify your presence at the institute', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => _handlePunch(context, ref, isPunchedIn),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: isPunchedIn ? Colors.red : theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(isPunchedIn ? 'Punch Out' : 'Punch In Now', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Text('Attendance error: $e', style: const TextStyle(color: Colors.red, fontSize: 12)),
      ),
    );
  }

  Future<void> _handlePunch(BuildContext context, WidgetRef ref, bool isPunchedIn) async {
    try {
      if (isPunchedIn) {
        await ref.read(tutorAttendanceProvider.notifier).punchOut();
      } else {
        await ref.read(tutorAttendanceProvider.notifier).punchIn();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool hasHighlight;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap, this.hasHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color),
            ),
            if (hasHighlight)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                ),
              ),
          ],
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      ),
    );
  }
}
