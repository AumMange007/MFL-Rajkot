import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../widgets/common_widgets.dart';
import '../../../models/batch_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/batch_management_provider.dart';
import '../providers/tutor_management_provider.dart';

const _kBg     = Color(0xFFF0F6FF);
const _kAccent = Color(0xFF0284C7);
const _kAccent2= Color(0xFF0891B2);

class ManageBatchesScreen extends ConsumerWidget {
  const ManageBatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user        = ref.watch(currentUserProvider);
    final batchesState = ref.watch(batchManagementProvider);
    final canManage   = user?.role == 'admin' || user?.role == 'staff';

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          // ── Premium SliverAppBar ───────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: _kAccent,
            actions: [
              IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: () => ref.refresh(batchManagementProvider)),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_kAccent, _kAccent2]),
                ),
                padding: const EdgeInsets.fromLTRB(24, 90, 24, 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.layers_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Manage Batches', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                        batchesState.maybeWhen(
                          data: (list) => Text('${list.length} active batches', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Batch List ────────────────────────────────────
          SliverToBoxAdapter(
            child: batchesState.when(
              data: (allBatches) {
                final batches = user?.role == 'tutor' 
                    ? allBatches.where((b) => b.tutorIds.contains(user!.id)).toList()
                    : allBatches;

                if (batches.isEmpty) {
                  return const Padding(padding: EdgeInsets.only(top: 80), child: EmptyState(icon: Icons.layers_clear_outlined, title: 'No batches found', subtitle: 'Nothing to display here.'));
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(batchManagementProvider),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: batches.length,
                    itemBuilder: (context, index) {
                      return _BatchCard(batch: batches[index], canEdit: canManage);
                    },
                  ),
                );
              },
              loading: () => const Padding(padding: EdgeInsets.only(top: 100), child: Center(child: CircularProgressIndicator(color: _kAccent))),
              error: (err, _) => ErrorState(message: err.toString(), onRetry: () => ref.refresh(batchManagementProvider)),
            ),
          ),
        ],
      ),
      floatingActionButton: canManage ? FloatingActionButton.extended(
        onPressed: () => _showAddBatchSheet(context, ref),
        backgroundColor: _kAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Add Batch', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ) : null,
    );
  }

  void _showAddBatchSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddBatchSheet(),
    );
  }
}

// ─── Batch Card ───────────────────────────────────────────────────────────────
class _BatchCard extends ConsumerWidget {
  final BatchModel batch;
  final bool canEdit;
  const _BatchCard({required this.batch, required this.canEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _kAccent.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.layers_rounded, color: _kAccent, size: 22),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(batch.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 12, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          batch.tutorNames.isEmpty ? 'No tutors assigned' : batch.tutorNames.join(', '),
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            if (canEdit) Row(
              children: [
                _ActionBtn(icon: Icons.edit_rounded, color: _kAccent, onTap: () => _showEditBatchSheet(context, ref, batch)),
                const SizedBox(width: 8),
                _ActionBtn(icon: Icons.delete_outline_rounded, color: const Color(0xFFEF4444), onTap: () => _confirmDelete(context, ref, batch)),
              ],
            ) else const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  void _showEditBatchSheet(BuildContext context, WidgetRef ref, BatchModel batch) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditBatchSheet(batch: batch),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, BatchModel batch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Batch?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Remove "${batch.name}"? This action cannot be undone.', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(batchManagementProvider.notifier).deleteBatch(batch);
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
      }
    }
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 18),
    ),
  );
}

// ─── Shared Sheet Widgets ────────────────────────────────────────────────────
Widget _sheetHandle() => Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)));

Widget _tutorPicker({
  required AsyncValue<List<dynamic>> tutorsState,
  required List<String> selectedIds,
  required TextEditingController searchCtrl,
  required String searchQuery,
  required void Function(String) onSearch,
  required void Function(String, bool) onToggle,
  required VoidCallback onClear,
}) {
  return tutorsState.when(
    data: (tutors) {
      if (tutors.isEmpty) return const SizedBox.shrink();
      final filtered = tutors.where((t) => t.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Assign Tutors (${selectedIds.length} selected)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
              if (selectedIds.isNotEmpty)
                TextButton(onPressed: onClear, child: Text('Clear All', style: GoogleFonts.inter(fontSize: 11, color: _kAccent))),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: searchCtrl,
            onChanged: onSearch,
            style: GoogleFonts.inter(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Find tutor…',
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              isDense: true,
              filled: true, fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(color: const Color(0xFFF0F6FF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: filtered.isEmpty
                ? const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No tutors found', style: TextStyle(fontSize: 12, color: Colors.grey))))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 8, runSpacing: 8,
                      children: filtered.map((t) {
                        final isSelected = selectedIds.contains(t.id);
                        return FilterChip(
                          label: Text(t.name, style: GoogleFonts.inter(fontSize: 12, color: isSelected ? Colors.white : const Color(0xFF0F172A))),
                          selected: isSelected,
                          onSelected: (v) => onToggle(t.id, v),
                          selectedColor: _kAccent,
                          checkmarkColor: Colors.white,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isSelected ? _kAccent : const Color(0xFFE2E8F0))),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      );
    },
    loading: () => const LinearProgressIndicator(),
    error: (_, __) => const Text('Error loading tutors', style: TextStyle(color: Colors.red, fontSize: 13)),
  );
}

// ─── Add Batch Sheet ─────────────────────────────────────────────────────────
class AddBatchSheet extends ConsumerStatefulWidget {
  const AddBatchSheet({super.key});
  @override
  ConsumerState<AddBatchSheet> createState() => _AddBatchSheetState();
}

class _AddBatchSheetState extends ConsumerState<AddBatchSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _searchCtrl = TextEditingController();
  final List<String> _selectedTutorIds = [];
  bool _isLoading = false;
  String _search = '';

  @override
  void dispose() { _nameCtrl.dispose(); _searchCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(batchManagementProvider.notifier).addBatch(name: _nameCtrl.text.trim(), tutorIds: _selectedTutorIds);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tutorsState = ref.watch(tutorManagementProvider);
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: _sheetHandle()),
              const SizedBox(height: 20),
              Row(children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _kAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.layers_rounded, color: _kAccent, size: 20)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Create New Batch', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                  Text('Assign tutors and organise students', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                ]),
              ]),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameCtrl,
                style: GoogleFonts.inter(fontSize: 14),
                validator: (v) => (v == null || v.isEmpty) ? 'Batch name is required' : null,
                decoration: InputDecoration(
                  labelText: 'Batch Name (e.g. A1, Beginner)',
                  prefixIcon: const Icon(Icons.layers_outlined),
                  filled: true, fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 20),
              _tutorPicker(
                tutorsState: tutorsState,
                selectedIds: _selectedTutorIds,
                searchCtrl: _searchCtrl,
                searchQuery: _search,
                onSearch: (v) => setState(() => _search = v),
                onToggle: (id, v) => setState(() { v ? _selectedTutorIds.add(id) : _selectedTutorIds.remove(id); }),
                onClear: () => setState(() => _selectedTutorIds.clear()),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(backgroundColor: _kAccent, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Create Batch', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Edit Batch Sheet ─────────────────────────────────────────────────────────
class EditBatchSheet extends ConsumerStatefulWidget {
  final BatchModel batch;
  const EditBatchSheet({super.key, required this.batch});
  @override
  ConsumerState<EditBatchSheet> createState() => _EditBatchSheetState();
}

class _EditBatchSheetState extends ConsumerState<EditBatchSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  final _searchCtrl = TextEditingController();
  final List<String> _selectedTutorIds = [];
  bool _isLoading = false;
  String _search = '';

  @override
  void initState() {
    _nameCtrl = TextEditingController(text: widget.batch.name);
    _selectedTutorIds.addAll(widget.batch.tutorIds);
    super.initState();
  }

  @override
  void dispose() { _nameCtrl.dispose(); _searchCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(batchManagementProvider.notifier).updateBatch(batchId: widget.batch.id, name: _nameCtrl.text.trim(), tutorIds: _selectedTutorIds);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tutorsState = ref.watch(tutorManagementProvider);
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: _sheetHandle()),
              const SizedBox(height: 20),
              Text('Edit Batch', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
              Text('Update batch name and tutors', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameCtrl,
                style: GoogleFonts.inter(fontSize: 14),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                decoration: InputDecoration(
                  labelText: 'Batch Name',
                  prefixIcon: const Icon(Icons.layers_outlined),
                  filled: true, fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 20),
              _tutorPicker(
                tutorsState: tutorsState,
                selectedIds: _selectedTutorIds,
                searchCtrl: _searchCtrl,
                searchQuery: _search,
                onSearch: (v) => setState(() => _search = v),
                onToggle: (id, v) => setState(() { v ? _selectedTutorIds.add(id) : _selectedTutorIds.remove(id); }),
                onClear: () => setState(() => _selectedTutorIds.clear()),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(backgroundColor: _kAccent, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Save Changes', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
