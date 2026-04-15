import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/staff_attendance_report_provider.dart';

class StaffAttendanceReportScreen extends ConsumerStatefulWidget {
  const StaffAttendanceReportScreen({super.key});

  @override
  ConsumerState<StaffAttendanceReportScreen> createState() => _StaffAttendanceReportScreenState();
}

class _StaffAttendanceReportScreenState extends ConsumerState<StaffAttendanceReportScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(staffAttendanceReportProvider);
    final searchQuery = ref.watch(staffReportSearchProvider).toLowerCase();
    final roleFilter = ref.watch(staffReportRoleFilterProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      appBar: AppBar(
        title: const Text('Staff & Tutor Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.refresh(staffAttendanceReportProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search & Filter Header ─────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => ref.read(staffReportSearchProvider.notifier).state = v,
                  decoration: InputDecoration(
                    hintText: 'Search by name...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(label: 'All Roles', value: 'all', selectedValue: roleFilter, onSelected: (v) => ref.read(staffReportRoleFilterProvider.notifier).state = v),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Tutors Only', value: 'tutor', selectedValue: roleFilter, onSelected: (v) => ref.read(staffReportRoleFilterProvider.notifier).state = v),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Admin Staff', value: 'staff', selectedValue: roleFilter, onSelected: (v) => ref.read(staffReportRoleFilterProvider.notifier).state = v),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── List Area ──────────────────────────────────────────────────
          Expanded(
            child: reportState.when(
              data: (reports) {
                final filterStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
                final filtered = reports.where((r) {
                  final matchesSearch = r.personName.toLowerCase().contains(searchQuery);
                  final matchesRole = roleFilter == 'all' || r.role == roleFilter;
                  final matchesDate = r.date == filterStr;
                  return matchesSearch && matchesRole && matchesDate;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text('No records match your search', style: GoogleFonts.inter(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final report = filtered[index];
                    return _ReportCard(report: report, theme: theme);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selectedValue;
  final Function(String) onSelected;

  const _FilterChip({required this.label, required this.value, required this.selectedValue, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selectedValue;
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : const Color(0xFF64748B))),
      selected: isSelected,
      onSelected: (s) => onSelected(value),
      selectedColor: const Color(0xFF0284C7),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0))),
      showCheckmark: false,
    );
  }
}

class _ReportCard extends StatelessWidget {
  final StaffAttendanceReport report;
  final ThemeData theme;

  const _ReportCard({required this.report, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: report.role == 'tutor' ? const Color(0xFFEEF2FF) : const Color(0xFFF0FDF4),
                  child: Text(report.personName[0], style: TextStyle(color: report.role == 'tutor' ? const Color(0xFF0284C7) : const Color(0xFF10B981), fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(report.personName, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: report.role == 'tutor' ? const Color(0xFF0284C7).withOpacity(0.1) : Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(report.role.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: report.role == 'tutor' ? const Color(0xFF0284C7) : Colors.green)),
                          ),
                          const SizedBox(width: 8),
                          Text(DateFormat('EEE, d MMM').format(DateTime.parse(report.date)), style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                        ],
                      ),
                    ],
                  ),
                ),
                if (report.durationMinutes != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${(report.durationMinutes! / 60).toStringAsFixed(1)} hrs', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF0F172A))),
                      Text('Work Time', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B))),
                    ],
                  )
                else
                  const _ActiveBadge(),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _TimeInfo(label: 'PUNCH IN', time: report.punchIn, icon: Icons.login_rounded, color: Colors.blue),
                const Spacer(),
                const Icon(Icons.arrow_forward_rounded, color: Color(0xFFE2E8F0), size: 16),
                const Spacer(),
                _TimeInfo(label: 'PUNCH OUT', time: report.punchOut, icon: Icons.logout_rounded, color: Colors.orange, isRight: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBBF7D0))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('ACTIVE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF166534))),
        ],
      ),
    );
  }
}

class _TimeInfo extends StatelessWidget {
  final String label;
  final DateTime? time;
  final IconData icon;
  final Color color;
  final bool isRight;

  const _TimeInfo({required this.label, required this.time, required this.icon, required this.color, this.isRight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isRight) Icon(icon, size: 12, color: color),
            if (!isRight) const SizedBox(width: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8))),
            if (isRight) const SizedBox(width: 4),
            if (isRight) Icon(icon, size: 12, color: color),
          ],
        ),
        const SizedBox(height: 4),
        Text(time != null ? DateFormat('h:mm a').format(time!) : '--:--', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
      ],
    );
  }
}
