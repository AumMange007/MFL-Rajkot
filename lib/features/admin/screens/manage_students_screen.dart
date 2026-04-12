import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../widgets/common_widgets.dart';
import '../../../models/student_model.dart';
import '../../../models/batch_model.dart';
import '../providers/student_management_provider.dart';
import '../../common/providers/profile_photo_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../common/providers/attendance_summary_provider.dart';

class ManageStudentsScreen extends ConsumerStatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  ConsumerState<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends ConsumerState<ManageStudentsScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsState = ref.watch(studentManagementProvider);
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final hasAccess = user?.role == 'admin' || user?.role == 'staff';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: const Text('Manage Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(studentManagementProvider.notifier).fetchStudents(),
          ),
        ],
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
      floatingActionButton: hasAccess ? FloatingActionButton.extended(
        onPressed: () => _showAddStudentSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Student'),
      ) : null,
      body: studentsState.when(
        data: (students) {
          final filtered = students.where((s) {
            final name = (s.studentName ?? '').toLowerCase();
            final email = (s.studentEmail ?? '').toLowerCase();
            final username = (s.studentUsername ?? '').toLowerCase();
            return name.contains(_searchQuery) || email.contains(_searchQuery) || username.contains(_searchQuery);
          }).toList();

          if (students.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline_rounded,
              title: 'No students found',
              subtitle: 'Invite students to your institute to get started.',
            );
          }
          
          if (filtered.isEmpty && _searchQuery.isNotEmpty) {
            return const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No matches',
              subtitle: 'Try a different name or email.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(studentManagementProvider.notifier).fetchStudents(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final student = filtered[index];
                return _StudentListItem(student: student);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
          message: err.toString(),
          onRetry: () => ref.read(studentManagementProvider.notifier).fetchStudents(),
        ),
      ),
    );
  }

  void _showAddStudentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => const AddStudentSheet(),
    );
  }
}

class _StudentListItem extends ConsumerWidget {
  final StudentModel student;
  const _StudentListItem({required this.student});

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
        child: InkWell(
          onTap: () => _showProfileSheet(context, ref),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Hero(
                  tag: 'avatar_${student.id}',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFFF1F5F9),
                      backgroundImage: student.studentAvatarUrl != null && student.studentAvatarUrl!.isNotEmpty 
                          ? CachedNetworkImageProvider(student.studentAvatarUrl!) 
                          : null,
                      child: student.studentAvatarUrl == null || student.studentAvatarUrl!.isEmpty
                        ? Text(
                            (student.studentName ?? "S")[0].toUpperCase(),
                            style: GoogleFonts.inter(fontSize: 18, color: const Color(0xFF4F46E5), fontWeight: FontWeight.w700),
                          )
                        : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.studentName ?? "Unknown", 
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.alternate_email_rounded, size: 12, color: theme.colorScheme.primary.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Text(
                            student.studentUsername ?? "No username", 
                            style: GoogleFonts.inter(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _miniBadge(theme, student.batchName ?? "No Batch", const Color(0xFF4F46E5), Icons.layers_rounded),
                          _miniBadge(theme, 'Lvl: ${student.level}', const Color(0xFF0EA5E9), Icons.signal_cellular_alt_rounded),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniBadge(ThemeData theme, String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            text, 
            style: GoogleFonts.inter(fontSize: 10, color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  void _showProfileSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ManageStudentProfileSheet(student: student),
    );
  }
}

class ManageStudentProfileSheet extends ConsumerStatefulWidget {
  final StudentModel student;
  const ManageStudentProfileSheet({super.key, required this.student});

  @override
  ConsumerState<ManageStudentProfileSheet> createState() => _ManageStudentProfileSheetState();
}

class _ManageStudentProfileSheetState extends ConsumerState<ManageStudentProfileSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _vocabChapCtrl;
  late TextEditingController _gramChapCtrl;
  late TextEditingController _kbChapCtrl;
  late TextEditingController _ubChapCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _parentMobileCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _dobCtrl;
  late String _level;
  late String _language;
  late String? _batchId;
  bool _isLoading = false;

  @override
  void initState() {
    _nameCtrl = TextEditingController(text: widget.student.studentName);
    _vocabChapCtrl = TextEditingController(text: widget.student.vocabChap);
    _gramChapCtrl = TextEditingController(text: widget.student.grammarChap);
    _kbChapCtrl = TextEditingController(text: widget.student.kbChap);
    _ubChapCtrl = TextEditingController(text: widget.student.ubChap);
    _mobileCtrl = TextEditingController(text: widget.student.mobile);
    _parentMobileCtrl = TextEditingController(text: widget.student.parentMobile);
    _addressCtrl = TextEditingController(text: widget.student.address);
    _dobCtrl = TextEditingController(text: widget.student.dateOfBirth);
    _level = widget.student.level ?? 'A1';
    _language = widget.student.language ?? 'German';
    _batchId = widget.student.batchId;
    super.initState();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _vocabChapCtrl.dispose();
    _gramChapCtrl.dispose();
    _kbChapCtrl.dispose();
    _ubChapCtrl.dispose();
    _mobileCtrl.dispose();
    _parentMobileCtrl.dispose();
    _addressCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(studentManagementProvider.notifier).updateStudentProfile(
        studentId: widget.student.id,
        name: _nameCtrl.text.trim(),
        batchId: _batchId ?? widget.student.batchId ?? '',
        level: _level,
        language: _language,
        vocabChap: _vocabChapCtrl.text.trim(),
        grammarChap: _gramChapCtrl.text.trim(),
        kbChap: _kbChapCtrl.text.trim(),
        ubChap: _ubChapCtrl.text.trim(),
        mobile: _mobileCtrl.text.trim(),
        parentMobile: _parentMobileCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        dob: _dobCtrl.text.trim(),
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student profile updated successfully!'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isAdmin = user?.role == 'admin';
    final theme = Theme.of(context);
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF1F5F9), width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0xFFF1F5F9),
                        backgroundImage: widget.student.studentAvatarUrl != null && widget.student.studentAvatarUrl!.isNotEmpty 
                            ? CachedNetworkImageProvider(widget.student.studentAvatarUrl!) 
                            : null,
                        child: widget.student.studentAvatarUrl == null || widget.student.studentAvatarUrl!.isEmpty
                          ? Text((widget.student.studentName ?? "S")[0].toUpperCase(), 
                              style: GoogleFonts.inter(fontSize: 24, color: const Color(0xFF4F46E5), fontWeight: FontWeight.w700))
                          : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: GestureDetector(
                        onTap: () => ref.read(profilePhotoProvider.notifier).uploadForUser(widget.student.userId),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.student.studentName ?? "Student", 
                          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      Text(widget.student.studentEmail ?? "No email", 
                          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
                    ],
                  ),
                ),
                if (isAdmin) 
                  IconButton.filledTonal(
                    onPressed: () => _confirmDelete(context, ref),
                    icon: const Icon(Icons.delete_outline_rounded, size: 22),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFEF2F2),
                      foregroundColor: const Color(0xFFEF4444),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            
            _buildWeeklyPulse(theme),
            
            const SizedBox(height: 32),
            _buildSectionDivider('BASIC INFORMATION', Icons.person_rounded),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _nameCtrl, 
              style: GoogleFonts.inter(fontSize: 14),
              decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.badge_outlined)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextFormField(
                  controller: _mobileCtrl, 
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: const InputDecoration(labelText: 'Mobile', prefixIcon: Icon(Icons.phone_android_rounded))
                )),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  controller: _dobCtrl, 
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: const InputDecoration(labelText: 'DOB', prefixIcon: Icon(Icons.cake_outlined))
                )),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressCtrl, 
              style: GoogleFonts.inter(fontSize: 14),
              decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_outlined))
            ),
            const SizedBox(height: 16),
            
            // NEW Batch Selection Dropdown
            Consumer(builder: (context, ref, _) {
               final batchesState = ref.watch(adminBatchesProvider);
               return batchesState.when(
                 data: (batches) => DropdownButtonFormField<String>(
                   value: _batchId,
                   style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                   decoration: const InputDecoration(labelText: 'Assign Batch', prefixIcon: Icon(Icons.layers_outlined)),
                   items: batches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name, style: GoogleFonts.inter(fontSize: 14)))).toList(),
                   onChanged: (v) => setState(() => _batchId = v),
                 ),
                 loading: () => const LinearProgressIndicator(),
                 error: (e, _) => Text('Error loading batches: $e', style: const TextStyle(color: Colors.red, fontSize: 12)),
               );
            }),
            
            const SizedBox(height: 32),
            _buildSectionDivider('ACADEMIC PROGRESS', Icons.auto_stories_rounded),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(child: DropdownButtonFormField<String>(
                    value: _level,
                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                    decoration: const InputDecoration(labelText: 'Course Level'),
                    items: ['A1', 'A2', 'B1', 'B2', 'C1'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                    onChanged: (v) => setState(() => _level = v!),
                )),
                const SizedBox(width: 16),
                Expanded(child: TextFormField(
                  controller: TextEditingController(text: _language),
                  onChanged: (v) => _language = v,
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: const InputDecoration(labelText: 'Language'),
                )),
              ],
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _miniChapterInput('Vocab', _vocabChapCtrl)),
                      const SizedBox(width: 12),
                      Expanded(child: _miniChapterInput('Grammar', _gramChapCtrl)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _miniChapterInput('Kursbuch', _kbChapCtrl)),
                      const SizedBox(width: 12),
                      Expanded(child: _miniChapterInput('Workbook', _ubChapCtrl)),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: _isLoading ? null : _save, 
              icon: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Icon(Icons.check_circle_rounded, size: 18),
              label: Text(_isLoading ? 'SAVING...' : 'SAVE CHANGES'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyPulse(ThemeData theme) {
    final weekly = ref.watch(weeklyAttendanceProvider(widget.student.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionDivider('ATTENDANCE PULSE', Icons.insights_rounded),
        const SizedBox(height: 16),
        weekly.when(
          data: (stats) {
            final present = stats['present'] ?? 0;
            final total = stats['total'] ?? 0;
            final percent = total > 0 ? (present / total) : 0.0;
            
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 60, width: 60,
                        child: CircularProgressIndicator(
                          value: percent,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 6,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Text('${(percent * 100).toInt()}%', 
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recent Attendance', 
                            style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('$present days present', 
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('Out of $total days marked this week', 
                            style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const ShimmerBox(height: 80, radius: 24),
          error: (e, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(16)),
            child: Text('Performance data unavailable', style: GoogleFonts.inter(color: const Color(0xFFEF4444), fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionDivider(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF64748B), letterSpacing: 0.8
        )),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: Color(0xFFF1F5F9))),
      ],
    );
  }

  Widget _miniChapterInput(String label, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: GoogleFonts.inter(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student?'),
        content: const Text('Are you sure you want to delete this student and all their data? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(studentManagementProvider.notifier).deleteStudent(widget.student);
      if (mounted) Navigator.pop(context);
    }
  }
}

class AddStudentSheet extends ConsumerStatefulWidget {
  const AddStudentSheet({super.key});

  @override
  ConsumerState<AddStudentSheet> createState() => _AddStudentSheetState();
}

class _AddStudentSheetState extends ConsumerState<AddStudentSheet> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  String? _selectedBatchId;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _usernameCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedBatchId == null) {
      if (_selectedBatchId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a batch')));
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(studentManagementProvider.notifier).addStudent(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        password: _pwdCtrl.text.trim(),
        batchId: _selectedBatchId!,
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
    final theme = Theme.of(context);

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
              Text('Create New Student', 
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
              const SizedBox(height: 8),
              Text('Fill in the credentials for the new student.', 
                  style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))),
              const SizedBox(height: 32),
              
              TextFormField(
                controller: _nameCtrl, 
                style: GoogleFonts.inter(fontSize: 14),
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline_rounded)),
                validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameCtrl, 
                style: GoogleFonts.inter(fontSize: 14),
                decoration: const InputDecoration(labelText: 'Username (For Login)', prefixIcon: Icon(Icons.alternate_email_rounded)),
                validator: (v) => v == null || v.length < 3 ? 'Username too short' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl, 
                style: GoogleFonts.inter(fontSize: 14),
                decoration: const InputDecoration(labelText: 'Email Address (Optional)', prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pwdCtrl, 
                style: GoogleFonts.inter(fontSize: 14),
                decoration: const InputDecoration(labelText: 'Login Password', prefixIcon: Icon(Icons.lock_outline_rounded)), 
                obscureText: true,
                validator: (v) => v == null || v.length < 4 ? 'Password too short' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl, 
                style: GoogleFonts.inter(fontSize: 14),
                decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_android_rounded)),
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty ? 'Phone number is required' : null,
              ),
              const SizedBox(height: 16),
              batchesState.when(
                data: (batches) => DropdownButtonFormField<String>(
                  value: _selectedBatchId,
                  style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                  decoration: const InputDecoration(labelText: 'Assign Batch', prefixIcon: Icon(Icons.layers_outlined)),
                  items: batches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name, style: GoogleFonts.inter(fontSize: 14)))).toList(),
                  onChanged: (v) => setState(() => _selectedBatchId = v),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (err, _) => Text('Error loading batches', style: TextStyle(color: theme.colorScheme.error)),
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: _isLoading ? null : _submit, 
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('CREATE STUDENT ACCOUNT'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
