import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/student_management_provider.dart';
import '../../common/providers/attendance_summary_provider.dart';

final dailyAttendanceProvider = FutureProvider.family<Map<String, String>, DateTime>((ref, date) async {
  final supabase = Supabase.instance.client;
  final dateStr = DateFormat('yyyy-MM-dd').format(date);
  final res = await supabase.from('attendance').select('student_id, status').eq('date', dateStr);
  final map = <String, String>{};
  for (var row in res) {
    map[row['student_id'] as String] = row['status'] as String;
  }
  return map;
});

class AttendanceReportsScreen extends ConsumerStatefulWidget {
  const AttendanceReportsScreen({super.key});

  @override
  ConsumerState<AttendanceReportsScreen> createState() => _AttendanceReportsScreenState();
}

class _AttendanceReportsScreenState extends ConsumerState<AttendanceReportsScreen> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      appBar: AppBar(
        title: const Text('Student Progress Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () => setState(() => _selectedDate = null),
            ),
        ],
      ),
      body: _StudentReportView(filterDate: _selectedDate),
    );
  }
}

class _StudentReportView extends ConsumerStatefulWidget {
  final DateTime? filterDate;
  const _StudentReportView({this.filterDate});

  @override
  ConsumerState<_StudentReportView> createState() => _StudentReportViewState();
}

class _StudentReportViewState extends ConsumerState<_StudentReportView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final studentsState = ref.watch(studentManagementProvider);
    
    return studentsState.when(
      data: (allStudents) {
        final students = allStudents.where((s) => (s.studentName ?? '').toLowerCase().contains(_searchQuery)).toList();
        
        return Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search students by name...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ),
            if (widget.filterDate != null)
              Container(
                width: double.infinity,
                color: const Color(0xFF0284C7).withOpacity(0.1),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                child: Text('Showing records for ${DateFormat('MMM d, yyyy').format(widget.filterDate!)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
              ),
            Expanded(
              child: students.isEmpty 
                  ? const Center(child: Text('No students match search'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        
                        if (widget.filterDate != null) {
                          final dailyMapState = ref.watch(dailyAttendanceProvider(widget.filterDate!));
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: CircleAvatar(backgroundColor: const Color(0xFFEEF2FF), child: Text((student.studentName ?? "S")[0].toUpperCase(), style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold))),
                              title: Text(student.studentName ?? "Unknown", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                              subtitle: Text(student.batchName ?? "Unassigned", style: const TextStyle(fontSize: 11)),
                              trailing: dailyMapState.when(
                                data: (map) {
                                  final status = map[student.id];
                                  Color c = Colors.grey;
                                  IconData ic = Icons.help_outline;
                                  String lbl = 'Not Marked';
                                  if (status == 'present') { c = Colors.green; ic = Icons.check_circle_rounded; lbl = 'Present'; }
                                  else if (status == 'absent') { c = Colors.red; ic = Icons.cancel_rounded; lbl = 'Absent'; }
                                  else if (status == 'late') { c = Colors.orange; ic = Icons.timer_rounded; lbl = 'Late'; }
                                  return Chip(
                                    label: Text(lbl, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.bold)),
                                    avatar: Icon(ic, color: c, size: 16),
                                    backgroundColor: c.withOpacity(0.1),
                                    side: BorderSide.none,
                                  );
                                },
                                loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                                error: (_, __) => const Icon(Icons.error_outline),
                              ),
                            ),
                          );
                        }

                        final stats = ref.watch(weeklyAttendanceProvider(student.id));
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: ExpansionTile(
                            shape: const RoundedRectangleBorder(side: BorderSide.none),
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFEEF2FF),
                              child: Text((student.studentName ?? "S")[0].toUpperCase(), style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                            ),
                            title: Text(student.studentName ?? "Unknown", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                            subtitle: Text(student.batchName ?? "Unassigned", style: const TextStyle(fontSize: 11)),
                            children: [
                              stats.when(
                                data: (s) {
                                  final perc = s['total'] == 0 ? 0 : (s['present']! / s['total']! * 100).toInt();
                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                    child: Column(
                                      children: [
                                        const Divider(),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            _StatBox(label: 'Present', value: '${s['present']}', color: Colors.green),
                                            _StatBox(label: 'Absent', value: '${s['absent']}', color: Colors.red),
                                            _StatBox(label: 'Health', value: '$perc%', color: Colors.blue),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                loading: () => const LinearProgressIndicator(),
                                error: (_, __) => const Text('Error loading stats'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
