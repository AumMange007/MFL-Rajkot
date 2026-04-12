import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../widgets/common_widgets.dart';
import '../../../models/announcement_model.dart';
import '../../../models/batch_model.dart';
import '../providers/announcement_provider.dart';
import '../providers/student_management_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ManageAnnouncementsScreen extends ConsumerWidget {
  const ManageAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(announcementProvider);
    final user  = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final hasManagementAccess = user?.role == 'admin' || user?.role == 'tutor' || user?.role == 'staff';

    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      floatingActionButton: hasManagementAccess ? FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Announcement'),
      ) : null,
      body: state.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: EmptyState(
                icon: Icons.campaign_outlined,
                title: 'No announcements',
                subtitle: 'Keep everyone informed by creating your first post.',
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final ann = list[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(ann.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                          if (hasManagementAccess) IconButton(
                             icon: Icon(Icons.delete_outline, color: theme.colorScheme.error, size: 20),
                             onPressed: () => ref.read(announcementProvider.notifier).deleteAnnouncement(ann.id),
                           ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(ann.message, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 14, color: theme.colorScheme.outline),
                          const SizedBox(width: 4),
                          Text(ann.creatorName, style: TextStyle(fontSize: 12, color: theme.colorScheme.outline)),
                          const Spacer(),
                          Text(DateFormat('MMM d, h:mm a').format(ann.createdAt), style: TextStyle(fontSize: 12, color: theme.colorScheme.outline)),
                        ],
                      ),
                    ],
                  ),
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

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateAnnouncementSheet(),
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
  String? _selectedBatchId;
  bool _isLoading = false;

  @override
  void dispose() {
     _titleCtrl.dispose();
     _contentCtrl.dispose();
     super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.isEmpty || _contentCtrl.text.isEmpty) return;
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
    final batchesState = ref.watch(adminBatchesProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('New Announcement', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 16),
          TextField(controller: _contentCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Content')),
          const SizedBox(height: 16),
          // Batch selection temporarily hidden to ensure DB compatibility
          const SizedBox(height: 32),
          FilledButton(onPressed: _isLoading ? null : _submit, child: const Text('Post Global Announcement')),
        ],
      ),
    );
  }
}
