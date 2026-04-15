import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../widgets/common_widgets.dart';
import '../../../models/announcement_model.dart';
import '../providers/announcement_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ManageAnnouncementsScreen extends ConsumerWidget {
  const ManageAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(announcementProvider);
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    
    // Managers and Admins have broadcast rights
    final canBroadcast = user?.isManager ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      appBar: AppBar(
        title: const Text('Broadcast Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.refresh(announcementProvider),
          ),
        ],
      ),
      floatingActionButton: canBroadcast ? FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context),
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('Post Announcement'),
      ) : null,
      body: state.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: EmptyState(icon: Icons.campaign_rounded, title: 'Silence is Golden', subtitle: 'Post something to keep the institute informed.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final ann = list[index];
              final isOwn = ann.createdBy == user?.id;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFF0284C7).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: Text('GLOBAL', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF0284C7))),
                              ),
                              const Spacer(),
                              if (isOwn || user?.isAdmin == true)
                                IconButton(
                                  icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 20),
                                  onPressed: () => _confirmDelete(context, ref, ann),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(ann.title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: const Color(0xFF0F172A))),
                          const SizedBox(height: 8),
                          Text(ann.message, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF475569), height: 1.5)),
                        ],
                      ),
                    ),
                    Container(height: 1, color: const Color(0xFFF1F5F9)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          CircleAvatar(radius: 12, backgroundColor: theme.colorScheme.primaryContainer, child: Text(ann.creatorName[0], style: const TextStyle(fontSize: 10))),
                          const SizedBox(width: 8),
                          Text(ann.creatorName, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                          const Spacer(),
                          Text(DateFormat('MMM d, h:mm a').format(ann.createdAt), style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateAnnouncementSheet(),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, AnnouncementModel ann) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Broadcast?'),
        content: const Text('This will remove the announcement for all students and staff. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              ref.read(announcementProvider.notifier).deleteAnnouncement(ann.id);
              Navigator.pop(ctx);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class CreateAnnouncementSheet extends ConsumerStatefulWidget {
  const CreateAnnouncementSheet({super.key});
  @override
  ConsumerState<CreateAnnouncementSheet> createState() => _CreateAnnouncementSheetState();
}

class _CreateAnnouncementSheetState extends ConsumerState<CreateAnnouncementSheet> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(announcementProvider.notifier).createAnnouncement(
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      padding: EdgeInsets.fromLTRB(28, 20, 28, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 24),
          Text('Post New Announcement', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('This will be broadcasted to all students and faculty.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 32),
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              hintText: 'Headline (e.g. Holiday Notice)',
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentCtrl,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Share the details here...',
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _isLoading ? null : _submit,
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7), padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: Text(_isLoading ? 'POSTING...' : 'BROADCAST NOW'),
          ),
        ],
      ),
    );
  }
}
