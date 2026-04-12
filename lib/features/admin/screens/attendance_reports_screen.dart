import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../widgets/common_widgets.dart';
import '../providers/student_management_provider.dart';

class AttendanceReportsScreen extends ConsumerWidget {
  const AttendanceReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsState = ref.watch(studentManagementProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Reports')),
      body: studentsState.when(
        data: (students) {
          if (students.isEmpty) {
            return const Center(
              child: EmptyState(
                icon: Icons.fact_check_outlined,
                title: 'No attendance data',
                subtitle: 'Invite students to start tracking attendance.',
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(student.studentName ?? "Unknown Student", style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(student.batchName ?? "Unassigned Batch"),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text('Coming Soon', style: TextStyle(fontSize: 12, color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
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
}
