import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/tutor_attendance_report_provider.dart';

class TutorAttendanceReportScreen extends ConsumerWidget {
  const TutorAttendanceReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportState = ref.watch(tutorAttendanceReportProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutor Punch Logs'),
      ),
      body: reportState.when(
        data: (reports) {
          if (reports.isEmpty) {
            return const Center(child: Text('No punch records found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(child: Text(report.tutorName[0])),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(report.tutorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(DateFormat('EEE, d MMM yyyy').format(DateTime.parse(report.date)), style: TextStyle(fontSize: 12, color: theme.colorScheme.outline)),
                              ],
                            ),
                          ),
                          if (report.durationMinutes != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(20)),
                              child: Text('${(report.durationMinutes! / 60).toStringAsFixed(1)} hrs', 
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer)),
                            )
                          else
                            const Badge(label: Text('ACTIVE')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _timeInfo('IN', report.punchIn, theme),
                          _timeInfo('OUT', report.punchOut, theme),
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

  Widget _timeInfo(String label, DateTime? dt, ThemeData theme) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.outline)),
        Text(dt != null ? DateFormat('h:mm a').format(dt) : '--:--', style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
