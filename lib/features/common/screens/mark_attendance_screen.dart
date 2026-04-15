import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/attendance_marking_provider.dart';
import '../../admin/providers/student_management_provider.dart';
import '../../tutor/providers/tutor_dashboard_provider.dart';

class MarkAttendanceScreen extends ConsumerStatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  ConsumerState<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends ConsumerState<MarkAttendanceScreen> {
  String? _selectedBatchId;
  DateTime _selectedDate = DateTime.now();
  Map<String, String> _attendanceMap = {}; 
  bool _isSaving = false;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isStaffOrAdmin = user?.role == 'admin' || user?.role == 'staff';
    
    final batchesState = isStaffOrAdmin 
        ? ref.watch(adminBatchesProvider) 
        : ref.watch(tutorDashboardProvider).when(
            data: (stats) => AsyncValue.data(stats.batches),
            loading: () => const AsyncValue.loading(),
            error: (e, st) => AsyncValue.error(e, st),
          );

    final studentsState = ref.watch(attendanceMarkingProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Student Attendance'),
      ),
      body: Column(
        children: [
          _buildSelectionHeader(batchesState),
          if (_selectedBatchId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search name...',
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
          const Divider(),
          Expanded(
            child: (_selectedBatchId == null)
                ? _buildInitialEmptyState()
                : studentsState.when(
                    data: (allStudents) {
                      final students = allStudents.where((s) => (s.studentName ?? '').toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                      if (students.isEmpty) return Center(child: Text(_searchQuery.isEmpty ? 'No records.' : 'No matches found.'));
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          final status = _attendanceMap[student.id] ?? 'absent';
                          return _buildStudentTile(student, status);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: (_selectedBatchId != null)
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: SafeArea(
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveAttendance,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Attendance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSelectionHeader(AsyncValue<dynamic> batchesState) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          batchesState.when(
            data: (batches) => DropdownButtonFormField<String>(
              initialValue: _selectedBatchId,
              decoration: const InputDecoration(labelText: 'Select Batch', prefixIcon: Icon(Icons.layers_rounded)),
              items: (batches as List).map((b) => DropdownMenuItem<String>(value: b.id.toString(), child: Text(b.name.toString()))).toList(),
              onChanged: (v) {
                setState(() {
                  _selectedBatchId = v;
                  _attendanceMap = {}; // Reset attendance map when batch changes
                });
                if (v != null) {
                  ref.read(attendanceMarkingProvider.notifier).fetchBatchStudents(v);
                  _loadAttendanceMap(); // Fetch existing attendance
                }
              },
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error loading batches: $e'),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
                _loadAttendanceMap();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 20),
                  const SizedBox(width: 12),
                  Text('Date: ${DateFormat('EEE, d MMM yyyy').format(_selectedDate)}'),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.layers_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Select a batch to mark attendance', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildStudentTile(dynamic student, String status) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: student.studentAvatarUrl != null ? CachedNetworkImageProvider(student.studentAvatarUrl!) : null,
              child: student.studentAvatarUrl == null ? Text(student.studentName?[0].toUpperCase() ?? 'S') : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.studentName ?? 'Student', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(student.studentEmail ?? '', style: TextStyle(fontSize: 12, color: theme.colorScheme.outline)),
                ],
              ),
            ),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'present', label: Text('P', style: TextStyle(fontSize: 12))),
                ButtonSegment(value: 'absent', label: Text('A', style: TextStyle(fontSize: 12))),
                ButtonSegment(value: 'late', label: Text('L', style: TextStyle(fontSize: 12))),
              ],
              selected: {status},
              onSelectionChanged: (set) {
                setState(() {
                   _attendanceMap[student.id] = set.first;
                });
              },
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: _getStatusColor(status).withOpacity(0.2),
                selectedForegroundColor: _getStatusColor(status),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    return switch (status) {
      'present' => Colors.green,
      'absent' => Colors.red,
      'late' => Colors.orange,
      _ => Colors.blue,
    };
  }

  Future<void> _loadAttendanceMap() async {
    final map = await ref.read(attendanceMarkingProvider.notifier).getExistingAttendance(
      batchId: _selectedBatchId,
      date: _selectedDate,
      isStaff: false,
    );
    if (mounted) {
      setState(() {
        _attendanceMap = map;
      });
    }
  }

  Future<void> _saveAttendance() async {
    final students = ref.read(attendanceMarkingProvider).value ?? [];
    if (_selectedBatchId == null) return;
    
    // Fill in default 'absent' for any not marked
    for (var s in students) {
      _attendanceMap.putIfAbsent(s.id, () => 'absent');
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(attendanceMarkingProvider.notifier).markAttendance(
        batchId: _selectedBatchId!,
        date: _selectedDate,
        statusMap: _attendanceMap,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance saved successfully!')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
