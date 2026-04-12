import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../widgets/common_widgets.dart';
import '../../../models/batch_model.dart';
import '../../../models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/admin_stats_provider.dart';
import '../providers/batch_management_provider.dart';
import '../providers/tutor_management_provider.dart';

class ManageBatchesScreen extends ConsumerWidget {
  const ManageBatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final batchesState = ref.watch(batchManagementProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: const Text('Manage Batches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.refresh(batchManagementProvider),
          ),
        ],
      ),
      floatingActionButton: user?.role == 'admin' ? FloatingActionButton.extended(
        onPressed: () => _showAddBatchSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Batch'),
      ) : null,
      body: batchesState.when(
        data: (batches) {
          if (batches.isEmpty) {
            return const EmptyState(
              icon: Icons.layers_clear_outlined,
              title: 'No batches found',
              subtitle: 'Create your first batch and assign it to a tutor.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(batchManagementProvider),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: batches.length,
              itemBuilder: (context, index) {
                final batch = batches[index];
                return _BatchListItem(batch: batch);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
          message: err.toString(),
          onRetry: () => ref.refresh(batchManagementProvider),
        ),
      ),
    );
  }

  void _showAddBatchSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => const AddBatchSheet(),
    );
  }
}

class _BatchListItem extends ConsumerWidget {
  final BatchModel batch;
  const _BatchListItem({required this.batch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.layers_rounded, color: Color(0xFF4F46E5), size: 24),
          ),
          title: Text(
            batch.name, 
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF0F172A))
          ),
          subtitle: Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 12, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                batch.tutorNames.isEmpty 
                    ? 'No Tutors Assigned' 
                    : 'Tutors: ${batch.tutorNames.join(", ")}', 
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF4F46E5), size: 20),
                style: IconButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9)),
                onPressed: () => _showEditBatchSheet(context, ref, batch),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                style: IconButton.styleFrom(backgroundColor: const Color(0xFFFEF2F2)),
                onPressed: () => _confirmDelete(context, ref, batch),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditBatchSheet(BuildContext context, WidgetRef ref, BatchModel batch) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => EditBatchSheet(batch: batch),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, BatchModel batch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Batch?'),
        content: Text('Are you sure you want to remove the batch "${batch.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(batchManagementProvider.notifier).deleteBatch(batch);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class AddBatchSheet extends ConsumerStatefulWidget {
  const AddBatchSheet({super.key});

  @override
  ConsumerState<AddBatchSheet> createState() => _AddBatchSheetState();
}

class _AddBatchSheetState extends ConsumerState<AddBatchSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final List<String> _selectedTutorIds = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(batchManagementProvider.notifier).addBatch(
        name: _nameCtrl.text.trim(),
        tutorIds: _selectedTutorIds,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tutorsState = ref.watch(tutorManagementProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(28, 20, 28, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 24),
              Text('Create New Batch', 
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
              const SizedBox(height: 8),
              Text('Organize your students into groups or classes.', 
                  style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))),
              const SizedBox(height: 32),
              
              TextFormField(
                controller: _nameCtrl, 
                style: GoogleFonts.inter(fontSize: 14),
                decoration: const InputDecoration(labelText: 'Batch Name', prefixIcon: Icon(Icons.layers_outlined)),
                validator: (v) => (v == null || v.isEmpty) ? 'Batch name is required' : null,
              ),
              const SizedBox(height: 16),
              tutorsState.when(
                data: (tutors) {
                  if (tutors.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assign Tutors', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tutors.map((t) {
                          final isSelected = _selectedTutorIds.contains(t.id);
                          return FilterChip(
                            label: Text(t.name, style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : const Color(0xFF0F172A))),
                            selected: isSelected,
                            onSelected: (v) {
                              setState(() {
                                if (v) _selectedTutorIds.add(t.id);
                                else _selectedTutorIds.remove(t.id);
                              });
                            },
                            selectedColor: const Color(0xFF4F46E5),
                            checkmarkColor: Colors.white,
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12), 
                              side: BorderSide(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0), width: 1.5)
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (err, _) => Text('Error loading tutors', style: TextStyle(color: Colors.red, fontSize: 13)),
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: _isLoading ? null : _submit, 
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(_isLoading ? 'CREATING...' : 'CREATE BATCH'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class EditBatchSheet extends ConsumerStatefulWidget {
  final BatchModel batch;
  const EditBatchSheet({super.key, required this.batch});

  @override
  ConsumerState<EditBatchSheet> createState() => _EditBatchSheetState();
}

class _EditBatchSheetState extends ConsumerState<EditBatchSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  final List<String> _selectedTutorIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    _nameCtrl = TextEditingController(text: widget.batch.name);
    _selectedTutorIds.addAll(widget.batch.tutorIds);
    super.initState();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(batchManagementProvider.notifier).updateBatch(
        batchId: widget.batch.id,
        name: _nameCtrl.text.trim(),
        tutorIds: _selectedTutorIds,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tutorsState = ref.watch(tutorManagementProvider);
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      padding: EdgeInsets.fromLTRB(28, 20, 28, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 24),
              Text('Edit Batch', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Batch Name', prefixIcon: Icon(Icons.layers_outlined)),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              tutorsState.when(
                data: (tutors) {
                  if (tutors.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assign Tutors', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tutors.map((t) {
                          final isSelected = _selectedTutorIds.contains(t.id);
                          return FilterChip(
                            label: Text(t.name, style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : const Color(0xFF0F172A))),
                            selected: isSelected,
                            onSelected: (v) {
                              setState(() {
                                if (v) _selectedTutorIds.add(t.id);
                                else _selectedTutorIds.remove(t.id);
                              });
                            },
                            selectedColor: const Color(0xFF4F46E5),
                            checkmarkColor: Colors.white,
                            backgroundColor: const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12), 
                              side: BorderSide(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0), width: 1.5)
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                child: Text(_isLoading ? 'SAVING...' : 'SAVE CHANGES'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
