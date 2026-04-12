import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../widgets/common_widgets.dart';
import '../../../models/user_model.dart';
import '../providers/tutor_management_provider.dart';
import '../../common/providers/profile_photo_provider.dart';
import '../../common/providers/attendance_summary_provider.dart';

class ManageTutorsScreen extends ConsumerWidget {
  const ManageTutorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tutorsState = ref.watch(tutorManagementProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tutors'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTutorSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Tutor'),
      ),
      body: tutorsState.when(
        data: (tutors) {
          if (tutors.isEmpty) {
            return const Center(
              child: EmptyState(
                icon: Icons.person_add_disabled_outlined,
                title: 'No tutors found',
                subtitle: 'Add tutors to start creating batches.',
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tutors.length,
            itemBuilder: (context, index) {
              final tutor = tutors[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    backgroundImage: tutor.avatarUrl != null && tutor.avatarUrl!.isNotEmpty 
                        ? CachedNetworkImageProvider(tutor.avatarUrl!) 
                        : null,
                    child: tutor.avatarUrl == null || tutor.avatarUrl!.isEmpty
                      ? Text(tutor.name[0].toUpperCase())
                      : null,
                  ),
                  onTap: () => _showProfile(context, tutor),
                  title: Text(tutor.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(tutor.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_a_photo_rounded, size: 20),
                        onPressed: () => ref.read(profilePhotoProvider.notifier).uploadForUser(tutor.id),
                        tooltip: 'Update Tutor Photo',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                        onPressed: () => _confirmDelete(context, ref, tutor),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(message: err.toString(), onRetry: () => ref.refresh(tutorManagementProvider)),
      ),
    );
  }

  void _showAddTutorSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddTutorSheet(),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, UserModel tutor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tutor?'),
        content: Text('Remove ${tutor.name}? This could affect associated batches.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(tutorManagementProvider.notifier).deleteTutor(tutor);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showProfile(BuildContext context, UserModel tutor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TutorProfileSheet(tutor: tutor),
    );
  }
}

class TutorProfileSheet extends ConsumerWidget {
  final UserModel tutor;
  const TutorProfileSheet({super.key, required this.tutor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attState = ref.watch(weeklyTutorAttendanceProvider(tutor.id));
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: tutor.avatarUrl != null ? CachedNetworkImageProvider(tutor.avatarUrl!) : null,
                child: tutor.avatarUrl == null ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tutor.name, style: Theme.of(context).textTheme.titleLarge),
                    Text(tutor.email),
                    Text('Phone: ${tutor.phone ?? "Not provided"}', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text('Weekly Pulse (Last 7 Days)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          attState.when(
            data: (stats) => Row(
              children: [
                _StatCard(title: 'Days Worked', value: stats['days_worked'].toString(), color: Colors.blue),
                const SizedBox(width: 12),
                _StatCard(title: 'Total Hours', value: stats['total_hours'].toString(), color: Colors.purple),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}

class AddTutorSheet extends ConsumerStatefulWidget {
  const AddTutorSheet({super.key});

  @override
  ConsumerState<AddTutorSheet> createState() => _AddTutorSheetState();
}

class _AddTutorSheetState extends ConsumerState<AddTutorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose(); _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(tutorManagementProvider.notifier).addTutor(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _pwdCtrl.text.trim(),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add New Tutor', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 16),
            TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email))),
            const SizedBox(height: 16),
            TextFormField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone))),
            const SizedBox(height: 16),
            TextFormField(controller: _pwdCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock))),
            const SizedBox(height: 32),
            FilledButton(onPressed: _isLoading ? null : _submit, child: const Text('Create Tutor')),
          ],
        ),
      ),
    );
  }
}
