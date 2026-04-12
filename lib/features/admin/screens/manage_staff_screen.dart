import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../widgets/common_widgets.dart';
import '../../common/providers/attendance_summary_provider.dart';
import '../../../models/user_model.dart';
import '../providers/staff_management_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ManageStaffScreen extends ConsumerStatefulWidget {
  const ManageStaffScreen({super.key});

  @override
  ConsumerState<ManageStaffScreen> createState() => _ManageStaffScreenState();
}

class _ManageStaffScreenState extends ConsumerState<ManageStaffScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staffState = ref.watch(staffManagementProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: const Text('Manage Staff & Tutors'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by name, email or username...',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStaffSheet(context),
        icon: const Icon(Icons.add_moderator_rounded),
        label: const Text('Add Staff'),
      ),
      body: staffState.when(
        data: (staff) {
          final filtered = staff.where((s) {
            final name = (s.name).toLowerCase();
            final email = (s.email).toLowerCase();
            final username = (s.username ?? '').toLowerCase();
            return name.contains(_searchQuery) || email.contains(_searchQuery) || username.contains(_searchQuery);
          }).toList();

          if (staff.isEmpty) {
             return const EmptyState(
                icon: Icons.badge_outlined, 
                title: 'No staff members', 
                subtitle: 'Invite tutors and support staff to manage the institute.'
             );
          }

          if (filtered.isEmpty && _searchQuery.isNotEmpty) {
            return const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No matches',
              subtitle: 'Try a different name or role.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(staffManagementProvider.notifier).fetchStaff(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final member = filtered[index];
                return _StaffListItem(member: member);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.read(staffManagementProvider.notifier).fetchStaff(),
        ),
      ),
    );
  }

  void _showAddStaffSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => const AddStaffSheet(),
    );
  }
}

class _StaffListItem extends ConsumerWidget {
  final UserModel member;
  const _StaffListItem({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isTutor = member.role == 'tutor';
    final roleColor = isTutor ? const Color(0xFF0EA5E9) : const Color(0xFFF59E0B);

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
        child: InkWell(
          onTap: () => _showProfile(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFFF1F5F9),
                    backgroundImage: member.avatarUrl != null ? CachedNetworkImageProvider(member.avatarUrl!) : null,
                    child: member.avatarUrl == null ? Text(member.name[0].toUpperCase(), 
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF4F46E5))) : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.name, 
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              member.roleLabel.toUpperCase(), 
                              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: roleColor, letterSpacing: 0.5)
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              member.username ?? member.email, 
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFFFEF2F2)),
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Remove Staff?'),
      content: Text('This will delete ${member.name} and their access. This action cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (ok == true) {
      await ref.read(staffManagementProvider.notifier).deleteStaff(member);
    }
  }

  void _showProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StaffProfileSheet(staff: member),
    );
  }
}

class StaffProfileSheet extends ConsumerWidget {
  final UserModel staff;
  const StaffProfileSheet({super.key, required this.staff});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final attState = ref.watch(weeklyStaffAttendanceProvider(staff.id));
    final isTutor = staff.role == 'tutor';
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 3),
                ),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFFF1F5F9),
                  backgroundImage: staff.avatarUrl != null ? CachedNetworkImageProvider(staff.avatarUrl!) : null,
                  child: staff.avatarUrl == null ? const Icon(Icons.person, size: 30, color: Color(0xFF4F46E5)) : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(staff.name, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text(staff.email, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone_android_rounded, size: 12, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(staff.phone ?? "No phone set", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
              ),
              RoleBadge(role: staff.role),
            ],
          ),
          const SizedBox(height: 32),
          _buildPulseSection(context, attState, theme),
        ],
      ),
    );
  }

  Widget _buildPulseSection(BuildContext context, AsyncValue<Map<String, int>> attState, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.insights_rounded, size: 14, color: Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text('WEEKLY PULSE (LAST 7 DAYS)', style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF64748B), letterSpacing: 0.8
            )),
            const SizedBox(width: 12),
            const Expanded(child: Divider(color: Color(0xFFF1F5F9))),
          ],
        ),
        const SizedBox(height: 16),
        attState.when(
          data: (stats) {
             final present = stats['present'] ?? 0;
             final absent = stats['absent'] ?? 0;
             final lateCount = stats['late'] ?? 0;
             final total = present + absent + lateCount;
             
             return Column(
               children: [
                 Container(
                   padding: const EdgeInsets.all(20),
                   decoration: BoxDecoration(
                     gradient: const LinearGradient(
                       colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                       begin: Alignment.topLeft, end: Alignment.bottomRight,
                     ),
                     borderRadius: BorderRadius.circular(24),
                     boxShadow: [
                       BoxShadow(
                         color: const Color(0xFF0EA5E9).withOpacity(0.3),
                         blurRadius: 15,
                         offset: const Offset(0, 6),
                       ),
                     ],
                   ),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceAround,
                     children: [
                       _PulseStat(label: 'Present', value: present.toString(), color: Colors.white),
                       _PulseStat(label: 'Late', value: lateCount.toString(), color: Colors.white.withOpacity(0.8)),
                       _PulseStat(label: 'Absent', value: absent.toString(), color: Colors.white.withOpacity(0.6)),
                     ],
                   ),
                 ),
                 const SizedBox(height: 12),
                 if (total > 0)
                   Text(
                     'Overall presence: ${((present / total) * 100).toInt()}% based on $total entries',
                     style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                   ),
               ],
             );
          },
          loading: () => const ShimmerBox(height: 80, radius: 24),
          error: (e, _) => Text('Attendance details not available', style: GoogleFonts.inter(color: Colors.red, fontSize: 13)),
        ),
      ],
    );
  }
}

class _PulseStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _PulseStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

class AddStaffSheet extends ConsumerStatefulWidget {
  const AddStaffSheet({super.key});
  @override
  ConsumerState<AddStaffSheet> createState() => _AddStaffSheetState();
}

class _AddStaffSheetState extends ConsumerState<AddStaffSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _unameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _role = 'tutor';
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(staffManagementProvider.notifier).addStaff(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        username: _unameCtrl.text.trim(),
        password: _passCtrl.text,
        role: _role,
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
              Text('Add Staff Member', 
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
              const SizedBox(height: 8),
              Text('Tutors can mark attendance, staff can manage recordings.', 
                  style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))),
              const SizedBox(height: 32),
              
              TextFormField(
                controller: _nameCtrl, 
                style: GoogleFonts.inter(fontSize: 14),
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.badge_outlined)),
                validator: (v) => (v == null || v.isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unameCtrl, 
                style: GoogleFonts.inter(fontSize: 14),
                decoration: const InputDecoration(labelText: 'Login Username', prefixIcon: Icon(Icons.alternate_email_rounded)),
                validator: (v) => (v == null || v.isEmpty) ? 'Enter a username' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl, 
                style: GoogleFonts.inter(fontSize: 14),
                decoration: const InputDecoration(labelText: 'Email Address (Optional)', prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passCtrl, 
                style: GoogleFonts.inter(fontSize: 14),
                decoration: const InputDecoration(labelText: 'Login Password', prefixIcon: Icon(Icons.lock_outline_rounded)),
                obscureText: true,
                validator: (v) => (v == null || v.isEmpty) ? 'Enter a password' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _role,
                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                decoration: const InputDecoration(labelText: 'Assigned Role', prefixIcon: Icon(Icons.verified_user_outlined)),
                items: [
                  const DropdownMenuItem(value: 'tutor', child: Text('Teacher / Tutor')),
                  const DropdownMenuItem(value: 'staff', child: Text('Admin / Support Staff')),
                ],
                onChanged: (v) => setState(() => _role = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl, 
                style: GoogleFonts.inter(fontSize: 14),
                keyboardType: TextInputType.phone, 
                decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_android_rounded))
              ),
              
              const SizedBox(height: 40),
              FilledButton(
                onPressed: _isLoading ? null : _submit, 
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(_isLoading ? 'CREATING...' : 'CREATE STAFF ACCOUNT'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
